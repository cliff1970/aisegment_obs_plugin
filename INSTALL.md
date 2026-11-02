# AI_remove_bg (wx_seg_obs) for OBS Studio 33 - Build & Install Guide

Real-time background removal/replacement filter for OBS Studio on Windows 11 x64.
Verified on OBS 33.0.1, Visual Studio 2022 Build Tools (MSVC 14.44), CMake, OpenCV 4.5.4.

---

## 1. Install on a computer with no developer tools (pre-built package)

This is the path for any ordinary Windows PC. **Nothing needs to be compiled**, and no Visual Studio, CMake, OBS SDK or OpenCV download is needed on the target machine.

### 1.1 What the target PC needs

| Requirement | Details | How to check / get it |
|---|---|---|
| Windows | Windows 11 **64-bit** (x64) - tested. Windows 10 x64 should work (OBS 33 supports it) but is untested. 32-bit Windows and ARM are not supported. | Settings -> System -> About -> "System type" |
| OBS Studio | **Version 33 or newer, 64-bit**, installed normally (not a portable copy; for portable see 1.5). | In OBS: Help -> About. Download from obsproject.com. |
| Visual C++ runtime | *Microsoft Visual C++ 2015-2022 Redistributable (x64)*. OBS installs it, so you normally already have it. | `winget install Microsoft.VCRedist.2015+.x64` |
| Camera / video source | Any OBS video source (webcam, DroidCam, capture card). | - |
| Disk space | About 100 MB. | - |
| Administrator rights | Not required for the install itself. Only needed to disable an *older* copy of this plugin in `C:\Program Files\obs-studio\` (see 1.4). | - |
| Internet | Not needed once you have the package. The plugin runs fully offline. | - |

No GPU is required: the project README states it runs at about 25 FPS on an ordinary computer (the vendor's claim; not measured here).

### 1.2 Get the package
You need the **`dist` folder** (or a zip of it) made by `installer\package.ps1` (section 4). It contains `Install.bat`, `Uninstall.bat`, two `.ps1` scripts, this guide, and a `payload\` folder with the plugin and its three required DLLs plus `data\`. Copy it to the target PC with a USB drive, network share or a GitHub Release download.

If it came as a zip: right-click the zip -> Properties -> tick **Unblock** -> OK *before* extracting (or run `Unblock-File` on the files). Then extract it to a normal folder such as `C:\Temp\wx_seg_obs_dist`. Do not run it from inside the zip.

### 1.3 Install (automatic)
1. **Close OBS completely** (check the system tray and Task Manager for `obs64.exe`).
2. Double-click **`Install.bat`**. If Windows SmartScreen says "Windows protected your PC", click *More info* -> *Run anyway* (the scripts are unsigned and are plain text you can read).
3. The window lists the installed files and says `Installed to: C:\ProgramData\obs-studio\plugins\wx_seg_obs`.
4. Start OBS -> right-click a video source -> **Filters** -> **+** -> **AI_remove_bg**.

To remove: close OBS and double-click **`Uninstall.bat`**.

### 1.4 If an older copy of this plugin is already installed
An older install in `C:\Program Files\obs-studio\obs-plugins\64bit\` has the same module name and conflicts with the new one. Right-click `Install.bat` -> **Run as administrator** and it renames the old DLLs to `.old` for you (reversible). To do it by hand, in an elevated PowerShell with OBS closed:
```powershell
Rename-Item "C:\Program Files\obs-studio\obs-plugins\64bit\wx_seg_obs.dll"   wx_seg_obs.dll.old
Rename-Item "C:\Program Files\obs-studio\obs-plugins\64bit\wx_video_seg.dll" wx_video_seg.dll.old
```

### 1.5 Manual install (no scripts) and portable OBS
Copy the contents of `payload\` into `C:\ProgramData\obs-studio\plugins\wx_seg_obs\` so the DLLs sit directly in that folder, next to `data\`:
```
wx_seg_obs.dll, wx_video_seg.dll, opencv_world454.dll, data\
```
For a **portable** OBS, OBS ignores ProgramData; use a `plugins\wx_seg_obs\` folder in the OBS install root instead (OBS 33 flags the older `obs-plugins` folder as Legacy).

### 1.6 Check that it worked
See section 5. In short: the OBS log shows `[wx_seg_obs] plugin loaded successfully`, and Plugin Manager lists it without a Legacy label.

### What gets installed

```
C:\ProgramData\obs-studio\plugins\wx_seg_obs\
    wx_seg_obs.dll          the plugin
    wx_video_seg.dll        vendor segmentation engine (required at load time)
    opencv_world454.dll     OpenCV 4.5.4 runtime (required at load time)
    data\
        obs.lic             license file (required)
        bkg.jpg             default background picture
        locale\en-US.ini, zh-CN.ini
