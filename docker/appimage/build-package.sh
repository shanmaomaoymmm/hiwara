#!/bin/bash
# ============================================================
# build-package.sh - 在容器内组装 AppImage 与 tar.gz
#
# 输入（环境变量）:
#   ARCH        架构名: amd64 | arm64 | riscv64（与 deb/rpm 一致）
#   VERSION     版本号，例如 0.3.8
#   PRODUCT     产品名，例如 Hiwara
#   DEB         源 .deb 路径
#   OUT_DIR     输出目录，默认 /work/release
#   RUNTIME     AppImage type2 runtime 路径；为空表示该架构无 runtime，
#               只生成 tar.gz
#   VARIANT     发行变体: linux（不含依赖，与 deb/rpm 一致）
#                       linux-full（内嵌全部运行时依赖）
#   BUNDLE_DEPS 可覆盖：1=内嵌依赖，0=依赖系统包（默认由 VARIANT 决定）
#   SYSROOT     对应架构的 sysroot（内嵌依赖时必需）
#   EXCLUDELIST 排除清单路径，默认 /tools/appimage/excludelist-minimal
#
# 输出:
#   ${OUT_DIR}/hiwara_${VERSION}_${VARIANT}_${ARCH}.AppImage
#   ${OUT_DIR}/hiwara_${VERSION}_${VARIANT}_${ARCH}.tar.gz
#   例: hiwara_0.3.8_linux_amd64.AppImage / hiwara_0.3.8_linux-full_amd64.AppImage
# ============================================================
set -euo pipefail

ARCH="${ARCH:?ARCH 未设置}"
VERSION="${VERSION:?VERSION 未设置}"
PRODUCT="${PRODUCT:-Hiwara}"
DEB="${DEB:?DEB 未设置}"
OUT_DIR="${OUT_DIR:-/work/release}"
RUNTIME="${RUNTIME:-}"
VARIANT="${VARIANT:-linux}"
SYSROOT="${SYSROOT:-}"
EXCLUDELIST="${EXCLUDELIST:-/tools/appimage/excludelist-minimal}"

case "$VARIANT" in
    linux)      BUNDLE_DEPS="${BUNDLE_DEPS:-0}" ;;
    linux-full) BUNDLE_DEPS="${BUNDLE_DEPS:-1}" ;;
    *) echo "[!] 不支持的变体: $VARIANT (可用: linux, linux-full)"; exit 1 ;;
esac

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

APPIMAGE_ARCH=""
case "$ARCH" in
    amd64)   APPIMAGE_ARCH="x86_64" ;;
    arm64)   APPIMAGE_ARCH="aarch64" ;;
    riscv64) APPIMAGE_ARCH="riscv64" ;;
    *) echo "[!] 不支持的架构: $ARCH (可用: amd64, arm64, riscv64)"; exit 1 ;;
esac

BUNDLE_NAME="hiwara_${VERSION}_${VARIANT}_${ARCH}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

log() { echo "[i] $*"; }
ok()  { echo "[✓] $*"; }

[ -f "$DEB" ] || { echo "[!] 未找到 deb: $DEB"; exit 1; }
mkdir -p "$OUT_DIR"

# ------------------------------------------------------------
# 1. 解包 deb，得到与安装后完全一致的文件树
# ------------------------------------------------------------
PAYLOAD="$WORK/payload"
mkdir -p "$PAYLOAD"
dpkg-deb -x "$DEB" "$PAYLOAD"
[ -x "$PAYLOAD/usr/bin/hiwara" ] || { echo "[!] deb 中缺少 usr/bin/hiwara"; exit 1; }
log "deb 已解包: $(find "$PAYLOAD" -type f | wc -l) 个文件"

# ------------------------------------------------------------
# 2. 组装 AppDir
#    目录结构: AppDir/AppRun + AppDir/usr/{bin,lib,share}
# ------------------------------------------------------------
APPDIR="$WORK/${PRODUCT}.AppDir"
mkdir -p "$APPDIR"
cp -a "$PAYLOAD/usr" "$APPDIR/usr"

# ------------------------------------------------------------
# 3. 内嵌运行时依赖（WebKitGTK / GTK3 及其依赖）
# ------------------------------------------------------------
if [ "$BUNDLE_DEPS" = "1" ]; then
    if [ -z "$SYSROOT" ] || [ ! -d "$SYSROOT" ]; then
        echo "[!] BUNDLE_DEPS=1 但 SYSROOT 不可用: '${SYSROOT}'"
        exit 1
    fi
    log "内嵌依赖（sysroot: $SYSROOT）..."
    bash "$HERE/bundle-deps.sh" "$APPDIR" "$SYSROOT" "usr/bin/hiwara" "$EXCLUDELIST"
else
    log "BUNDLE_DEPS=0：依赖由目标系统提供"
fi

