# Assembles dist\ (a copy-anywhere installer package) from the Release build and 3rd\ runtime DLLs.
# Usage (from repo root, after `cmake --build build --config Release`):
#   powershell -ExecutionPolicy Bypass -File installer\package.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$dist = Join-Path $root 'dist'
$pay  = Join-Path $dist 'payload'

$files = @{
    'wx_seg_obs.dll'      = Join-Path $root 'build\Release\wx_seg_obs.dll'
    'wx_video_seg.dll'    = Join-Path $root '3rd\lh320_windows_1.2.2\bin\x64\wx_video_seg.dll'
    'opencv_world454.dll' = Join-Path $root '3rd\opencv\x64\vc15\bin\opencv_world454.dll'
}
foreach ($k in $files.Keys) { if (-not (Test-Path $files[$k])) { throw "Missing $($files[$k])" } }

if (Test-Path $dist) { Remove-Item $dist -Recurse -Force }
New-Item -ItemType Directory -Force $pay | Out-Null
foreach ($k in $files.Keys) { Copy-Item $files[$k] (Join-Path $pay $k) }
Copy-Item (Join-Path $root 'data') (Join-Path $pay 'data') -Recurse
foreach ($f in 'install.ps1','uninstall.ps1','Install.bat','Uninstall.bat') { Copy-Item (Join-Path $PSScriptRoot $f) $dist }
Copy-Item (Join-Path $root 'INSTALL.md') $dist

Write-Host "Package ready: $dist" -ForegroundColor Green
Get-ChildItem $dist -Recurse -File | ForEach-Object { "{0,10:N0}  {1}" -f $_.Length, $_.FullName.Substring($dist.Length + 1) }
