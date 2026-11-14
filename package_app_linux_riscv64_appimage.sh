#!/bin/bash
# ============================================================
# package_app_linux_riscv64_appimage.sh
#
# 【附加脚本】打包 RISC-V 64 的 AppImage / tar.gz。
#
# 背景:
#   AppImage 官方 type2-runtime 只发布 x86_64/i686/armhf/aarch64，
#   riscv64 支持请求仍 open（AppImage/type2-runtime#156），
#   tauri bundler 也直接报 `Unsupported architecture: Riscv64`。
#   在官方支持到来之前，本脚本用上游同一份 runtime.c + libfuse3 +
#   squashfuse 源码，通过 Debian 的 riscv64 交叉工具链自行编译
#   runtime-riscv64，再用它组装标准 type-2 AppImage。
#
# 被调用方:
#   package_app_linux_appimage_targz.sh 在打包 riscv64 时会调用本脚本。
#
# 变体:
#   linux       不内嵌依赖（与 deb/rpm 一致）
#   linux_full  内嵌全部运行时依赖
#
# 使用方式:
#   ./package_app_linux_riscv64_appimage.sh                      # 两个变体
#   ./package_app_linux_riscv64_appimage.sh --variant linux       # 只出不内嵌依赖的
#   ./package_app_linux_riscv64_appimage.sh --variant linux_full  # 只出全依赖的
#   ./package_app_linux_riscv64_appimage.sh -F                    # 强制重新编译 runtime
#   ./package_app_linux_riscv64_appimage.sh --no-tar              # 只出 AppImage
#   ./package_app_linux_riscv64_appimage.sh --no-verify           # 跳过 qemu 校验
#   ./package_app_linux_riscv64_appimage.sh -h                    # 帮助
#
# 输出:
#   release/hiwara_{version}_linux_riscv64.{AppImage,tar.gz}
#   release/hiwara_{version}_linux_full_riscv64.{AppImage,tar.gz}
# ============================================================

set -euo pipefail
cd "$(dirname "$0")"

RELEASE_DIR="release"
RUNTIME="docker/config/appimage/runtime-riscv64"
BUILDER_IMAGE="hiwara-riscv64-runtime"
TOOLS_IMAGE="hiwara-appimage-tools"
SYSROOT_IMAGE="hiwara-linux-sysroot"
ALL_VARIANTS=(linux linux_full)
SELECTED_VARIANTS=()
FORCE_RUNTIME=false
WITH_TAR=true
DO_VERIFY=true

VERSION=$(grep '"version"' src-tauri/tauri.conf.json | head -1 | sed 's/.*"version": *"\([^"]*\)".*/\1/')
PRODUCT=$(grep '"productName"' src-tauri/tauri.conf.json | head -1 | sed 's/.*"productName": *"\([^"]*\)".*/\1/')

while [ $# -gt 0 ]; do
    case "$1" in
        -F|--force-runtime) FORCE_RUNTIME=true; shift ;;
        --no-tar)           WITH_TAR=false; shift ;;
        --no-verify)        DO_VERIFY=false; shift ;;
        --variant)
            shift
            while [ $# -gt 0 ] && ! [[ "$1" =~ ^- ]]; do
                case "$1" in
                    linux|linux_full) SELECTED_VARIANTS+=("$1") ;;
                    both|full)        SELECTED_VARIANTS=("${ALL_VARIANTS[@]}") ;;
                    *) echo "[!] 不支持的变体: $1 (可用: linux, linux_full, both)"; exit 1 ;;
                esac
                shift
            done
            ;;
        --no-deps)          SELECTED_VARIANTS=("linux"); shift ;;   # 兼容旧参数
        -h|--help)          sed -n '2,36p' "$0"; exit 0 ;;
        *) echo "[!] 未知参数: $1 (可用: -F, --variant linux|linux_full|both, --no-tar, --no-verify, -h)"; exit 1 ;;
    esac
done

