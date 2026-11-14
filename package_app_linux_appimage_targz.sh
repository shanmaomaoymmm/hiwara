#!/bin/bash
# ============================================================
# Linux AppImage + tar.gz 打包脚本
#
# 参照 package_app_linux_docker.sh 的产物约定：
#   输入: 已有 .deb 产物（release/ 或 docker/release/<arch>/）
#   输出: 两个发行变体（架构名与 deb/rpm 一致：amd64 / arm64 / riscv64）
#     linux       与 deb/rpm 一致，不内嵌依赖（需要宿主装 webkit2gtk-4.1 + gtk3）
#                 release/hiwara_{version}_linux_{arch}.AppImage
#                 release/hiwara_{version}_linux_{arch}.tar.gz
#     linux-full  内嵌全部运行时依赖（WebKitGTK/GTK3 及其整条依赖链）
#                 release/hiwara_{version}_linux-full_{arch}.AppImage
#                 release/hiwara_{version}_linux-full_{arch}.tar.gz
#
# 架构: amd64 (x86_64) / arm64 (aarch64) / riscv64
#
# 说明:
#   AppImage 由 AppImage/type2-runtime 官方 runtime + squashfs 组装，
#   全程离线完成（runtime 已内置在 docker/config/appimage/），
#   不依赖 tauri 默认的 linuxdeploy 在线下载。
#   linux-full 变体的依赖来自 hiwara-linux-sysroot 镜像里的三架构 sysroot。
#   RISC-V 没有官方 AppImage runtime（type2-runtime 仅发布
#   x86_64/i686/armhf/aarch64，上游 #156 仍 open），tauri bundler 也报
#   "Unsupported architecture: Riscv64"。因此 riscv64 的 AppImage 交给
#   附加脚本 package_app_linux_riscv64_appimage.sh：它会用上游源码
#   交叉编译 runtime-riscv64，再组装 AppImage。
#
# 使用方式:
#   ./package_app_linux_appimage_targz.sh                          # 三架构 × 两个变体
#   ./package_app_linux_appimage_targz.sh --variant linux          # 只要不内嵌依赖的版本
#   ./package_app_linux_appimage_targz.sh --variant linux-full     # 只要全依赖版本
#   ./package_app_linux_appimage_targz.sh --arch amd64 arm64       # 指定架构
#   ./package_app_linux_appimage_targz.sh --arch riscv64           # 仅 RISC-V（走附加脚本）
#   ./package_app_linux_appimage_targz.sh -F                       # 强制重建镜像/重编 riscv64 runtime
#   ./package_app_linux_appimage_targz.sh -h                       # 帮助
# ============================================================

set -euo pipefail
cd "$(dirname "$0")"

ARCHS=(amd64 arm64 riscv64)
ALL_VARIANTS=(linux linux-full)
SELECTED=()
SELECTED_VARIANTS=()
FORCE_TOOLS=false
RELEASE_DIR="release"
TOOLS_IMAGE="hiwara-appimage-tools"
SYSROOT_IMAGE="hiwara-linux-sysroot"

# 从 tauri.conf.json 读取版本号与产品名
VERSION=$(grep '"version"' src-tauri/tauri.conf.json | head -1 | sed 's/.*"version": *"\([^"]*\)".*/\1/')
PRODUCT=$(grep '"productName"' src-tauri/tauri.conf.json | head -1 | sed 's/.*"productName": *"\([^"]*\)".*/\1/')

# 兼容旧写法：x64 -> amd64，linux_full -> linux-full
normalize_arch() {
    case "$1" in
        x64) echo "amd64" ;;
        *)   echo "$1" ;;
    esac
}
normalize_variant() {
    case "$1" in
        linux_full) echo "linux-full" ;;
        *)          echo "$1" ;;
    esac
}

while [ $# -gt 0 ]; do
    case "$1" in
        --arch)
            shift
            while [ $# -gt 0 ] && ! [[ "$1" =~ ^- ]]; do
                a="$(normalize_arch "$1")"
                case "$a" in
                    amd64|arm64|riscv64) SELECTED+=("$a") ;;
                    *) echo "[!] 不支持的架构: $1 (可用: amd64, arm64, riscv64)"; exit 1 ;;
                esac
                shift
            done
            ;;
        --variant)
            shift
            while [ $# -gt 0 ] && ! [[ "$1" =~ ^- ]]; do
                case "$1" in
                    both|full) SELECTED_VARIANTS=("${ALL_VARIANTS[@]}") ;;
                    *)
                        v="$(normalize_variant "$1")"
                        case "$v" in
                            linux|linux-full) SELECTED_VARIANTS+=("$v") ;;
                            *) echo "[!] 不支持的变体: $1 (可用: linux, linux-full, both)"; exit 1 ;;
                        esac
                        ;;
                esac
                shift
            done
            ;;
        --no-deps) SELECTED_VARIANTS=("linux"); shift ;;   # 兼容旧参数
        -F|--force-all) FORCE_TOOLS=true; shift ;;
        -h|--help) sed -n '2,38p' "$0"; exit 0 ;;
        *) echo "[!] 未知参数: $1 (使用 --arch ..., --variant linux|linux-full|both, -F, -h)"; exit 1 ;;
    esac
