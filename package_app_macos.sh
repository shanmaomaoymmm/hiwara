#!/bin/zsh

# ============================================================
# macOS 打包脚本 (zsh)
# 支持架构: x86_64 (Intel), aarch64 (Apple Silicon)
# 支持格式: dmg (Tauri 默认同时生成 .app)
# 功能: 各架构独立打包 + Universal Binary (lipo) 合并
# 输出目录: release/
# 输出文件: hiwara_{version}_mac_{arch}.dmg
# 配置: 通过 package_app_macos.env 控制签名和公证
# 配置文档: doc/macos-packaging-config.md
# ============================================================

set -e  # target 安装阶段严格模式

# ============================================================
# 配置加载
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 加载 .env 配置文件（如果存在）
if [[ -f "package_app_macos.env" ]]; then
    echo "========================================"
    echo "加载配置文件: package_app_macos.env"
    echo "========================================"
    source "package_app_macos.env"
fi

# 默认值（环境变量未设置时使用）
: ${ENABLE_CODESIGNING:=false}
: ${ENABLE_NOTARIZATION:=false}
: ${APPLE_SIGNING_IDENTITY:=""}
: ${APPLE_TEAM_ID:=""}
: ${APPLE_ID:=""}
: ${APPLE_APP_SPECIFIC_PASSWORD:=""}

# 输出目录
RELEASE_DIR="release"
mkdir -p "$RELEASE_DIR"

# 从 tauri.conf.json 读取版本号
VERSION=$(grep '"version"' src-tauri/tauri.conf.json | head -1 | sed 's/.*"version": *"\([^"]*\)".*/\1/')

# ============================================================
# 架构与打包格式定义
# ============================================================

# 架构列表: (target_triple, short_name)
ARCHITECTURES=(
    "x86_64-apple-darwin:x86_64"    # Intel Mac (64-bit)
    "aarch64-apple-darwin:arm64" # Apple Silicon (M 系列)
)

# 打包格式说明：
# - Tauri v2 默认生成 .app（macOS 应用 bundle）
# - DMG 由脚本在 Universal Binary 阶段用 hdiutil 直接创建
# - 不传 --bundles 参数，避免触发 Tauri 内置的 bundle_dmg.sh（已知 bug）
BUNDLES=()

# ============================================================
# 第一步：检查 Xcode 命令行工具
# ============================================================
echo ""
echo "========================================"
echo "检查 Xcode 命令行工具..."
echo "========================================"

if ! xcode-select -p &>/dev/null; then
    echo "[✗] Xcode 命令行工具未安装"
    echo "    请运行: xcode-select --install"
    echo "    安装完成后重新运行此脚本"
    exit 1
else
    echo "[✓] Xcode 命令行工具已安装 ($(xcode-select -p))"
fi

# ============================================================
# 第二步：检查并安装缺失的 Rust target
# ============================================================
echo ""
echo "========================================"
echo "检查并安装缺失的 Rust target..."
echo "========================================"

for entry in "${ARCHITECTURES[@]}"; do
    arch="${entry%%:*}"
    if rustup target list --installed 2>/dev/null | grep -q "^$arch$"; then
        echo "[✓] $arch 已安装"
    else
        echo "[ ] $arch 未安装，正在安装..."
        rustup target add "$arch"
        echo "[✓] $arch 安装完成"
    fi
done

set +e  # 后续构建步骤使用错误容忍模式

# ============================================================
# 第三步：逐架构构建 .app + 创建各架构 DMG
# ============================================================
echo ""
echo "========================================"
echo "开始构建各架构 .app..."
echo "========================================"

declare -A BUILD_RESULTS  # 存储构建结果

for entry in "${ARCHITECTURES[@]}"; do
    arch="${entry%%:*}"
    short="${entry##*:}"

    echo ""
    echo "========================================"
    echo "构建: $arch  ($short)"
    echo "========================================"

    # 只构建 .app
    npx tauri build --target "$arch"
    
    if [[ $? -eq 0 ]]; then
        echo "[✓] $arch 构建成功"
        BUILD_RESULTS[$arch]="success"

        # 创建各架构 DMG → release/
        APP_PATH="src-tauri/target/$arch/release/bundle/macos/Hiwara.app"
        DMG_PATH="$RELEASE_DIR/hiwara_${VERSION}_mac_${short}.dmg"

        if [[ -d "$APP_PATH" ]]; then
            echo "创建 DMG: $DMG_PATH"
            hdiutil create -volname "Hiwara" \
                -srcfolder "$APP_PATH" \
                -ov -format UDZO \
                "$DMG_PATH"
            if [[ $? -eq 0 ]]; then
                echo "[✓] $DMG_PATH 创建成功 ($(du -h "$DMG_PATH" | cut -f1))"
            else
                echo "[!] $DMG_PATH 创建失败"
            fi
        fi
    else
        echo "[!] $arch 构建失败（继续执行后续步骤）"
        BUILD_RESULTS[$arch]="failed"
    fi