[ ${#SELECTED_VARIANTS[@]} -eq 0 ] && SELECTED_VARIANTS=("${ALL_VARIANTS[@]}")
declare -A _seen
UNIQ=()
for v in "${SELECTED_VARIANTS[@]}"; do
    [ -n "${_seen[$v]:-}" ] && continue
    _seen[$v]=1
    UNIQ+=("$v")
done
SELECTED_VARIANTS=("${UNIQ[@]}")

NEED_FULL=false
for v in "${SELECTED_VARIANTS[@]}"; do
    [ "$v" = "linux_full" ] && NEED_FULL=true
done

log() { echo "[i] $*"; }
ok()  { echo "[✓] $*"; }

echo "========================================"
echo "RISC-V 64 AppImage 打包（自建 runtime）"
echo "版本: $VERSION | 产品: $PRODUCT"
echo "变体: ${SELECTED_VARIANTS[*]}"
echo "========================================"
echo ""

# ============================================================
# 第一步：检查 Docker
# ============================================================
if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    echo "[!] Docker 不可用"
    echo "    Windows 请用: wsl -d Debian -- bash $(pwd)/$0"
    exit 1
fi

# ============================================================
# 第二步：确保 runtime-riscv64 存在
#   交叉编译：libfuse 3.15.0(上游补丁) + squashfuse 0.5.2 + runtime.c
# ============================================================
check_runtime() {
    [ -f "$RUNTIME" ] || return 1
    # AppImage type-2 魔数（offset 8 处 "AI\x02"）
    local magic
    magic=$(od -An -c -j 8 -N 3 "$RUNTIME" | tr -d ' \n')
    [ "$magic" = "AI002" ] || { echo "[!] $RUNTIME 魔数异常: $magic"; return 1; }
    # ELF 头（7f 45 4c 46）+ e_machine=243（RISC-V，小端 f3 00）
    local elfmagic machine
    elfmagic=$(head -c 4 "$RUNTIME" | od -An -tx1 | tr -d ' \n')
    machine=$(od -An -tx1 -j 18 -N 2 "$RUNTIME" | tr -d ' \n')
    [ "$elfmagic" = "7f454c46" ] || { echo "[!] $RUNTIME 不是 ELF"; return 1; }
    [ "$machine" = "f300" ] || { echo "[!] $RUNTIME 不是 riscv64 ELF (e_machine=$machine)"; return 1; }
}

if check_runtime && [ "$FORCE_RUNTIME" = false ]; then
    ok "复用已有 runtime: $RUNTIME ($(du -h "$RUNTIME" | cut -f1))"
else
    # 构建源码不入库，缺失时现下（见 docker/config/appimage/fetch-sources.sh）
    MISSING_SRC=false
    for f in runtime.c data_sections.ld mount.c.diff fuse-3.15.0.tar.gz squashfuse-0.5.2.tar.gz; do
        [ -f "docker/config/appimage/src/$f" ] || MISSING_SRC=true
    done
    if [ "$MISSING_SRC" = true ]; then
        log "下载 runtime 构建源码（不入库，现下现用）..."
        bash docker/config/appimage/fetch-sources.sh || {
            echo "[!] 源码下载失败，可手动执行: bash docker/config/appimage/fetch-sources.sh"
            exit 1; }
    fi
    log "编译 riscv64 runtime（首次约 2-4 分钟，会缓存镜像层）..."
    docker build -t "$BUILDER_IMAGE" -f docker/Dockerfile.riscv64-runtime . || {
        echo "[!] runtime 构建镜像失败"; exit 1; }
    docker run --rm \
        --user "$(id -u):$(id -g)" \
        -v "$PWD:$PWD" -w "$PWD" \
        -v "$PWD/docker/config/appimage:/out" \
        "$BUILDER_IMAGE" \
        "$PWD/docker/appimage/build-riscv64-runtime.sh" || {
        echo "[!] runtime 交叉编译失败"; exit 1; }
    check_runtime || { echo "[!] runtime 校验失败"; exit 1; }
    ok "runtime-riscv64 编译完成: $(du -h "$RUNTIME" | cut -f1)"
fi
# 记录产物指纹，便于对照/复现
sha256sum "$RUNTIME" > "$RUNTIME.sha256"

# ============================================================
# 第三步：定位 .deb 产物
# ============================================================
DEB=""
for cand in "$RELEASE_DIR/hiwara_${VERSION}_linux_riscv64.deb" \
            "docker/release/riscv64/hiwara_${VERSION}_linux_riscv64.deb"; do
    [ -f "$cand" ] && DEB="$cand" && break
done
if [ -z "$DEB" ]; then
    echo "[!] 未找到 riscv64 deb 产物"
    echo "    请先执行: ./package_app_linux_docker.sh --arch riscv64 --bundle deb"
    exit 1
fi
log "源 deb: $DEB"

# ============================================================
# 第四步：准备镜像
# ============================================================
if [ "$FORCE_RUNTIME" = true ] || ! docker image inspect "$SYSROOT_IMAGE" >/dev/null 2>&1; then
    log "构建依赖 sysroot 镜像 $SYSROOT_IMAGE（首次需下载三架构依赖）..."
    docker build -t "$SYSROOT_IMAGE" -f docker/Dockerfile.sysroot . || {
        echo "[!] sysroot 镜像构建失败"; exit 1; }
fi
if [ "$NEED_FULL" = false ]; then
    log "本次不构建 linux_full 变体，sysroot 镜像仅作为组装镜像的基础"
fi
if ! docker image inspect "$TOOLS_IMAGE" >/dev/null 2>&1; then
    log "构建组装镜像 $TOOLS_IMAGE ..."
    docker build -t "$TOOLS_IMAGE" -f docker/Dockerfile.appimage . || {
        echo "[!] 组装镜像构建失败"; exit 1; }
fi

# ============================================================
# 第五步：逐变体组装 + qemu 校验
# ============================================================
for variant in "${SELECTED_VARIANTS[@]}"; do
    echo ""
    echo "----------------------------------------"
    echo "riscv64 / $variant"
    echo "----------------------------------------"

    BUNDLE_DEPS=0
    [ "$variant" = "linux_full" ] && BUNDLE_DEPS=1

    docker run --rm \
        --user "$(id -u):$(id -g)" \
        -v "$PWD:$PWD" -w "$PWD" \
        -v "$PWD/docker/config/appimage:/tools/appimage:ro" \
        -e ARCH=riscv64 \
        -e VERSION="$VERSION" \
        -e PRODUCT="$PRODUCT" \
        -e VARIANT="$variant" \
        -e BUNDLE_DEPS="$BUNDLE_DEPS" \
        -e DEB="$PWD/$DEB" \
        -e OUT_DIR="$PWD/$RELEASE_DIR" \
        -e RUNTIME=/tools/appimage/runtime-riscv64 \
        -e SYSROOT=/sysroot/riscv64/root \
        "$TOOLS_IMAGE" \
        "$PWD/docker/appimage/build-package.sh" || {
        echo "[!] $variant 组装失败"; exit 1; }

    IMG="$PWD/$RELEASE_DIR/hiwara_${VERSION}_${variant}_riscv64.AppImage"
    TGZ="$PWD/$RELEASE_DIR/hiwara_${VERSION}_${variant}_riscv64.tar.gz"
    [ "$WITH_TAR" = false ] && rm -f "$TGZ"

    if [ "$DO_VERIFY" = true ] && [ -f "$IMG" ]; then
        if docker image inspect "$BUILDER_IMAGE" >/dev/null 2>&1; then
            docker run --rm \
                --user "$(id -u):$(id -g)" \
                -v "$PWD:$PWD" -w "$PWD" \
                --entrypoint bash \
                "$BUILDER_IMAGE" \
                "$PWD/docker/appimage/verify-riscv64-appimage.sh" \
                "$IMG" || { echo "[!] $variant qemu 校验失败"; exit 1; }
        else
            echo "[!] 缺少 $BUILDER_IMAGE 镜像，跳过 qemu 校验"
        fi
    fi
done

echo ""
echo "========================================"
echo "RISC-V 64 打包完成"
echo "输出:"
ls -lh "$RELEASE_DIR"/hiwara_${VERSION}_linux*_riscv64.AppImage \
       "$RELEASE_DIR"/hiwara_${VERSION}_linux*_riscv64.tar.gz 2>/dev/null | sed 's/^/    /'
echo "========================================"
