#!/bin/bash
# ============================================================
# bundle-deps.sh - 把运行时依赖内嵌进 AppDir（自包含发行包）
#
# 做法:
#   1. 从主程序的 DT_NEEDED 出发，按 sysroot 里的库递归求依赖闭包
#   2. 跳过「最小排除清单」（glibc / libstdc++ / 图形驱动 / 音频服务栈）
#   3. 把库复制到 AppDir/usr/lib，并给主程序和库写 rpath
#   4. 复制并补齐 WebKit helper、gio 模块、gdk-pixbuf 加载器、
#      GStreamer 插件这些「dlopen 型」依赖的库闭包
#   5. 改写 WebKit helper 的编译期绝对路径，由 AppRun 在 /tmp 建软链
#
# 用法: bundle-deps.sh <AppDir> <sysroot> <主程序相对路径> [excludelist]
#   例: bundle-deps.sh /tmp/Hiwara.AppDir /sysroot/amd64/root usr/bin/hiwara
# ============================================================
set -euo pipefail

APPDIR="${1:?需要 AppDir 路径}"
SYSROOT="${2:?需要 sysroot 路径（含 usr/lib/... 的根）}"
APP_REL="${3:?需要主程序相对路径，例如 usr/bin/hiwara}"
EXCLUDELIST="${4:-/tools/appimage/excludelist-minimal}"

APP_BIN="$APPDIR/$APP_REL"
DEST_LIB="$APPDIR/usr/lib"

log() { echo "[i] $*"; }
ok()  { echo "[✓] $*"; }

[ -f "$APP_BIN" ] || { echo "[!] 主程序不存在: $APP_BIN"; exit 1; }
[ -d "$SYSROOT" ] || { echo "[!] sysroot 不存在: $SYSROOT"; exit 1; }
command -v patchelf >/dev/null || { echo "[!] 缺少 patchelf"; exit 1; }
command -v readelf >/dev/null || { echo "[!] 缺少 readelf"; exit 1; }

# ------------------------------------------------------------
# 排除清单
# ------------------------------------------------------------
declare -A EXCLUDED
if [ -f "$EXCLUDELIST" ]; then
    while IFS= read -r line; do
        line="${line%%#*}"
        line="$(echo "$line" | tr -d '\r' | xargs)"
        [ -n "$line" ] && EXCLUDED["$line"]=1
    done < "$EXCLUDELIST"
fi
log "排除清单条目: ${#EXCLUDED[@]}"

# ------------------------------------------------------------
# soname -> 真实文件 索引
# ------------------------------------------------------------
declare -A SONAME_MAP
mapfile -t ALL_SO < <(find "$SYSROOT" -type f \( -name '*.so' -o -name '*.so.*' \) 2>/dev/null)
log "sysroot 内库文件: ${#ALL_SO[@]}，建立 soname 索引 ..."
for f in "${ALL_SO[@]}"; do
    soname=$(readelf -d "$f" 2>/dev/null | sed -n 's/.*SONAME.*\[\(.*\)\]/\1/p' | head -1 || true)
    if [ -n "$soname" ] && [ -z "${SONAME_MAP[$soname]:-}" ]; then
        SONAME_MAP["$soname"]="$f"
    fi
done

needed_of() {
    readelf -d "$1" 2>/dev/null | sed -n 's/.*NEEDED.*\[\(.*\)\]/\1/p' || true
}

# ------------------------------------------------------------
# 依赖闭包收集（可多次调用，补齐 dlopen 模块的依赖）
# ------------------------------------------------------------
declare -A DONE
BUNDLED_COUNT=0

