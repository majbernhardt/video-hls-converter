#!/usr/bin/env pwsh
param (
  [string]$config = "./config.json",
  [int]$height,
  [int]$crf,
  [string]$preset,
  [int]$audioBitrate,
  [int]$hlsTime
)

# Читаем конфиг
if (Test-Path $config) {
  $jsonConfig = Get-Content $config | ConvertFrom-Json
  Write-Host "DEBUG: Конфиг загружен" 
  Write-Host "DEBUG: $jsonConfig"
} else {
  Write-Host "Файл конфигурации '$config' не найден. Используются только переданные параметры."
  $jsonConfig = @{}
}

# Приоритет: аргументы > конфиг > дефолт
$finalHeight = $height ? $height : ($jsonConfig.height ? $jsonConfig.height : 1080)
$finalCrf = $crf ? $crf : ($jsonConfig.crf ? $jsonConfig.crf : 23)
$finalPreset = $preset ? $preset : ($jsonConfig.preset ? $jsonConfig.preset : "slow")
$finalAudioBitrate = $audioBitrate ? $audioBitrate : ($jsonConfig.audioBitrate ? $jsonConfig.audioBitrate : 128)
$finalHlsTime = $hlsTime ? $hlsTime : ($jsonConfig.hlsTime ? $jsonConfig.hlsTime : 6)

$inputDir = "video"
$outputDir = "video-hls"

# Абсолютные пути
$inputDirFull = (Resolve-Path $inputDir).Path
$outputDirFull = (Resolve-Path $outputDir -ErrorAction SilentlyContinue)

if (-not $outputDirFull) {
  New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
  $outputDirFull = (Resolve-Path $outputDir).Path
}

# Поддерживаемые расширения
$videoExtensions = @('.mov', '.mp4', '.mkv', '.avi', '.webm', '.flv', '.wmv', '.mpeg', '.mpg')

# Поиск видео и конвертация
Get-ChildItem -Path $inputDirFull -Recurse -File | Where-Object {
  $videoExtensions -contains $_.Extension.ToLower()
} | ForEach-Object {
  $inputFile = $_.FullName
  $relativePath = $inputFile.Substring($inputDirFull.Length + 1)
  $baseName = [System.IO.Path]::GetFileNameWithoutExtension($relativePath)
  $dirName = [System.IO.Path]::GetDirectoryName($relativePath)

  $destDir = Join-Path $outputDirFull $dirName
  $destDirFull = Join-Path $destDir $baseName
  New-Item -ItemType Directory -Force -Path $destDirFull | Out-Null

  $outputM3U8 = Join-Path $destDirFull "$baseName.m3u8"
  $outputTs = Join-Path $destDirFull "$baseName_%03d.ts"

  Write-Host "Конвертация из $relativePath в $outputM3U8"
  Write-Host "Используемые параметры:"
  Write-Host "Height: $finalHeight"
  Write-Host "CRF: $finalCrf"
  Write-Host "Preset: $finalPreset"
  Write-Host "Audio Bitrate: $finalAudioBitrate"
  Write-Host "HLS Time: $finalHlsTime"

  ffmpeg -i "$inputFile" `
    -vf "scale=-2:$finalHeight" `
    -c:v libx264 -crf $finalCrf -preset $finalPreset `
    -c:a aac -b:a ${finalAudioBitrate}k `
    -hls_time $finalHlsTime `
    -hls_playlist_type vod `
    -hls_segment_filename "$outputTs" `
    "$outputM3U8"

  Write-Host "✅ Готово: $relativePath"
}