done

[ ${#SELECTED[@]} -eq 0 ] && SELECTED=("${ARCHS[@]}")
[ ${#SELECTED_VARIANTS[@]} -eq 0 ] && SELECTED_VARIANTS=("${ALL_VARIANTS[@]}")

# 去重（避免 --variant linux linux 之类重复打包）
declare -A _seen
UNIQ_VARIANTS=()
for v in "${SELECTED_VARIANTS[@]}"; do
    [ -n "${_seen[$v]:-}" ] && continue
    _seen[$v]=1
    UNIQ_VARIANTS+=("$v")
done
SELECTED_VARIANTS=("${UNIQ_VARIANTS[@]}")

NEED_FULL=false
for v in "${SELECTED_VARIANTS[@]}"; do
    [ "$v" = "linux-full" ] && NEED_FULL=true
done

# 架构名 -> AppImage runtime 文件后缀
runtime_for() {
    case "$1" in
        amd64) echo "x86_64" ;;
        arm64) echo "aarch64" ;;
        *)     echo "" ;;
    esac
}

# 架构名 -> sysroot 目录名（与 Debian 架构名一致）
sysroot_for() {
    case "$1" in
        amd64) echo "amd64" ;;
        arm64) echo "arm64" ;;
        *)     echo "riscv64" ;;
    esac
}

mkdir -p "$RELEASE_DIR"

echo "========================================"
echo "Linux AppImage + tar.gz 打包"
echo "架构: ${SELECTED[*]}"
echo "变体: ${SELECTED_VARIANTS[*]}"
echo "版本: $VERSION"
echo "产品: $PRODUCT"
echo "输出: $RELEASE_DIR/"
echo "========================================"
echo ""

# ============================================================
# 第一步：检查 Docker（Windows 下请通过 WSL 执行）
# ============================================================
if ! command -v docker >/dev/null 2>&1; then
    echo "[!] 未找到 docker 命令"
    echo "    Windows 请用: wsl -d Debian -- bash $(pwd)/package_app_linux_appimage_targz.sh"
    exit 1
fi
if ! docker info >/dev/null 2>&1; then
    echo "[!] Docker 守护进程不可用"
    exit 1
fi
echo "[✓] Docker 可用"

# 校验内置 runtime
echo ""
echo "--- 校验 AppImage runtime ---"
for arch in "${SELECTED[@]}"; do
    rt=$(runtime_for "$arch")
    if [ -z "$rt" ]; then
        echo "[i] $arch 无官方 runtime -> 由附加脚本交叉编译（见 package_app_linux_riscv64_appimage.sh）"
        continue
    fi
    f="docker/config/appimage/runtime-$rt"
    if [ ! -f "$f" ]; then
        echo "[i] 缺少 $f，自动下载官方 runtime（不入库，现下现用）..."
        bash docker/config/appimage/fetch-runtimes.sh || {
            echo "[!] runtime 下载失败，可手动执行: bash docker/config/appimage/fetch-runtimes.sh"
            exit 1; }
    fi
    expected=$(tr -d '\r' < docker/config/appimage/SHA256SUMS | awk -v n="runtime-$rt" '$2 == n { print $1 }')
    actual=$(sha256sum "$f" | cut -d' ' -f1)
    if [ "$expected" != "$actual" ]; then
        echo "[!] $f 校验失败 (期望 $expected, 实际 $actual)"
        exit 1
    fi
    echo "[✓] $f 校验通过"
done

# ============================================================
# 第二步：构建/确认镜像
#   hiwara-linux-sysroot  : 三架构 WebKitGTK/GTK3 依赖树（linux-full 用；
#                           也是组装镜像的基础镜像）
#   hiwara-appimage-tools : 基于前者 + squashfs-tools + runtime
# ============================================================
if [ "$FORCE_TOOLS" = true ] || ! docker image inspect "$SYSROOT_IMAGE" >/dev/null 2>&1; then
    echo ""
    echo "--- 构建依赖 sysroot 镜像: $SYSROOT_IMAGE（首次需下载三架构依赖，约数分钟）---"
    SYSROOT_ARGS=()
    if [ "$FORCE_TOOLS" = true ]; then SYSROOT_ARGS+=("--no-cache"); fi
    docker build "${SYSROOT_ARGS[@]}" -t "$SYSROOT_IMAGE" -f docker/Dockerfile.sysroot . || {
        echo "[!] sysroot 镜像构建失败"; exit 1; }
