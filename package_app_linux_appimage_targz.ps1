# ============================================================
# Linux AppImage + tar.gz 打包脚本 (Windows -> WSL 包装器)
#
# 在 WSL 中执行 package_app_linux_appimage_targz.sh，
# 把 release/ 下已有的 .deb 组装成 AppImage 与 tar.gz。
#
# 输出目录: release/
# 输出文件（两个变体）:
#   hiwara_{version}_linux_{arch}.AppImage      不内嵌依赖（同 deb/rpm）
#   hiwara_{version}_linux_{arch}.tar.gz
#   hiwara_{version}_linux_full_{arch}.AppImage 内嵌全部运行时依赖
#   hiwara_{version}_linux_full_{arch}.tar.gz
#
# 使用方式:
#   .\package_app_linux_appimage_targz.ps1                      # 三个架构
#   .\package_app_linux_appimage_targz.ps1 -Arch x64,arm64      # 指定架构
#   .\package_app_linux_appimage_targz.ps1 -Variant linux       # 只出不内嵌依赖的版本
#   .\package_app_linux_appimage_targz.ps1 -Variant linux_full  # 只出全依赖版本
#   .\package_app_linux_appimage_targz.ps1 -Arch riscv64        # 仅 RISC-V（自动调用附加脚本编译 runtime）
#   .\package_app_linux_appimage_targz.ps1 -F                   # 强制重建工具镜像
#   .\package_app_linux_appimage_targz.ps1 -H                   # 帮助
# ============================================================

param(
    [Alias("A")]
    [Parameter(Mandatory = $false, HelpMessage = "目标架构，可用值: x64, arm64, riscv64，逗号分隔。默认全部")]
    [ValidateSet("x64", "arm64", "riscv64")]
    [string[]]$Arch,

    [Alias("V")]
    [Parameter(Mandatory = $false, HelpMessage = "发行变体: linux（不含依赖）/ linux_full（含全部依赖）。默认两个都出")]
    [ValidateSet("linux", "linux_full")]
    [string[]]$Variant,

    [Alias("F")]
    [Parameter(Mandatory = $false, HelpMessage = "强制重建工具镜像")]
    [switch]$ForceAll,

    [Alias("D")]
    [Parameter(Mandatory = $false, HelpMessage = "WSL 发行版名称，默认 Debian")]
    [string]$Distro = "Debian",

    [Alias("H")]
    [Parameter(Mandatory = $false, HelpMessage = "显示帮助")]
    [switch]$Help
)

if ($Help) {
    Write-Host "Linux AppImage + tar.gz 打包 (通过 WSL Docker)"
    Write-Host "  -Arch / -A       x64,arm64,riscv64（默认全部）"
    Write-Host "  -Variant / -V    linux（不内嵌依赖）/ linux_full（内嵌全部依赖），默认两个都出"
    Write-Host "  -F           强制重建工具镜像"
    Write-Host "  -Distro      WSL 发行版（默认 Debian）"
    Write-Host "注意: RISC-V 无官方 runtime，会调用 package_app_linux_riscv64_appimage.sh 自建 runtime"
    exit 0
}

$ErrorActionPreference = "Stop"
$winPath = (Get-Location).Path
$wslPath = (wsl -d $Distro -- wslpath -a "$winPath").Trim()
if ([string]::IsNullOrWhiteSpace($wslPath)) {
    # 回退：手动转换 C:\Users\... -> /mnt/c/Users/...
    $drive = $winPath.Substring(0, 1).ToLower()
    $rest = $winPath.Substring(3) -replace '\\', '/'
    $wslPath = "/mnt/$drive/$rest"
}

$scriptArgs = @()
if ($Arch -and $Arch.Count -gt 0) {
    $scriptArgs += "--arch"
    $scriptArgs += $Arch
}
if ($Variant -and $Variant.Count -gt 0) {
    $scriptArgs += "--variant"
    $scriptArgs += $Variant
}
if ($ForceAll) { $scriptArgs += "-F" }
$scriptArgsStr = ($scriptArgs -join " ")

Write-Host "[i] Windows 路径: $winPath"
Write-Host "[i] WSL 路径:     $wslPath"
Write-Host "[i] 执行: bash package_app_linux_appimage_targz.sh $scriptArgsStr"
Write-Host ""

wsl -d $Distro -- bash -lc "cd '$wslPath' && bash package_app_linux_appimage_targz.sh $scriptArgsStr"
$exitCode = $LASTEXITCODE

Write-Host ""
Write-Host "========================================"
Write-Host "产物列表 (release/)"
Write-Host "========================================"
$version = (Get-Content src-tauri/tauri.conf.json | ConvertFrom-Json).version
Get-ChildItem -Path "release" -Filter "hiwara_${version}_linux_*" -ErrorAction SilentlyContinue |
    Sort-Object Name |
    ForEach-Object { "[✓] {0,-42} {1,8:N2} MB" -f $_.Name, ($_.Length / 1MB) }

if ($exitCode -ne 0) {
    Write-Host "[!] 打包失败，退出码: $exitCode"
    exit $exitCode
}
