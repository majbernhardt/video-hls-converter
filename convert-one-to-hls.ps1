$inputFile = "video/module/video_name.mov"
$outputDir = "video-hls/module/video_name.mov"

# Получим имя файла без расширения
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($inputFile)

# Создадим директорию для HLS
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

# Пути для выходных файлов
$outputM3U8 = Join-Path $outputDir "$baseName.m3u8"
$outputTs = Join-Path $outputDir "$baseName_%03d.ts"

# Конвертация в HLS 1080p
ffmpeg -i $inputFile `
    -vf "scale=-2:1080" -c:v libx264 -crf 23 -preset slow `
    -c:a aac -b:a 128k `
    -hls_time 6 `
    -hls_playlist_type vod `
    -hls_segment_filename $outputTs `
    $outputM3U8

Write-Host "Готово! Файл $inputFile сконвертирован в HLS."