resolve_deps_for() {  # $@=起始 ELF 文件
    local queue=() f n src
    for f in "$@"; do
        [ -f "$f" ] || continue
        for n in $(needed_of "$f"); do queue+=("$n"); done
    done

    while [ ${#queue[@]} -gt 0 ]; do
        local soname="${queue[0]}"
        queue=("${queue[@]:1}")

        [ -n "${DONE[$soname]:-}" ] && continue
        DONE["$soname"]=1

        [ -n "${EXCLUDED[$soname]:-}" ] && continue   # 系统提供

        src="${SONAME_MAP[$soname]:-}"
        if [ -z "$src" ]; then
            continue   # 交给后面的完整性检查报告
        fi

        cp -L "$src" "$DEST_LIB/$soname"
        chmod 0755 "$DEST_LIB/$soname"
        for n in $(needed_of "$DEST_LIB/$soname"); do
            if [ -z "${DONE[$n]:-}" ]; then queue+=("$n"); fi
        done
    done
}

mkdir -p "$DEST_LIB"
log "解析主程序依赖 ..."
resolve_deps_for "$APP_BIN"
BUNDLED_COUNT=$(find "$DEST_LIB" -maxdepth 1 -name '*.so*' | wc -l)
log "主程序依赖已内嵌: $BUNDLED_COUNT 个库"

# ------------------------------------------------------------
# rpath: 主程序 -> $ORIGIN/../lib，内嵌库 -> $ORIGIN
# ------------------------------------------------------------
log "写入 rpath ..."
patchelf --set-rpath '$ORIGIN/../lib' "$APP_BIN"
for f in "$DEST_LIB"/*.so*; do
    if [ -f "$f" ] && head -c 4 "$f" | grep -q ELF; then
        patchelf --set-rpath '$ORIGIN' "$f" 2>/dev/null || true
    fi
done

# ------------------------------------------------------------
# 运行时数据目录
# ------------------------------------------------------------
copy_dir_if_exists() {  # $1=源 $2=目标
    if [ -d "$1" ]; then
        mkdir -p "$2"
        cp -a "$1/." "$2/"
        echo "    + ${1#$SYSROOT/} -> ${2#$APPDIR/}"
    fi
}

MULTIARCH_LIB=$(find "$SYSROOT/usr/lib" -maxdepth 1 -type d -name '*-linux-gnu*' | head -1)
log "数据目录:"

# WebKit 的 WebKitWebProcess / WebKitNetworkProcess / injected-bundle
copy_dir_if_exists "$MULTIARCH_LIB/webkit2gtk-4.1" "$APPDIR/usr/lib/webkit2gtk-4.1"

# gio 模块（glib-networking 的 TLS 后端、libproxy 等）
copy_dir_if_exists "$MULTIARCH_LIB/gio/modules" "$APPDIR/usr/lib/gio/modules"

# gdk-pixbuf 加载器
PIXBUF_DIR=$(find "$SYSROOT/usr/lib" -maxdepth 3 -type d -name 'gdk-pixbuf-2.0' | head -1)
if [ -n "$PIXBUF_DIR" ]; then
    ver_dir=$(find "$PIXBUF_DIR" -maxdepth 1 -type d -name '2.*' | head -1)
    if [ -n "$ver_dir" ] && [ -d "$ver_dir/loaders" ]; then
        copy_dir_if_exists "$ver_dir/loaders" "$APPDIR/usr/lib/gdk-pixbuf-2.0/$(basename "$ver_dir")/loaders"
    fi
fi

# GStreamer 插件（WebView 内的音视频解码）
GST_DIR=$(find "$SYSROOT/usr/lib" -maxdepth 2 -type d -name 'gstreamer-1.0' | head -1)
if [ -n "$GST_DIR" ]; then
    copy_dir_if_exists "$GST_DIR" "$APPDIR/usr/lib/gstreamer-1.0"
fi

# glib schema（GSettings）
copy_dir_if_exists "$SYSROOT/usr/share/glib-2.0/schemas" "$APPDIR/usr/share/glib-2.0/schemas"
if [ -d "$APPDIR/usr/share/glib-2.0/schemas" ] && command -v glib-compile-schemas >/dev/null; then
    glib-compile-schemas "$APPDIR/usr/share/glib-2.0/schemas"
    echo "    + glib schema 已编译 (gschemas.compiled)"
fi

# WebKit 沙箱依赖 bwrap / xdg-dbus-proxy
for tool in bwrap xdg-dbus-proxy; do
    for cand in "$SYSROOT/usr/bin/$tool" "$SYSROOT/usr/libexec/$tool" "$MULTIARCH_LIB/$tool"; do
        if [ -f "$cand" ]; then
            cp -L "$cand" "$APPDIR/usr/bin/$tool"
            chmod 0755 "$APPDIR/usr/bin/$tool"
            echo "    + usr/bin/$tool"
            break
        fi
    done
done

# ------------------------------------------------------------
# dlopen 型模块的依赖补齐（gio 模块 / pixbuf 加载器 / gst 插件）
# ------------------------------------------------------------
mapfile -t MODULE_SOS < <(find "$APPDIR/usr/lib/gio/modules" \
                                 "$APPDIR/usr/lib/gstreamer-1.0" \
                                 "$APPDIR/usr/lib/gdk-pixbuf-2.0" \
                                 -type f -name '*.so*' 2>/dev/null)
if [ ${#MODULE_SOS[@]} -gt 0 ]; then
    log "补齐 ${#MODULE_SOS[@]} 个 dlopen 模块的依赖 ..."
    resolve_deps_for "${MODULE_SOS[@]}"
    for f in "${MODULE_SOS[@]}"; do
        if [ -f "$f" ] && head -c 4 "$f" | grep -q ELF; then
            patchelf --set-rpath '$ORIGIN' "$f" 2>/dev/null || true
        fi
    done
fi
BUNDLED_COUNT=$(find "$DEST_LIB" -maxdepth 1 -name '*.so*' | wc -l)

# ------------------------------------------------------------
# WebKit helper 路径改写
#   /usr/lib/<multiarch>/webkit2gtk-4.1 是编译期硬编码的绝对路径，
#   AppImage 无 root 无法在宿主创建它，改写为 /tmp/.hiwara-wk，
#   由 AppRun 在 /tmp 建用户私有软链目录指过去。
#   （WEBKIT_INJECTED_BUNDLE_PATH 只覆盖 injected-bundle，覆盖不到 helper）
# ------------------------------------------------------------
WK_SO="$DEST_LIB/libwebkit2gtk-4.1.so.0"
MULTIARCH_NAME=$(basename "$MULTIARCH_LIB" 2>/dev/null || true)
if [ -f "$WK_SO" ] && [ -n "$MULTIARCH_NAME" ]; then
    WK_ORIG="/usr/lib/$MULTIARCH_NAME/webkit2gtk-4.1"
    WK_NEW="/tmp/.hiwara-wk"
    if grep -qa "$WK_ORIG" "$WK_SO"; then
        ORIG="$WK_ORIG" NEW="$WK_NEW" perl -0777 -pi -e '
            BEGIN { $o = $ENV{ORIG}; $n = $ENV{NEW}; }
            s/\Q$o\E\x00/$n . ("\x00" x (length($o) - length($n) + 1))/ge;
            my $obj = $o . "/injected-bundle/";
            my $nb  = $n . "/injected-bundle/";
            s/\Q$obj\E\x00/$nb . ("\x00" x (length($obj) - length($nb) + 1))/ge;
        ' "$WK_SO"
        if grep -qa "$WK_NEW" "$WK_SO"; then
            echo "    + WebKit helper 路径已改写: $WK_ORIG -> $WK_NEW"
        else
            echo "    [!] WebKit helper 路径改写未生效（运行时需要系统 webkit2gtk-4.1）"
        fi
    fi
fi

# ------------------------------------------------------------
# 完整性自检：每个 NEEDED 必须「包内已有」或「在排除清单里」
# 跨架构唯一的可行校验（arm64/riscv64 无法实跑）
# ------------------------------------------------------------
UNRESOLVED=()
for f in "$APP_BIN" "$DEST_LIB"/*.so*; do
    [ -f "$f" ] || continue
    for n in $(needed_of "$f"); do
        [ -n "${EXCLUDED[$n]:-}" ] && continue
        [ -f "$DEST_LIB/$n" ] && continue
        UNRESOLVED+=("$(basename "$f") -> $n")
    done
done

if [ ${#UNRESOLVED[@]} -gt 0 ]; then
    echo "[!] 依赖闭包不完整，共 ${#UNRESOLVED[@]} 项未解析:"
    printf '    %s\n' "${UNRESOLVED[@]}" | head -20
    if [ "${STRICT_DEPS:-1}" = "1" ]; then
        exit 1
    fi
else
    echo "[✓] 依赖闭包完整：所有 NEEDED 均已内嵌或在排除清单中"
fi

DATA_SIZE=$(du -sh "$DEST_LIB" | cut -f1)
ok "依赖内嵌完成: ${BUNDLED_COUNT} 个库，usr/lib 共 $DATA_SIZE"