# ------------------------------------------------------------
# 4. 生成启动脚本（含内嵌依赖所需的环境变量）
# ------------------------------------------------------------
PIXBUF_VER=""
if [ -d "$APPDIR/usr/lib/gdk-pixbuf-2.0" ]; then
    PIXBUF_VER=$(ls "$APPDIR/usr/lib/gdk-pixbuf-2.0" | head -1)
fi

make_entry() {  # $1=目标文件  $2=注释
    cat > "$1" <<ENTRY
#!/bin/sh
# $2
HERE="\$(dirname "\$(readlink -f "\$0")")"
export APPDIR="\${APPDIR:-\$HERE}"
ENTRY
    if [ "$BUNDLE_DEPS" = "1" ]; then
        cat >> "$1" <<'ENTRY'
# 使用随包内嵌的库与运行时数据
export PATH="$APPDIR/usr/bin:$PATH"
export LD_LIBRARY_PATH="$APPDIR/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export XDG_DATA_DIRS="$APPDIR/usr/share:/usr/share${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
export GSETTINGS_SCHEMA_DIR="$APPDIR/usr/share/glib-2.0/schemas"
export GIO_MODULE_DIR="$APPDIR/usr/lib/gio/modules"
export GTK_DATA_PREFIX="$APPDIR"
export GTK_EXE_PREFIX="$APPDIR"
export GTK_PATH="$APPDIR/usr/lib/gtk-3.0"
export WEBKIT_EXEC_PATH="$APPDIR/usr/lib/webkit2gtk-4.1"
export WEBKIT_INJECTED_BUNDLE_PATH="$APPDIR/usr/lib/webkit2gtk-4.1/injected-bundle/"
export GST_PLUGIN_PATH="$APPDIR/usr/lib/gstreamer-1.0"

# WebKit 的 helper 进程路径在编译期被写死，打包时已改写成 /tmp/.hiwara-wk，
# 这里在 /tmp 下建一个只有自己可写的软链目录指向包内的 helper
WK=/tmp/.hiwara-wk
if [ -d "$APPDIR/usr/lib/webkit2gtk-4.1" ]; then
    if [ ! -e "$WK" ]; then mkdir -m 700 "$WK" 2>/dev/null || true; fi
    if [ -d "$WK" ] && [ ! -L "$WK" ] && [ "$(stat -c %u "$WK" 2>/dev/null)" = "$(id -u)" ]; then
        chmod 700 "$WK" 2>/dev/null || true
        for f in "$APPDIR/usr/lib/webkit2gtk-4.1"/*; do
            [ -e "$f" ] && ln -sfn "$f" "$WK/${f##*/}" 2>/dev/null || true
        done
    fi
fi
ENTRY
        if [ -n "$PIXBUF_VER" ]; then
            cat >> "$1" <<'ENTRY'
export GDK_PIXBUF_MODULEDIR="$APPDIR/usr/lib/gdk-pixbuf-2.0/${PIXBUF_VER}/loaders"
ENTRY
            # 上面的 ${PIXBUF_VER} 需要展开，单独处理
            sed -i "s|\${PIXBUF_VER}|$PIXBUF_VER|g" "$1"
            if [ -f "$APPDIR/usr/lib/gdk-pixbuf-2.0/$PIXBUF_VER/loaders.cache" ]; then
                printf 'export GDK_PIXBUF_MODULE_FILE="$APPDIR/usr/lib/gdk-pixbuf-2.0/%s/loaders.cache"\n' "$PIXBUF_VER" >> "$1"
            fi
        fi
    fi
    cat >> "$1" <<'ENTRY'
exec "$HERE/usr/bin/hiwara" "$@"
ENTRY
    chmod 0755 "$1"
}

# 桌面文件与图标（AppImage 规范要求的顶层文件）
DESKTOP_SRC="$APPDIR/usr/share/applications/${PRODUCT}.desktop"
[ -f "$DESKTOP_SRC" ] || DESKTOP_SRC="$(find "$APPDIR/usr/share/applications" -name '*.desktop' | head -1)"
[ -n "$DESKTOP_SRC" ] && [ -f "$DESKTOP_SRC" ] || { echo "[!] 未找到 .desktop 文件"; exit 1; }

ICON_SRC="$(find "$APPDIR/usr/share/icons" -name '*.png' -printf '%s %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)"
[ -n "$ICON_SRC" ] && [ -f "$ICON_SRC" ] || { echo "[!] 未找到图标"; exit 1; }

make_entry "$APPDIR/AppRun" "Hiwara 启动入口"
cp "$ICON_SRC" "$APPDIR/${PRODUCT}.png"
ln -sfn "${PRODUCT}.png" "$APPDIR/.DirIcon"
# 与 tauri 一致：顶层 .desktop 指向 usr/share/applications 下的实际文件
ln -sfn "usr/share/applications/$(basename "$DESKTOP_SRC")" "$APPDIR/${PRODUCT}.desktop"
ok "AppDir 组装完成: $APPDIR"

