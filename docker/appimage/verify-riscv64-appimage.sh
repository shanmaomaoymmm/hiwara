#!/bin/bash
# ============================================================
# verify-riscv64-appimage.sh - 在容器内校验 RISC-V AppImage
#
# 通过 qemu-riscv64-static 运行 AppImage 的自建 runtime，
# 完整走一遍 ELF 加载 + squashfs（含 zstd 解压）解析 + 文件提取。
# 真正的 GUI 启动需要在 RISC-V 真机上验证（本机无 binfmt/QEMU 全用户态
# 环境，且缺少 riscv64 的 webkit2gtk 运行库）。
#
# 用法: verify-riscv64-appimage.sh <AppImage 路径>
# ============================================================
set -uo pipefail

IMG="${1:?需要 AppImage 路径}"
IMG="$(readlink -f "$IMG")"

echo "--- RISC-V AppImage 校验: $(basename "$IMG") ---"
file "$IMG" | sed 's/^/    /'

echo "    magic: $(od -An -c -j 8 -N 3 "$IMG" | tr -d ' \n')"

echo "    runtime 自检:"
qemu-riscv64-static "$IMG" --appimage-version | sed 's/^/      /'
printf "    payload 偏移: %s\n" "$(qemu-riscv64-static "$IMG" --appimage-offset)"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

echo "    提取测试（qemu + squashfuse，含 zstd 解压）:"
if ! qemu-riscv64-static "$IMG" --appimage-extract >"$WORK/extract.log" 2>&1; then
    echo "[!] 提取失败:"
    tail -15 "$WORK/extract.log" | sed 's/^/      /'
    exit 1
fi

for f in AppRun Hiwara.desktop .DirIcon usr/bin/hiwara; do
    if [ ! -e "$WORK/squashfs-root/$f" ]; then
        echo "[!] 缺少 $f"
        exit 1
    fi
done
echo "      AppRun / Hiwara.desktop / .DirIcon / usr/bin/hiwara 均在位"
printf "      条目数: %s\n" "$(find "$WORK/squashfs-root" | wc -l)"
printf "      字体:   %s 个\n" "$(find "$WORK/squashfs-root/usr/lib" -name '*.ttf' | wc -l)"
file -b "$WORK/squashfs-root/usr/bin/hiwara" | sed 's/^/      主程序: /'
[ -x "$WORK/squashfs-root/usr/bin/hiwara" ] && echo "      主程序可执行位: ok"

echo "[✓] RISC-V AppImage 结构校验通过"
