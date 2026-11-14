#!/bin/bash
# ============================================================
# fetch-sources.sh - 下载 RISC-V AppImage runtime 的构建源码
#
# 这些文件都不入库（见 .gitignore），按需现下：
#   - type2-runtime 的 runtime.c / data_sections.ld / mount.c.diff
#   - libfuse 3.15.0 源码包（打上游补丁用）
#   - squashfuse 0.5.2 源码包
#
# 产物目录: docker/config/appimage/src/
# 由 build-riscv64-runtime.sh 在容器内使用。
#
# 使用:
#   bash docker/config/appimage/fetch-sources.sh
#   TYPE2_RUNTIME_REF=<commit|tag> bash docker/config/appimage/fetch-sources.sh
# ============================================================
set -euo pipefail
cd "$(dirname "$0")"

SRC_DIR="src"
REF="${TYPE2_RUNTIME_REF:-main}"
mkdir -p "$SRC_DIR"

# 文件名|SHA256|URL
ITEMS=(
    "runtime.c|e90a7685e1e11cd422bbc9cc0032c975ef9ca998e3c3708050c1c5134286f618|https://raw.githubusercontent.com/AppImage/type2-runtime/${REF}/src/runtime/runtime.c"
    "data_sections.ld|3d62a1eaa49c62569927a668d1c62d4b6ebf94a14db9b39ef99ea3d14cd79ab2|https://raw.githubusercontent.com/AppImage/type2-runtime/${REF}/src/runtime/data_sections.ld"
    "mount.c.diff|1c7fd9e26717545a476b226b083a9f9d05676c180edbd71a04bbd8a73599dc44|https://raw.githubusercontent.com/AppImage/type2-runtime/${REF}/patches/libfuse/mount.c.diff"
    "fuse-3.15.0.tar.gz|1e79f1dd60eaf79645c21411c4a7028c97b5e745ea677ac5bda747c90497a785|https://github.com/libfuse/libfuse/archive/refs/tags/fuse-3.15.0.tar.gz"
    "squashfuse-0.5.2.tar.gz|db0238c5981dabbd80ee09ae15387f390091668ca060a7bc38047912491443d3|https://github.com/vasi/squashfuse/archive/refs/tags/0.5.2.tar.gz"
)

FAILED=0
for item in "${ITEMS[@]}"; do
    IFS='|' read -r name sha url <<< "$item"
    dest="$SRC_DIR/$name"

    if [ -f "$dest" ]; then
        actual=$(sha256sum "$dest" | cut -d' ' -f1)
        if [ "$actual" = "$sha" ]; then
            echo "[✓] $name 已存在且校验通过"
            continue
        fi
        echo "[!] $name 校验不一致，重新下载（可能上游 ${REF} 已更新）"
        rm -f "$dest"
    fi

    echo "[i] 下载 $name ..."
    if ! curl -fL --retry 3 --retry-delay 2 -o "$dest.tmp" "$url"; then
        echo "[!] 下载失败: $url"
        rm -f "$dest.tmp"
        FAILED=$((FAILED + 1))
        continue
    fi
    actual=$(sha256sum "$dest.tmp" | cut -d' ' -f1)
    if [ "$actual" != "$sha" ]; then
        echo "[!] $name SHA256 不匹配"
        echo "    期望: $sha"
        echo "    实际: $actual"
        rm -f "$dest.tmp"
        FAILED=$((FAILED + 1))
        continue
    fi
    mv "$dest.tmp" "$dest"
done

if [ "$FAILED" -gt 0 ]; then
    echo ""
    echo "[!] $FAILED 个文件下载失败"
    echo "    如果上游 $REF 分支已更新，可指定具体 ref:"
    echo "      TYPE2_RUNTIME_REF=<commit-sha> bash $0"
    exit 1
fi

echo "[✓] 源码就绪: $SRC_DIR/"
