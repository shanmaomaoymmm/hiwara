#!/bin/bash
# ============================================================
# Docker 构建多架构 (deb / rpm / appimage)
# 支持: x86_64 / ARM64 / RISC-V 64
# 默认从 TUNA 镜像源本地构建基础镜像（debootstrap），无需 Docker Hub
# 输出目录: release/
# 输出文件: hiwara_{version}_linux_{arch}.{deb,rpm,AppImage}
#
# 使用方式:
#   ./package_app_linux_docker.sh                             # amd64 + ARM64 + RISC-V 64, 全部格式
#   ./package_app_linux_docker.sh -F                          # 强制重建本地基础镜像（含 debootstrap）
#   ./package_app_linux_docker.sh --pull                      # 改为从 Docker Hub 拉取基础镜像
#   ./package_app_linux_docker.sh --pull -F                   # 强制从 Docker Hub 重新拉取
#   ./package_app_linux_docker.sh --arch amd64 arm64          # 两个架构
#   ./package_app_linux_docker.sh --arch amd64                # 仅 amd64
#   ./package_app_linux_docker.sh --arch arm64                # 仅 ARM64
#   ./package_app_linux_docker.sh --arch riscv64              # 仅 RISC-V 64
#   ./package_app_linux_docker.sh --arch amd64 arm64 riscv64  # 三个架构全量构建
#   ./package_app_linux_docker.sh --bundle deb rpm            # 指定格式
#   ./package_app_linux_docker.sh --bundle deb                # 仅 deb
#   ./package_app_linux_docker.sh --bundle appimage           # 仅 appimage
#   ./package_app_linux_docker.sh --arch amd64 arm64 --bundle deb rpm  # 组合使用
#
# 基础镜像来源优先级:
#   1. 本地已有 debian:trixie-slim → 直接使用
#   2. 默认（或 --local-base）       → 通过 debootstrap 从 TUNA 镜像源构建
#   3. --pull                       → 从 Docker Hub 拉取
# ============================================================

set -e

DOCKER_OUTPUT_DIR="docker/release"
LOG_DIR="docker/logs"
BUILD_AMD64=false
BUILD_ARM64=false
BUILD_RISCV64=false
BUNDLES=()
FORCE_ALL=false
USE_LOCAL_BASE=true
USE_DOCKER_HUB=false

# 统一输出目录
RELEASE_DIR="release"

# 从 tauri.conf.json 读取版本号
VERSION=$(grep '"version"' src-tauri/tauri.conf.json | head -1 | sed 's/.*"version": *"\([^"]*\)".*/\1/')

# 格式→扩展名映射
declare -A EXT_MAP
EXT_MAP["deb"]=".deb"
EXT_MAP["rpm"]=".rpm"
EXT_MAP["appimage"]=".AppImage"

# 确保输出目录存在
mkdir -p "$RELEASE_DIR"

# 解析命名参数
while [ $# -gt 0 ]; do
    case "$1" in
        -F|--force-all)
            FORCE_ALL=true
            shift
            ;;
        --local-base)
            USE_LOCAL_BASE=true
            USE_DOCKER_HUB=false
            shift
            ;;
        --pull)
            USE_DOCKER_HUB=true
            USE_LOCAL_BASE=false
            shift
            ;;
        --arch)
            shift
            while [ $# -gt 0 ] && ! [[ "$1" =~ ^-- ]] && ! [[ "$1" =~ ^- ]]; do
                case "$1" in
                    amd64|x64) BUILD_AMD64=true ;;
                    arm64)   BUILD_ARM64=true ;;
                    riscv64) BUILD_RISCV64=true ;;
                    *)       echo "[!] 不支持的架构: $1 (可用: amd64, arm64, riscv64)"; exit 1 ;;
                esac
                shift
            done
            ;;
        --bundle)
            shift
            while [ $# -gt 0 ] && ! [[ "$1" =~ ^-- ]] && ! [[ "$1" =~ ^- ]]; do
                case "$1" in
                    deb|rpm|appimage) BUNDLES+=("$1") ;;
                    *)     echo "[!] 不支持的格式: $1 (可用: deb, rpm, appimage)"; exit 1 ;;
                esac
                shift
            done
            ;;
        -h|--help)
            sed -n '3,28p' "$0"
            exit 0
            ;;
        *)
            echo "[!] 未知参数: $1 (使用 --arch amd64|arm64|riscv64, --bundle, --pull, --local-base, -F, 或 -h)"
            exit 1
            ;;
    esac