else
    echo "[✓] sysroot 镜像 $SYSROOT_IMAGE 已存在"
fi
if [ "$NEED_FULL" = false ]; then
    echo "[i] 本次不构建 linux-full 变体，仍复用该镜像作为组装镜像的基础"
fi

# 组装镜像每次都走 docker build（有层缓存，通常 1 秒内完成），
# 这样 Dockerfile 改动（例如换了基础镜像）不会留下过期镜像
echo ""
echo "--- 确认组装镜像: $TOOLS_IMAGE ---"
TOOLS_ARGS=()
if [ "$FORCE_TOOLS" = true ]; then TOOLS_ARGS+=("--no-cache"); fi
docker build "${TOOLS_ARGS[@]}" -t "$TOOLS_IMAGE" -f docker/Dockerfile.appimage . || {
    echo "[!] 组装镜像构建失败"; exit 1; }

# ============================================================
# 第三步：逐架构 × 逐变体组装 AppImage + tar.gz
# ============================================================
SUCCESS=0
FAILED=0

for arch in "${SELECTED[@]}"; do
    # 定位 deb 产物（两个变体共用同一份 deb；兼容旧的 x64 命名/目录）
    DEB=""
    LEGACY_ARCH="$arch"
    if [ "$arch" = "amd64" ]; then LEGACY_ARCH="x64"; fi
    for cand in "$RELEASE_DIR/hiwara_${VERSION}_linux_${arch}.deb" \
                "$RELEASE_DIR/hiwara_${VERSION}_linux_${LEGACY_ARCH}.deb" \
                "docker/release/${arch}/hiwara_${VERSION}_linux_${arch}.deb" \
                "docker/release/${LEGACY_ARCH}/hiwara_${VERSION}_linux_${LEGACY_ARCH}.deb"; do
        if [ -f "$cand" ]; then DEB="$cand"; break; fi
    done

    if [ -z "$DEB" ] && [ "$arch" != "riscv64" ]; then
        echo ""
        echo "========================================"
        echo "Assembly: $arch"
        echo "========================================"
        echo "[!] 未找到 $arch 的 deb 产物"
        echo "    请先执行: ./package_app_linux_docker.sh --arch $arch --bundle deb"
        FAILED=$((FAILED + ${#SELECTED_VARIANTS[@]}))
        continue
    fi

    rt=$(runtime_for "$arch")
    runtime_path=""
    [ -n "$rt" ] && runtime_path="/tools/appimage/runtime-$rt"

    for variant in "${SELECTED_VARIANTS[@]}"; do
        echo ""
        echo "========================================"
        echo "Assembly: $arch / $variant"
        echo "========================================"

        # RISC-V：官方没有 runtime，交给附加脚本（自建 runtime + 组装）
        if [ "$arch" = "riscv64" ]; then
            RISCV_ARGS=()
            if [ "$FORCE_TOOLS" = true ]; then RISCV_ARGS+=("-F"); fi
            RISCV_ARGS+=("--variant" "$variant")
            if bash ./package_app_linux_riscv64_appimage.sh "${RISCV_ARGS[@]}"; then
                SUCCESS=$((SUCCESS + 1))
            else
                echo "[!] riscv64 / $variant 打包失败"
                FAILED=$((FAILED + 1))
            fi
            continue
        fi

        echo "[i] 源 deb: $DEB"
        echo "[i] 变体: $variant（$([ "$variant" = "linux-full" ] && echo "内嵌全部运行时依赖" || echo "不内嵌依赖，与 deb/rpm 一致")）"

        if docker run --rm \
            --user "$(id -u):$(id -g)" \
            -e ARCH="$arch" \
            -e VERSION="$VERSION" \
            -e PRODUCT="$PRODUCT" \
            -e VARIANT="$variant" \
            -e DEB="/work/$DEB" \
            -e OUT_DIR="/work/$RELEASE_DIR" \
            -e RUNTIME="$runtime_path" \
            -e SYSROOT="/sysroot/$(sysroot_for "$arch")/root" \
            -v "$(pwd):/work" \
            -v "$(pwd)/docker/config/appimage:/tools/appimage:ro" \
            "$TOOLS_IMAGE" \
            /work/docker/appimage/build-package.sh; then
            SUCCESS=$((SUCCESS + 1))
        else
            echo "[!] $arch / $variant 打包失败"
            FAILED=$((FAILED + 1))
        fi
    done
done

echo ""
echo "========================================"
echo "打包完成"
echo "输出目录: $RELEASE_DIR/"
ls -lh "$RELEASE_DIR"/hiwara_${VERSION}_linux*_*.AppImage \
       "$RELEASE_DIR"/hiwara_${VERSION}_linux*_*.tar.gz 2>/dev/null || true
echo "成功: $SUCCESS | 失败: $FAILED"
echo "========================================"
[ "$FAILED" -gt 0 ] && exit 1
exit 0
