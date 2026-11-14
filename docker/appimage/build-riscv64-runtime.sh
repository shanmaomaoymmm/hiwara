#!/bin/bash
# ============================================================
# build-riscv64-runtime.sh - 交叉编译 AppImage runtime (riscv64)
#
# 在 docker/Dockerfile.riscv64-runtime 容器内运行，产物:
#   /out/runtime-riscv64
#
# 流程与上游 scripts/build-runtime.sh 对齐：
#   1. libfuse 3.15.0（打上游 mount.c.diff 补丁，静态库）
#   2. squashfuse 0.5.2（静态库，交叉编译）
#   3. runtime.c + data_sections.ld -> 静态 PIE 可执行文件
#   4. strip 后写入 "AI\x02" 魔数（offset 8），与官方 runtime 一致
#
# 与上游的差异:
#   - 不链接 mimalloc（runtime.c 未调用其 API，仅作 malloc 替换；
#     glibc 交叉环境下省略，功能不受影响）
#   - riscv64 由 Debian 交叉工具链完成，故不使用 musl 静态构建
# ============================================================
set -euo pipefail

SRC="${SRC_DIR:-/src}"
OUT="${OUT_DIR:-/out}"
WORK="${BUILD_DIR:-/build}"
PREFIX="$WORK/prefix"
TC=riscv64-linux-gnu
JOBS="$(nproc)"

export CC="${TC}-gcc"
export CXX="${TC}-g++"
export AR="${TC}-ar"
export RANLIB="${TC}-ranlib"
export STRIP="${TC}-strip"
export PKG_CONFIG_LIBDIR="/usr/lib/riscv64-linux-gnu/pkgconfig:/usr/share/pkgconfig"
export PKG_CONFIG_SYSROOT_DIR="/"

log() { echo "[i] $*"; }
ok()  { echo "[✓] $*"; }

mkdir -p "$WORK" "$OUT" "$PREFIX"
cd "$WORK"

# ------------------------------------------------------------
# 0. 源码预检（这些文件不入库，用 fetch-sources.sh 现下）
# ------------------------------------------------------------
MISSING=()
for f in runtime.c data_sections.ld mount.c.diff fuse-3.15.0.tar.gz squashfuse-0.5.2.tar.gz; do
    [ -f "$SRC/$f" ] || MISSING+=("$f")