done

# 默认值（未指定架构时构建全部）
if [ "$BUILD_AMD64" = false ] && [ "$BUILD_ARM64" = false ] && [ "$BUILD_RISCV64" = false ]; then
    BUILD_AMD64=true
    BUILD_ARM64=true
    BUILD_RISCV64=true
fi
if [ ${#BUNDLES[@]} -eq 0 ]; then
    BUNDLES=("deb" "rpm" "appimage")
fi

BUNDLES_STR="${BUNDLES[*]}"
echo "[i] 架构: $([ "$BUILD_AMD64" = true ] && echo 'amd64 ')$([ "$BUILD_ARM64" = true ] && echo 'ARM64 ')$([ "$BUILD_RISCV64" = true ] && echo 'RISC-V64')"
echo "[i] 格式: ${BUNDLES[*]}"
echo "[i] 版本: $VERSION"
echo "[i] 输出: $RELEASE_DIR/"

# ============================================================
# 确保基础镜像存在
# 默认: 从 TUNA 镜像源本地构建（debootstrap），无需 Docker Hub
# --pull: 从 Docker Hub 拉取
# -F: 强制重建/重新拉取
# ============================================================
ensure_base_image() {
    if docker image inspect debian:trixie-slim >/dev/null 2>&1; then
        if [ "$FORCE_ALL" = true ]; then
            if [ "$USE_DOCKER_HUB" = true ]; then
                echo "[i] 强制从 Docker Hub 重新拉取基础镜像..."
                docker pull debian:trixie-slim
                return $?
            else
                echo "[i] 强制重建本地基础镜像..."
            fi
        else
            echo "[i] 本地基础镜像 debian:trixie-slim 已存在"
            return 0
        fi
    else
        if [ "$USE_DOCKER_HUB" = true ]; then
            echo "[i] 本地基础镜像不存在，从 Docker Hub 拉取..."
            docker pull debian:trixie-slim
            return $?
        else
            echo "[i] 本地基础镜像不存在，通过 debootstrap 从 TUNA 镜像源构建..."
        fi
    fi

    if [ "$USE_DOCKER_HUB" = true ]; then
        echo "[i] 从 Docker Hub 拉取 debian:trixie-slim..."
        docker pull debian:trixie-slim
    elif [ -f ./docker/setup-docker-base.sh ]; then
        bash ./docker/setup-docker-base.sh
    else
        echo "[!] setup-docker-base.sh 不存在，回退到 Docker Hub 拉取"
        docker pull debian:trixie-slim
    fi
}

# ANSI 颜色定义
RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'; CYAN=$'\033[0;36m'; BOLD=$'\033[1m'; NC=$'\033[0m'

# 日志高亮过滤器
highlight_log() {
    sed \
        -e "s/CACHED/${GREEN}&${NC}/g" \
        -e "s/ERROR/${RED}&${NC}/g" \
        -e "s/failed/${RED}&${NC}/g" \
        -e "s/Failed/${RED}&${NC}/g" \
        -e "s/\[!\]/${YELLOW}&${NC}/g" \
        -e "s/Building/${CYAN}&${NC}/g" \
        -e "s/完成/${GREEN}&${NC}/g" \
        -e "s/\[i\]/${BLUE}&${NC}/g"
}

# ============================================================
# 构建函数（输出同时显示到终端和保存到日志文件）
# ============================================================
run_build() {
    local name=$1
    local arch_dir=$2      # 例如 amd64, arm64, riscv64
    local short_arch=$3
    shift 3

    local log_dir="$LOG_DIR/$arch_dir"
    mkdir -p "$log_dir"
    local log_file="$log_dir/$(date +%Y-%m-%d_%H-%M-%S).log"

    echo ""
    echo "========================================"
    echo "$name — 格式: ${BUNDLES[*]}"
    echo "日志: $log_file"
    echo "========================================"

    mkdir -p "$DOCKER_OUTPUT_DIR/$arch_dir"

    ensure_base_image

    set +e
    if command -v unbuffer &>/dev/null; then
        unbuffer "$@" 2>&1 | tee "$log_file" | highlight_log
    else
        "$@" 2>&1 | tee "$log_file" | highlight_log
    fi
    local exit_code=${PIPESTATUS[0]}
    set -e

    if [ "$exit_code" -ne 0 ]; then
        echo "[!] $name 构建失败"
        return 1
    fi

    # 重命名产物并复制到 release/ 目录
    echo ""
    echo "--- 重命名产物 → $RELEASE_DIR/ ---"
    for bundle in "${BUNDLES[@]}"; do
        local ext="${EXT_MAP[$bundle]}"
        for f in "$DOCKER_OUTPUT_DIR/$arch_dir"/*"$ext"; do
            if [ -f "$f" ]; then
                local new_name="hiwara_${VERSION}_linux_${short_arch}${ext}"
                cp "$f" "$RELEASE_DIR/$new_name"
                echo "[✓] $RELEASE_DIR/$new_name ($(du -h "$RELEASE_DIR/$new_name" | cut -f1))"
            fi
        done
    done

    echo "[✓] $name 完成"
}

# 从配置文件读取构建参数
read_build_args() {
    local args=""
    if [ -f docker/config/rustup-env ]; then
        while IFS='=' read -r key value; do
            [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
            args="$args --build-arg $key=$value"
        done < docker/config/rustup-env
    fi
    echo "$args"
}
BUILD_ARGS="$(read_build_args)"

# ============================================================
# 构建 x86_64
# ============================================================
build_amd64() {
    docker build $BUILD_ARGS --build-arg "BUNDLES=$BUNDLES_STR" \
        -t hiwara-builder-amd64 -f docker/Dockerfile.x64 .
    docker run --rm --user "$(id -u):$(id -g)" \
        -v "$(pwd)/$DOCKER_OUTPUT_DIR/amd64:/output" hiwara-builder-amd64
}

# ============================================================
# 构建 ARM64
# ============================================================
build_arm64() {
    docker build $BUILD_ARGS --build-arg "BUNDLES=$BUNDLES_STR" \
        -t hiwara-builder-arm64 -f docker/Dockerfile.arm64 .
    docker run --rm --user "$(id -u):$(id -g)" \
        -v "$(pwd)/$DOCKER_OUTPUT_DIR/arm64:/output" hiwara-builder-arm64
}

# ============================================================
# 构建 RISC-V 64
# ============================================================
build_riscv64() {
    docker build $BUILD_ARGS --build-arg "BUNDLES=$BUNDLES_STR" \
        -t hiwara-builder-riscv64 -f docker/Dockerfile.riscv64 .
    docker run --rm --user "$(id -u):$(id -g)" \
        -v "$(pwd)/$DOCKER_OUTPUT_DIR/riscv64:/output" hiwara-builder-riscv64
}

# ============================================================
# 顺序执行各架构构建
# ============================================================
FAILED=0
if [ "$BUILD_AMD64" = true ]; then
    run_build "amd64" "amd64" "amd64" build_amd64 || FAILED=1
fi
if [ "$BUILD_ARM64" = true ]; then
    run_build "ARM64" "arm64" "arm64" build_arm64 || FAILED=1
fi
if [ "$BUILD_RISCV64" = true ]; then
    run_build "RISC-V 64" "riscv64" "riscv64" build_riscv64 || FAILED=1
fi

echo ""
echo "========================================"
echo "全部完成！"
echo "输出目录: $RELEASE_DIR/"
ls -lh "$RELEASE_DIR"/hiwara_${VERSION}_linux_* 2>/dev/null || echo "(无)"
echo "========================================"
[ "$FAILED" = 1 ] && exit 1
