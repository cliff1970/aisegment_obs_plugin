# Removes the wx_seg_obs (AI_remove_bg) plugin installed by install.ps1.
$ErrorActionPreference = 'Stop'
$dest = Join-Path $env:ProgramData 'obs-studio\plugins\wx_seg_obs'
if (Get-Process obs64 -ErrorAction SilentlyContinue) { Write-Host "ERROR: Close OBS Studio first." -ForegroundColor Red; exit 1 }
if (Test-Path $dest) { Remove-Item $dest -Recurse -Force; Write-Host "Removed $dest" -ForegroundColor Green }
else { Write-Host "Nothing to remove: $dest does not exist." }
Write-Host "Your scene files are untouched; filters using AI_remove_bg will show as missing until reinstalled."
