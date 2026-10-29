# Memasang widget Lunera ke proyek Flutter. Jalankan dari folder android_widget (di dalam proyek):
#   powershell -ExecutionPolicy Bypass -File .\install.ps1
param([string]$Project = (Resolve-Path "$PSScriptRoot\..").Path)
$ErrorActionPreference = "Stop"

$kotlinRoot = Join-Path $Project "android\app\src\main\kotlin"
$main = Get-ChildItem -Path $kotlinRoot -Recurse -Filter "MainActivity.*" | Select-Object -First 1
if (-not $main) { throw "MainActivity tidak ditemukan di $kotlinRoot. Pastikan folder android sudah dibuat (flutter create .)." }
$pkg = (Select-String -Path $main.FullName -Pattern '^\s*package\s+([\w\.]+)').Matches[0].Groups[1].Value
Write-Host "Package aplikasi: $pkg"

$utf8 = New-Object System.Text.UTF8Encoding $false
Get-ChildItem "$PSScriptRoot\kotlin\*.kt" | ForEach-Object {
    $text = (Get-Content $_.FullName -Raw) -replace 'package com\.example\.ritme', "package $pkg"
    [System.IO.File]::WriteAllText((Join-Path $main.DirectoryName $_.Name), $text, $utf8)
    Write-Host "Disalin: $($_.Name)"
}

$res = Join-Path $Project "android\app\src\main\res"
Copy-Item "$PSScriptRoot\res\*" -Destination $res -Recurse -Force
Write-Host "Sumber daya (layout, xml, drawable, values) disalin."

$manifestPath = Join-Path $Project "android\app\src\main\AndroidManifest.xml"
$manifest = Get-Content $manifestPath -Raw
if ($manifest -notmatch 'HrtWidget') {
    $snippet = Get-Content "$PSScriptRoot\AndroidManifest.snippet.xml" -Raw
    $manifest = $manifest -replace '</application>', ($snippet + "`n    </application>")
    [System.IO.File]::WriteAllText($manifestPath, $manifest, $utf8)
    Write-Host "Receiver widget ditambahkan ke AndroidManifest.xml."
} else {
    Write-Host "AndroidManifest.xml sudah berisi widget, dilewati."
}
Write-Host "Selesai. Jalankan: flutter pub get, lalu jalankan ulang aplikasi."
