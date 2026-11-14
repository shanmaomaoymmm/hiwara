#!/bin/bash
# ============================================================
# 获取 AppImage type2 runtime（离线打包所需）
#
# 来源: https://github.com/AppImage/type2-runtime/releases (continuous)
# 产物: docker/config/appimage/runtime-{x86_64,aarch64}
#
# 上游仅发布 i686/x86_64/armhf/aarch64，没有 riscv64，
# riscv64 的 runtime 由附加脚本 package_app_linux_riscv64_appimage.sh
# 通过交叉编译自建（见 docker/Dockerfile.riscv64-runtime）。
#
# 使用:
#   bash docker/config/appimage/fetch-runtimes.sh
# ============================================================
set -euo pipefail
cd "$(dirname "$0")"

BASE="https://github.com/AppImage/type2-runtime/releases/download/continuous"

for rt in x86_64 aarch64; do
    if [ -f "runtime-$rt" ] && sha256sum -c --status SHA256SUMS 2>/dev/null; then
        echo "[✓] runtime-$rt 已存在且校验通过"
        continue
    fi
    echo "[i] 下载 runtime-$rt ..."
    curl -fL --retry 3 --retry-delay 2 -o "runtime-$rt.tmp" "$BASE/runtime-$rt"
    mv "runtime-$rt.tmp" "runtime-$rt"
done

echo "[i] 校验 SHA256 ..."
sha256sum -c <(tr -d '\r' < SHA256SUMS)
chmod 0755 runtime-x86_64 runtime-aarch64
echo "[✓] 完成"