# ------------------------------------------------------------
# 5. 生成 AppImage（仅当该架构有 runtime）
# ------------------------------------------------------------
if [ -n "$RUNTIME" ] && [ -f "$RUNTIME" ]; then
    log "使用 runtime: $RUNTIME ($(stat -c %s "$RUNTIME") 字节)"
    mksquashfs "$APPDIR" "$WORK/payload.squashfs" \
        -root-owned -noappend -no-xattrs -no-progress \
        -comp zstd -Xcompression-level 19 -b 128K >/dev/null
    cat "$RUNTIME" "$WORK/payload.squashfs" > "$OUT_DIR/${BUNDLE_NAME}.AppImage"
    chmod 0755 "$OUT_DIR/${BUNDLE_NAME}.AppImage"
    rm -f "$WORK/payload.squashfs"
    ok "AppImage: ${BUNDLE_NAME}.AppImage ($(du -h "$OUT_DIR/${BUNDLE_NAME}.AppImage" | cut -f1))"
else
    echo "[!] $ARCH 无 AppImage runtime，跳过 AppImage 生成（仅输出 tar.gz）"
fi

# ------------------------------------------------------------
# 6. 生成便携 tar.gz
#    结构: hiwara_{version}_linux_{arch}/hiwara + usr/ + .desktop + 图标
# ------------------------------------------------------------
STAGE="$WORK/stage/${BUNDLE_NAME}"
mkdir -p "$STAGE"
cp -a "$PAYLOAD/usr" "$STAGE/usr"
[ "$BUNDLE_DEPS" = "1" ] && cp -a "$APPDIR/usr/." "$STAGE/usr/" 2>/dev/null || true
cp "$DESKTOP_SRC" "$STAGE/${PRODUCT}.desktop"
cp "$ICON_SRC" "$STAGE/${PRODUCT}.png"
make_entry "$STAGE/hiwara" "Hiwara 便携版入口"

if [ "$BUNDLE_DEPS" = "1" ]; then
    DEP_NOTE="运行时依赖: 已内嵌（WebKitGTK / GTK3 及其依赖），无需额外安装。"
    LIB_NOTE="usr/lib/                  内嵌的依赖库与资源"
else
    DEP_NOTE="运行时依赖: libwebkit2gtk-4.1-0, libgtk-3-0（需系统安装）。"
    LIB_NOTE="usr/lib/                  应用自身的资源文件"
fi

cat > "$STAGE/README.txt" <<README
${PRODUCT} ${VERSION} - Linux ${ARCH} 便携版（${VARIANT}）
========================================

运行:
    ./hiwara

${DEP_NOTE}

目录说明:
    hiwara                    启动脚本
    usr/bin/hiwara            主程序
    ${LIB_NOTE}
    usr/share/                桌面文件与图标
README
ok "便携目录组装完成"

tar -czf "$OUT_DIR/${BUNDLE_NAME}.tar.gz" -C "$WORK/stage" "$BUNDLE_NAME"
chmod 0644 "$OUT_DIR/${BUNDLE_NAME}.tar.gz"
ok "tar.gz: ${BUNDLE_NAME}.tar.gz ($(du -h "$OUT_DIR/${BUNDLE_NAME}.tar.gz" | cut -f1))"

# ------------------------------------------------------------
# 7. 产物自检
# ------------------------------------------------------------
echo ""
echo "--- 自检: ${BUNDLE_NAME} ---"
if [ -f "$OUT_DIR/${BUNDLE_NAME}.AppImage" ]; then
    RUNTIME_SIZE=$(stat -c %s "$RUNTIME")
    file "$OUT_DIR/${BUNDLE_NAME}.AppImage" | sed 's/^/    /'
    # AppImage = runtime + squashfs，unsquashfs 需要显式指定偏移
    unsquashfs -s -o "$RUNTIME_SIZE" "$OUT_DIR/${BUNDLE_NAME}.AppImage" 2>/dev/null \
        | grep -E 'Compression|Found a valid' | sed 's/^/    /' || true
    unsquashfs -l -o "$RUNTIME_SIZE" "$OUT_DIR/${BUNDLE_NAME}.AppImage" 2>/dev/null \
        | grep -E '/AppRun$|/usr/bin/hiwara$|/\.DirIcon$' | sed 's/^/    /' || true
fi
tar -tzf "$OUT_DIR/${BUNDLE_NAME}.tar.gz" | grep -E "hiwara$|usr/bin/hiwara$|README.txt$" | sed 's/^/    /'
du -h "$OUT_DIR/${BUNDLE_NAME}".* 2>/dev/null | sed 's/^/    /'
sha256sum "$OUT_DIR/${BUNDLE_NAME}".* 2>/dev/null | sed 's/^/    /'
