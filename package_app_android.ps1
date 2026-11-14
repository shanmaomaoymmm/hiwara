# ============================================================
# Android 打包脚本
# 生成 split-per-abi APK
# 输出目录: release/
# 输出文件: hiwara_{version}_android_{arch}.apk（arch: armv7 / aarch64 / x86 / x86_64）
# ============================================================

Write-Host "========================================"
Write-Host "开始打包 Android APK (split per ABI)..."
Write-Host "========================================"

# 输出目录
$releaseDir = "release"

# 从 tauri.conf.json 读取版本号
$version = (Get-Content src-tauri/tauri.conf.json | ConvertFrom-Json).version

# 确保输出目录存在
New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

# Android (APK, split per ABI)
npm run tauri android build -- --apk --split-per-abi

if ($LASTEXITCODE -ne 0) {
    Write-Host "[!] Android 构建失败"
    exit 1
}

Write-Host ""
Write-Host "========================================"
Write-Host "重命名 APK 文件到 $releaseDir/ ..."
Write-Host "========================================"

# ABI → 简称映射（键为实际输出目录名，按长度降序排列以防子串误匹配）
$abiMap = @{
    "x86_64"  = "x86_64"
    "arm64"   = "aarch64"
    "x86"     = "x86"
    "arm"     = "armv7"
}

$apkDir = "src-tauri/gen/android/app/build/outputs/apk"

# 查找所有 release APK（排除 debug）
$apks = Get-ChildItem -Path $apkDir -Recurse -Filter "*.apk" -ErrorAction SilentlyContinue `
    | Where-Object { $_.FullName -notmatch "\\debug\\" }

$successCount = 0
foreach ($apk in $apks) {
    $matched = $false
    foreach ($abi in $abiMap.Keys) {
        # 匹配路径中的目录名（例如 ...\arm64\release\...）
        if ($apk.Directory.FullName -match "\\$abi\\") {
            $shortArch = $abiMap[$abi]
            $outputPath = "$releaseDir/hiwara_${version}_android_${shortArch}.apk"
            Copy-Item $apk.FullName $outputPath -Force
            Write-Host "[✓] $outputPath ($([math]::Round((Get-Item $outputPath).Length / 1MB, 2)) MB)"
            $successCount++
            $matched = $true
            break
        }
    }
    if (-not $matched) {
        Write-Host "[!] 未能识别 ABI: $($apk.FullName)"
    }
}

Write-Host ""
Write-Host "========================================"
Write-Host "Android 打包完成"
Write-Host "输出目录: $releaseDir/"
Write-Host "共重命名 $successCount 个 APK"
Write-Host "========================================"