done
if [ ${#MISSING[@]} -gt 0 ]; then
    echo "[!] 缺少编译源码: ${MISSING[*]}"
    echo "    请在宿主机执行: bash docker/config/appimage/fetch-sources.sh"
    echo "    （或由 package_app_linux_riscv64_appimage.sh 自动下载）"
    exit 1
fi
log "源码预检通过: $SRC"

# ------------------------------------------------------------
# 1. 准备源码
# ------------------------------------------------------------
# 源码包内顶层目录名由 GitHub archive 决定（libfuse-3.15.0 / squashfuse-0.5.2）
extract_tarball() {  # $1=tar 包路径  $2=目标目录
    local tarball=$1 dest=$2
    local top
    top="$(tar -tzf "$tarball" | head -1 | cut -d/ -f1)"
    rm -rf "$WORK/$dest"
    mkdir -p "$WORK/$dest"
    tar -xzf "$tarball" -C "$WORK/$dest" --strip-components=1
    echo "$WORK/$dest"
}
FUSE_SRC="$(extract_tarball "$SRC/fuse-3.15.0.tar.gz" fuse-src)"
SQFS_SRC="$(extract_tarball "$SRC/squashfuse-0.5.2.tar.gz" squashfuse-src)"
log "libfuse 源码: $FUSE_SRC"
log "squashfuse 源码: $SQFS_SRC"

# ------------------------------------------------------------
# 2. libfuse 3.15.0（静态库 + 上游补丁）
# ------------------------------------------------------------
if [ ! -f "$PREFIX/lib/libfuse3.a" ]; then
    log "构建 libfuse 3.15.0 (riscv64 交叉编译) ..."
    cd "$FUSE_SRC"
    if [ ! -f .patched ]; then
        patch -p1 < "$SRC/mount.c.diff" && touch .patched
    fi
    cat > "$WORK/riscv64-cross.ini" <<EOF
[binaries]
c = '${TC}-gcc'
ar = '${TC}-ar'
strip = '${TC}-strip'
pkgconfig = 'pkg-config'
# libfuse 的 meson.build 用 cc.run() 探测 getmntent 行为，
# 交叉编译时通过 qemu-user 运行探测程序
exe_wrapper = 'qemu-riscv64-static'

[host_machine]
system = 'linux'
cpu_family = 'riscv64'
cpu = 'riscv64'
endian = 'little'
EOF
    rm -rf build
    meson setup build \
        --cross-file "$WORK/riscv64-cross.ini" \
        --prefix="$PREFIX" \
        --default-library static \
        --buildtype minsize \
        -Dutils=false -Dexamples=false -Dtests=false >"$WORK/fuse-meson.log" 2>&1 \
        || { echo "[!] meson setup 失败:"; tail -25 "$WORK/fuse-meson.log"; exit 1; }
    ninja -C build -j "$JOBS" >"$WORK/fuse-ninja.log" 2>&1 \
        || { echo "[!] libfuse 编译失败:"; tail -25 "$WORK/fuse-ninja.log"; exit 1; }
    ninja -C build install >"$WORK/fuse-install.log" 2>&1 \
        || { echo "[!] libfuse 安装失败:"; tail -25 "$WORK/fuse-install.log"; exit 1; }
    cd "$WORK"
    ok "libfuse3.a: $(ls -l "$PREFIX/lib/libfuse3.a" | awk '{print $5}') 字节"
fi
export PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig"

# ------------------------------------------------------------
# 3. squashfuse 0.5.2（静态库）
# ------------------------------------------------------------
if [ ! -f "$PREFIX/lib/libsquashfuse_ll.a" ]; then
    log "构建 squashfuse 0.5.2 (riscv64 交叉编译) ..."
    cd "$SQFS_SRC"
    [ -x ./configure ] || ./autogen.sh >/dev/null 2>&1
    make distclean >/dev/null 2>&1 || true
    ./configure --host="$TC" --prefix="$PREFIX" \
        --disable-demo --disable-multithreading \
        --disable-shared --enable-static \
        LDFLAGS="-L/usr/lib/riscv64-linux-gnu -L$PREFIX/lib" \
        CPPFLAGS="-I$PREFIX/include" >"$WORK/sqfs-configure.log" 2>&1 \
        || { echo "[!] squashfuse configure 失败:"; tail -25 "$WORK/sqfs-configure.log"; exit 1; }
    make -j "$JOBS" >"$WORK/sqfs-make.log" 2>&1 \
        || { echo "[!] squashfuse 编译失败:"; tail -25 "$WORK/sqfs-make.log"; exit 1; }
    make install >"$WORK/sqfs-install.log" 2>&1 \
        || { echo "[!] squashfuse 安装失败:"; tail -25 "$WORK/sqfs-install.log"; exit 1; }
    # 上游只安装 ll.h，runtime.c 还需要 fuseprivate.h 等内部头文件
    mkdir -p "$PREFIX/include/squashfuse"
    install -m 644 "$SQFS_SRC"/*.h "$PREFIX/include/squashfuse/"
    cd "$WORK"
    ok "squashfuse 静态库构建完成"
fi

# ------------------------------------------------------------
# 4. 链接 runtime（静态 PIE）
# ------------------------------------------------------------
log "编译 runtime.c -> runtime-riscv64 ..."
"$CC" -std=gnu99 -Os -D_FILE_OFFSET_BITS=64 \
    -DGIT_COMMIT=\"cross-riscv64\" \
    -T "$SRC/data_sections.ld" \
    -ffunction-sections -fdata-sections \
    -Wl,--gc-sections -static -no-pie \
    -I"$PREFIX/include" -I"$PREFIX/include/fuse3" \
    "$SRC/runtime.c" -o "$WORK/runtime-riscv64" \
    -L"$PREFIX/lib" -L/usr/lib/riscv64-linux-gnu \
    -lsquashfuse -lsquashfuse_ll -lzstd -lz -lfuse3 -lpthread

# ------------------------------------------------------------
# 5. strip + 写入 AppImage 魔数（与官方构建脚本一致）
# ------------------------------------------------------------
"$STRIP" --strip-debug --strip-unneeded "$WORK/runtime-riscv64"
printf 'AI\x02' | dd of="$WORK/runtime-riscv64" bs=1 count=3 seek=8 conv=notrunc status=none

cp "$WORK/runtime-riscv64" "$OUT/runtime-riscv64"
chmod 0755 "$OUT/runtime-riscv64"

# ------------------------------------------------------------
# 6. 产物校验
# ------------------------------------------------------------
echo ""
echo "--- runtime-riscv64 自检 ---"
file "$OUT/runtime-riscv64" | sed 's/^/    /'
printf "    magic: "; od -An -c -j 8 -N 3 "$OUT/runtime-riscv64" | tr -d ' \n'; echo
printf "    大小: %s 字节\n" "$(stat -c %s "$OUT/runtime-riscv64")"
if "$TC"-readelf -h "$OUT/runtime-riscv64" | grep -q 'RISC-V'; then
    ok "ELF 架构确认为 RISC-V"
else
    echo "[!] ELF 架构校验失败"
    exit 1
fi
ok "完成: $OUT/runtime-riscv64"