done

# ============================================================
# 第四步：Codesigning（各架构独立）
# ============================================================
echo ""
echo "========================================"
echo "Codesigning 处理..."
echo "========================================"

for entry in "${ARCHITECTURES[@]}"; do
    arch="${entry%%:*}"
    short="${entry##*:}"

    if [[ "${BUILD_RESULTS[$arch]}" != "success" ]]; then
        echo "[!] 跳过 $arch 签名（构建失败）"
        continue
    fi
    
    APP_PATH="src-tauri/target/$arch/release/bundle/macos/Hiwara.app"
    if [[ ! -d "$APP_PATH" ]]; then
        echo "[!] $APP_PATH 不存在，跳过签名"
        continue
    fi
    
    if [[ "$ENABLE_CODESIGNING" == "true" && -n "$APPLE_SIGNING_IDENTITY" ]]; then
        echo "签名: $APP_PATH"
        echo "签名身份: $APPLE_SIGNING_IDENTITY"
        codesign --force --options runtime \
            --sign "$APPLE_SIGNING_IDENTITY" \
            --deep \
            "$APP_PATH"
        if [[ $? -eq 0 ]]; then
            echo "[✓] $arch 正式签名成功"
        else
            echo "[✗] $arch 正式签名失败"
        fi
    else
        echo "自签名: $APP_PATH"
        codesign --force --deep -s - "$APP_PATH"
        if [[ $? -eq 0 ]]; then
            echo "[✓] $arch 自签名成功"
        else
            echo "[✗] $arch 自签名失败"
        fi
    fi
done

# ============================================================
# 第五步：创建 Universal Binary + Universal DMG
# ============================================================
echo ""
echo "========================================"
echo "创建 Universal Binary..."
echo "========================================"

INTEL_DIR="src-tauri/target/x86_64-apple-darwin/release"
ARM_DIR="src-tauri/target/aarch64-apple-darwin/release"
UNIVERSAL_DIR="src-tauri/target/universal"

INTEL_APP="$INTEL_DIR/bundle/macos/Hiwara.app"
ARM_APP="$ARM_DIR/bundle/macos/Hiwara.app"

UNIVERSAL_DMG="$RELEASE_DIR/hiwara_${VERSION}_mac_universal.dmg"

# 检查两个架构的构建是否都成功
if [[ ! -d "$INTEL_APP" || ! -d "$ARM_APP" ]]; then
    echo "[!] 缺少架构产物，无法创建 Universal Binary"
    echo "    Intel app: $( [[ -d "$INTEL_APP" ]] && echo '存在' || echo '不存在' )"
    echo "    ARM   app: $( [[ -d "$ARM_APP" ]] && echo '存在' || echo '不存在' )"
    UNIVERSAL_BUILD_FAILED=true
