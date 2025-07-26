$inputDir = "video" 
$outputDir = "video-hls"

Get-ChildItem -Path $inputDir -Recurse -Filter *.mov | ForEach-Object {
    $inputFile = $_.FullName
    $relativePath = $inputFile.Substring($inputDir.Length + 1)
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($relativePath)
    $dirName = [System.IO.Path]::GetDirectoryName($relativePath)

    $destDir = Join-Path $outputDir $dirName
    $destDirFull = Join-Path $destDir $baseName
    New-Item -ItemType Directory -Force -Path $destDirFull | Out-Null

    $outputM3U8 = Join-Path $destDirFull "$baseName.m3u8"
    $outputTs = Join-Path $destDirFull "$baseName_%03d.ts"

    Write-Host "Конвертирую: $relativePath"

    ffmpeg -i $inputFile `
        -vf "scale=-2:1080" -c:v libx264 -crf 23 -preset slow `
        -c:a aac -b:a 128k `
        -hls_time 6 `
        -hls_playlist_type vod `
        -hls_segment_filename $outputTs `
        $outputM3U8

    Write-Host "Готово: $relativePath"
}
