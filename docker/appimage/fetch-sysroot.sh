#!/bin/bash
# ============================================================
# fetch-sysroot.sh - 下载并解包指定架构的运行时依赖到 sysroot
#
# 用途: 为 AppImage / tar.gz 的「内嵌依赖」版本准备库文件。
#       只用 apt 解析依赖 + dpkg -x 解包，不做真实安装，
#       因此可以同时准备 amd64 / arm64 / riscv64 三套。
#
# 关键点: 用空的 dpkg status 让 apt 认为「什么都没装」，
#         否则构建容器里已安装的包（如 libglib2.0-0t64）会被
#         当成已满足而漏掉，导致内嵌的依赖树不完整。
#
# 用法: fetch-sysroot.sh <arch> <dest>
#   arch: amd64 | arm64 | riscv64
#   dest: 例如 /sysroot/arm64
# ============================================================
set -euo pipefail

ARCH="${1:?需要架构 (amd64/arm64/riscv64)}"
DEST="${2:?需要目标目录}"

case "$ARCH" in
    amd64|arm64|riscv64) ;;
    *) echo "[!] 不支持的架构: $ARCH"; exit 1 ;;
esac

# WebKitGTK + GTK3 + glib 网络（TLS）后端
PKGS=(
    libwebkit2gtk-4.1-0
    libgtk-3-0
    libgdk-pixbuf-2.0-0
    glib-networking
)

mkdir -p "$DEST"
cd "$DEST"
rm -rf .debs root
mkdir -p .debs root

echo "[i] $ARCH: 解析依赖 ..."
: > empty-status
apt-get install --print-uris -y --no-install-recommends \
    -o Dir::State::status="$DEST/empty-status" \
    -o APT::Architecture="$ARCH" \
    -o APT::Architectures::="$ARCH" \
    "${PKGS[@]/%/:$ARCH}" > uris.txt 2>/dev/null \
    || { echo "[!] apt 依赖解析失败 ($ARCH)"; exit 1; }

# 只保留目标架构（以及 all）的 deb，避免把宿主架构的包混进 sysroot
grep -o "'http[^']*\.deb'" uris.txt \
    | tr -d "'" \
    | grep -E "_${ARCH}\.deb$|_all\.deb$" \
    | sort -u > urls.txt
COUNT=$(wc -l < urls.txt)
[ "$COUNT" -gt 0 ] || { echo "[!] $ARCH: 没解析到任何 deb 链接"; exit 1; }
echo "[i] $ARCH: 需要 $COUNT 个包"

cd .debs
FAILED_DL=0
while read -r url; do
    f="$(basename "$url")"
    [ -f "$f" ] && continue
    if curl -fsSL --retry 3 -o "$f" "$url"; then
        continue
    fi
    # 回退：按包名交给 apt（先解码 %2b/%7e 等转义）
    base="$(basename "$url" .deb | sed -e 's/%2[bB]/+/g' -e 's/%7[eE]/~/g')"
    pkg="${base%%_*}"
    parch="${base##*_}"
    spec="$pkg"
    [ "$parch" != "all" ] && spec="$pkg:$parch"
    echo "[i] $ARCH: curl 失败，改用 apt-get download $spec"
    apt-get download -o APT::Architecture="$ARCH" "$spec" >>download.log 2>&1 || {
        echo "[!] $ARCH: 下载失败 $spec"
        FAILED_DL=$((FAILED_DL + 1))
    }
done < ../urls.txt
cd ..
[ "$FAILED_DL" -eq 0 ] || { echo "[!] $ARCH: 有 $FAILED_DL 个包下载失败"; exit 1; }
echo "[i] $ARCH: 实到 $(ls .debs/*.deb | wc -l) 个包"

echo "[i] $ARCH: 解包 ..."
for deb in .debs/*.deb; do
    dpkg -x "$deb" root/ || { echo "[!] 解包失败: $deb"; exit 1; }
done

# 关键库自检，避免依赖树再次不完整
for soname in libglib-2.0.so.0 libgobject-2.0.so.0 libgtk-3.so.0 libwebkit2gtk-4.1.so.0; do
    if ! find root -name "$soname" -print -quit | grep -q .; then
        echo "[!] $ARCH sysroot 缺少关键库: $soname"
        exit 1
    fi
done

echo "[✓] $ARCH sysroot 就绪: $DEST/root ($(du -sh root | cut -f1))"
