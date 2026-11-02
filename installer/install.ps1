# Installs the wx_seg_obs (AI_remove_bg) plugin for OBS Studio 33+ using the modern layout:
#   %ProgramData%\obs-studio\plugins\wx_seg_obs\{*.dll, data\}
# Run via Install.bat (double-click) or: powershell -ExecutionPolicy Bypass -File install.ps1
$ErrorActionPreference = 'Stop'
$src  = Join-Path $PSScriptRoot 'payload'
$dest = Join-Path $env:ProgramData 'obs-studio\plugins\wx_seg_obs'

function Fail($m) { Write-Host "ERROR: $m" -ForegroundColor Red; exit 1 }

if (-not (Test-Path (Join-Path $src 'wx_seg_obs.dll'))) { Fail "payload\wx_seg_obs.dll not found next to this script." }
foreach ($f in 'wx_video_seg.dll','opencv_world454.dll','data\obs.lic') {
    if (-not (Test-Path (Join-Path $src $f))) { Fail "payload\$f is missing - package is incomplete." }
}
if (Get-Process obs64 -ErrorAction SilentlyContinue) { Fail "OBS Studio is running. Close it completely, then run the installer again." }

# 1. Disable any legacy copy in Program Files (it has the same module name and would conflict).
$legacyDir = Join-Path ${env:ProgramFiles} 'obs-studio\obs-plugins\64bit'
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
foreach ($n in 'wx_seg_obs.dll','wx_video_seg.dll') {
    $old = Join-Path $legacyDir $n
    if (Test-Path $old) {
        if ($isAdmin) {
            Rename-Item $old "$n.old" -Force
            Write-Host "Disabled legacy copy: $old  (renamed to $n.old)"
        } else {
            Write-Host "WARNING: legacy copy found at $old" -ForegroundColor Yellow
            Write-Host "         Re-run Install.bat as Administrator (right-click > Run as administrator) to disable it automatically." -ForegroundColor Yellow
        }
    }
}

# 2. Install the new layout.
New-Item -ItemType Directory -Force $dest | Out-Null
Copy-Item (Join-Path $src '*') $dest -Recurse -Force
# Remove the old bin\64bit layout from earlier manual installs (flagged "Legacy" by OBS 33).
$oldBin = Join-Path $dest 'bin'
if (Test-Path $oldBin) { Remove-Item $oldBin -Recurse -Force }

Write-Host ""
$ver = (Get-Item (Join-Path $dest 'wx_seg_obs.dll')).VersionInfo.FileVersion
Write-Host "Installed wx_seg_obs version $ver to: $dest" -ForegroundColor Green
Get-ChildItem $dest -Recurse -File | ForEach-Object { "  " + $_.FullName.Substring($dest.Length + 1) }
Write-Host ""
Write-Host "Start OBS, then right-click a video source > Filters > + > AI_remove_bg."