else
    UNIVERSAL_BUILD_FAILED=false
    
    # 清理旧目录
    rm -rf "$UNIVERSAL_DIR"
    mkdir -p "$UNIVERSAL_DIR"
    
    # 1. 复制 Intel 的 .app 结构作为基础
    echo "复制 .app 结构..."
    cp -R "$INTEL_APP" "$UNIVERSAL_DIR/Hiwara.app"
    
    # 2. 获取可执行文件路径
    INTEL_BIN="$INTEL_DIR/hiwara"
    ARM_BIN="$ARM_DIR/hiwara"
    UNIVERSAL_BIN="$UNIVERSAL_DIR/Hiwara.app/Contents/MacOS/hiwara"
    
    # 3. 使用 lipo 合并二进制
    echo "合并二进制..."
    if [[ -f "$INTEL_BIN" && -f "$ARM_BIN" ]]; then
        lipo -create \
            "$INTEL_BIN" \
            "$ARM_BIN" \
            -output "$UNIVERSAL_BIN"
        echo "[✓] Universal Binary 创建成功"
        
        # 验证合并结果
        echo "架构信息:"
        lipo -info "$UNIVERSAL_BIN"
    else
        echo "[✗] 缺少可执行文件"
        echo "    Intel: $( [[ -f "$INTEL_BIN" ]] && echo '存在' || echo '不存在' )"
        echo "    ARM:   $( [[ -f "$ARM_BIN" ]] && echo '存在' || echo '不存在' )"
        UNIVERSAL_BUILD_FAILED=true
    fi
    
    # 4. 签名 Universal App
    if [[ "$UNIVERSAL_BUILD_FAILED" == false ]]; then
        if [[ "$ENABLE_CODESIGNING" == "true" && -n "$APPLE_SIGNING_IDENTITY" ]]; then
            echo "签名 Universal App（正式签名）..."
            codesign --force --options runtime \
                --sign "$APPLE_SIGNING_IDENTITY" \
                --deep \
                "$UNIVERSAL_DIR/Hiwara.app"
        else
            echo "签名 Universal App（自签名）..."
            codesign --force --deep -s - "$UNIVERSAL_DIR/Hiwara.app"
        fi
        if [[ $? -eq 0 ]]; then
            echo "[✓] Universal App 签名成功"
        else
            echo "[✗] Universal App 签名失败"
        fi
    fi
    
    # 5. 创建 Universal DMG → release/
    echo "创建 Universal DMG... $UNIVERSAL_DMG"
    
    hdiutil create -volname "Hiwara" \
        -srcfolder "$UNIVERSAL_DIR/Hiwara.app" \
        -ov -format UDZO \
        "$UNIVERSAL_DMG"
    
    if [[ $? -eq 0 ]]; then
        echo "[✓] Universal DMG 创建成功: $UNIVERSAL_DMG ($(du -h "$UNIVERSAL_DMG" | cut -f1))"
        
        # 可选：公证 Universal DMG
        if [[ "$ENABLE_NOTARIZATION" == "true" && "$ENABLE_CODESIGNING" == "true" ]]; then
            echo ""
            echo "========================================"
            echo "提交到 Apple 公证服务..."
            echo "========================================"
            
            if [[ -n "$APPLE_ID" && -n "$APPLE_TEAM_ID" && -n "$APPLE_APP_SPECIFIC_PASSWORD" ]]; then
                xcrun notarytool submit "$UNIVERSAL_DMG" \
                    --apple-id "$APPLE_ID" \
                    --team-id "$APPLE_TEAM_ID" \
                    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
                    --wait
                
                if [[ $? -eq 0 ]]; then
                    echo "[✓] Notarization 提交成功"
                    echo "绑定公证票据..."
                    xcrun stapler staple "$UNIVERSAL_DMG"
                    echo "[✓] 公证票据绑定成功"
                else
                    echo "[✗] Notarization 失败"
                fi
            else
                echo "[✗] Notarization 配置不完整"
                echo "    请设置 APPLE_ID, APPLE_TEAM_ID, APPLE_APP_SPECIFIC_PASSWORD"
            fi
        fi
    else
        echo "[✗] Universal DMG 创建失败"
    fi
fi

# ============================================================
# 第六步：构建结果摘要
# ============================================================
echo ""
echo "========================================"
echo "构建结果摘要"
echo "========================================"

echo ""
echo "--- 各架构 DMG ---"
for entry in "${ARCHITECTURES[@]}"; do
    arch="${entry%%:*}"
    short="${entry##*:}"
    RESULT="${BUILD_RESULTS[$arch]}"
    DMG_FILE="$RELEASE_DIR/hiwara_${VERSION}_mac_${short}.dmg"
    if [[ -f "$DMG_FILE" ]]; then
        SIZE=$(du -h "$DMG_FILE" | cut -f1)
        echo "  [✓] $short — $DMG_FILE ($SIZE)"
    elif [[ "$RESULT" == "success" ]]; then
        echo "  [!] $short — 构建成功，但 DMG 未找到"
    else
        echo "  [✗] $short — 构建失败"
    fi
done

echo ""
echo "--- Universal Binary ---"
if [[ "$UNIVERSAL_BUILD_FAILED" == false ]]; then
    if [[ -f "$UNIVERSAL_DMG" ]]; then
        SIZE=$(du -h "$UNIVERSAL_DMG" | cut -f1)
        echo "  [✓] Universal DMG — $UNIVERSAL_DMG ($SIZE)"
    fi
else
    echo "  [✗] Universal Binary 创建失败（缺少架构产物）"
fi

echo ""
echo "========================================"
echo "全部任务完成"
echo "========================================"
