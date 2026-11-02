# Installing the OBS plugin

## OBS Studio 33 or newer (recommended)

OBS 33 uses a new plugin layout (`%ProgramData%\obs-studio\plugins\wx_seg_obs\`). Plugins installed under `C:\Program Files\obs-studio\` are flagged **Legacy** in OBS 33 and will not be loaded from OBS 34.

Follow **[INSTALL.md](INSTALL.md)**: section 1 installs a pre-built package on any Windows x64 PC with no developer tools, and sections 2-4 explain how to build that package from source.

## Older method (OBS 32 and earlier, or as a fallback)

> This is the original method. It installs into `C:\Program Files\obs-studio`, which is the legacy location, and `AI_remove_bg.zip` is an older build that does not contain the fixes in this branch (black frame at start-up, per-instance state).

First, download the zip file: [AI_remove_bg](AI_remove_bg.zip)  
Then unzip the AI_remove_bg.zip file in the OBS directory (needs an elevated PowerShell),  
e.g. `C:\Program Files\obs-studio`, for example: `Expand-Archive .\AI_remove_bg.zip -DestinationPath 'C:\Program Files\obs-studio' -Force`

Do not keep both the old and the new install: they use the same module name (`wx_seg_obs`). See INSTALL.md section 1.4 for how to disable the old copy.
