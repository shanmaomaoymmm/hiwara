#!/bin/bash

# ============================================================
# Linux amd64 打包脚本
# 支持格式: deb, rpm, appimage
# 架构: x86_64 (64-bit) - 本机构建
# 输出目录: release/
# 输出文件: hiwara_{version}_linux_amd64.{deb,rpm,AppImage}
# ============================================================

ARCH="x86_64-unknown-linux-gnu"
BUNDLES=("deb" "rpm" "appimage")
RELEASE_DIR="release"

# 从 tauri.conf.json 读取版本号
VERSION=$(grep '"version"' src-tauri/tauri.conf.json | head -1 | sed 's/.*"version": *"\([^"]*\)".*/\1/')

# 架构简称
SHORT_ARCH="amd64"

# 格式→扩展名映射
declare -A EXT_MAP
EXT_MAP["deb"]=".deb"
EXT_MAP["rpm"]=".rpm"
EXT_MAP["appimage"]=".AppImage"

# 确保输出目录存在
mkdir -p "$RELEASE_DIR"

# ============================================================
# 第一步：检查并安装 Rust target
# ============================================================
echo "========================================"
echo "检查 Rust target: $ARCH"
echo "========================================"
if rustup target list --installed 2>/dev/null | grep -q "^$ARCH$"; then
    echo "[✓] $ARCH 已安装"
else
    echo "[ ] $ARCH 未安装，正在安装..."
    rustup target add "$ARCH"
    echo "[✓] $ARCH 安装完成"
fi
echo ""

# ============================================================
# 第二步：安装系统依赖（如果缺失）
# ============================================================
if ! dpkg -l libwebkit2gtk-4.1-dev 2>/dev/null | grep -q "^ii"; then
    echo "安装 x86_64 系统依赖..."
    sudo apt update
    sudo apt install -y libwebkit2gtk-4.1-dev \
      build-essential curl wget file \
      libxdo-dev libssl-dev libayatana-appindicator3-dev librsvg2-dev
fi

# ============================================================
# 第三步：逐格式打包 + 重命名到 release/
# ============================================================
SUCCESS=0
FAILED=0

for bundle in "${BUNDLES[@]}"; do
    echo "========================================"
    echo "Building: $ARCH  ->  $bundle"
    echo "========================================"

    npx tauri build --target "$ARCH" --bundles "$bundle"
    if [ $? -ne 0 ]; then
        echo "[!] $ARCH / $bundle 打包失败，继续下一个..."
        FAILED=$((FAILED + 1))
        continue
    fi

    # 查找生成的包文件
    BUNDLE_DIR="src-tauri/target/$ARCH/release/bundle/$bundle"
    OUTPUT_PATH="$RELEASE_DIR/hiwara_${VERSION}_linux_${SHORT_ARCH}${EXT_MAP[$bundle]}"

    if [ "$bundle" = "deb" ]; then
        SRC_FILE=$(find "$BUNDLE_DIR" -name "*.deb" 2>/dev/null | head -1)
    elif [ "$bundle" = "rpm" ]; then
        SRC_FILE=$(find "$BUNDLE_DIR" -name "*.rpm" 2>/dev/null | head -1)
    elif [ "$bundle" = "appimage" ]; then
        SRC_FILE=$(find "$BUNDLE_DIR" -name "*.AppImage" 2>/dev/null | head -1)
    fi

    if [ -n "$SRC_FILE" ] && [ -f "$SRC_FILE" ]; then
        cp "$SRC_FILE" "$OUTPUT_PATH"
        echo "[✓] 输出: $OUTPUT_PATH ($(du -h "$OUTPUT_PATH" | cut -f1))"
        SUCCESS=$((SUCCESS + 1))
    else
        echo "[!] $bundle 产物未找到"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "========================================"
echo "Linux amd64 打包完成"
echo "输出目录: $RELEASE_DIR/"
echo "成功: $SUCCESS | 失败: $FAILED"
echo "========================================"
[ "$FAILED" -gt 0 ] && exit 1