```

This is OBS 33's current plugin layout: the DLL sits **directly** in the plugin folder. Putting it in a `bin\64bit\` subfolder makes OBS flag the plugin as **Legacy**.

---

## 2. Build from source (developers only - not needed to install)

Do this on a build machine, then ship the package from section 4 to other PCs.

### Prerequisites
| Item | Notes |
|---|---|
| Visual Studio 2022 (or Build Tools) | "Desktop development with C++" workload, x64 |
| CMake 3.20+ | on `PATH` |
| OBS SDK at `C:\obs-sdk` | `include\` (with `libobs\` and `obsconfig.h` for 33.0.0) and `lib\libobs.lib` |
| OpenCV 4.5.4 | see below - **not stored in git** |

### OpenCV 4.5.4 (required, not in the repo)
`opencv_world454.lib` was never committed. Get the official prebuilt:

1. Download `opencv-4.5.4-vc14_vc15.exe` from the OpenCV 4.5.4 release on GitHub (about 218 MB) and extract it.
2. Copy into the repo:
   - `build\x64\vc15\lib\opencv_world454.lib` -> `3rd\opencv\x64\vc15\lib\`
   - `build\x64\vc15\bin\opencv_world454.dll` -> `3rd\opencv\x64\vc15\bin\`

Do **not** use other versions (for example the 4.0.1 DLLs that ship with some apps): the bundled headers are 4.5.4.

### Configure and build
```powershell
cd <repo>
Remove-Item build -Recurse -Force -ErrorAction SilentlyContinue
cmake -S . -B build -G "Visual Studio 17 2022" -A x64
cmake --build build --config Release
```
Output: `build\Release\wx_seg_obs.dll`.

Notes on `CMakeLists.txt`:
- C++20 is required (`src/wxsegobs.cpp` uses designated initializers).
- Uses the DLL runtime (`/MD`) to match OBS.
- `-DOPENCV_STATIC=ON` links the static OpenCV libs in `3rd\opencv\x64\vc16\staticlib\` instead, but only works if you have built a static `opencv_world454.lib` yourself.

---

## 3. Manual install (without the installer)

```powershell
$p = "$env:ProgramData\obs-studio\plugins\wx_seg_obs"
New-Item -ItemType Directory -Force $p | Out-Null
Copy-Item build\Release\wx_seg_obs.dll $p
Copy-Item 3rd\lh320_windows_1.2.2\bin\x64\wx_video_seg.dll $p
Copy-Item 3rd\opencv\x64\vc15\bin\opencv_world454.dll $p
Copy-Item data $p -Recurse -Force
```

---

## 4. Create the installer package

After a successful build:
```powershell
powershell -ExecutionPolicy Bypass -File installer\package.ps1
```
This creates `dist\` (about 100 MB) containing `Install.bat`, `Uninstall.bat`, the scripts, this guide, and `payload\`. Zip `dist\` and copy it to any Windows x64 machine with OBS 33 (then follow section 1). To share it publicly, attach the zip to a GitHub **Release** rather than committing it: it is about 100 MB and would bloat the repository.

The installer uses only built-in PowerShell. If you later want a classic `Setup.exe`, the same `payload\` folder can be wrapped with Inno Setup.

---

## 5. Verify it works

1. Start OBS and open **Help -> Log Files -> View Current Log**.
2. Look for:
   - `[wx_seg_obs] plugin loaded successfully (version 0.4.0)`
   - `wx_seg_obs.dll` under *Loaded Modules*
3. **Settings -> Plugins** (Plugin Manager) should list it **without** a Legacy label.

---

## 6. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Filter missing, log has `Failed to load ... wx_seg_obs.dll` | A dependency DLL is missing. `wx_video_seg.dll` and `opencv_world454.dll` must be in the **same folder** as `wx_seg_obs.dll`. Install the *VC++ 2015-2022 x64 Redistributable* if needed (OBS normally already has it). |
| Plugin Manager shows **Legacy** | The DLL is in `...\bin\64bit\` or in `C:\Program Files\obs-studio\obs-plugins\64bit\`. Use the layout in section 1. OBS stops loading Program Files plugins in OBS 34. |
| Duplicate / wrong version loads | An old copy exists in `C:\Program Files\obs-studio\obs-plugins\64bit\`. In an **elevated** PowerShell, with OBS closed: `Rename-Item "C:\Program Files\obs-studio\obs-plugins\64bit\wx_seg_obs.dll" wx_seg_obs.dll.old` (same for `wx_video_seg.dll`). The installer does this automatically when run as administrator. |
| Black video on OBS start | Fixed in this build (the picture/colour background used a stale zero height). If it returns, you are running an older DLL - reinstall. |
| Filter does not appear / license error | `data\obs.lic` must be present in the plugin's `data\` folder. |
| LNK1181 `opencv_world454.lib` | The OpenCV library is not in `3rd\opencv\x64\vc15\lib\` - see section 2. |
| C7555 designated initializers | Needs `/std:c++20` - already set in `CMakeLists.txt`. |
| Installer says OBS is running | Close OBS fully (including the tray icon), then retry. |

### Known limitations
- Each filter instance now owns its own segmentation handle and image buffers, and re-allocates them if the source resolution changes. (Earlier builds shared this state globally, which could glitch with several cameras at different resolutions.)
- The build host does not need OBS installed, but needs the OBS SDK at `C:\obs-sdk` (change with `-DOBS_SDK_DIR=...`).

---

## 7. Files not to commit
`3rd\opencv\x64\vc15\` (60 MB DLL), `build\` and `dist\` are build artifacts; they are listed in `.gitignore`.
