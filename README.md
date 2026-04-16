# Intune Wallpaper Override

Overrides a corporate/Intune-enforced desktop wallpaper on Windows 11 with a preferred image, and keeps it applied across logins.

## The problem

Intune's `PersonalizationCSP` policy enforces a wallpaper by downloading an image from a company URL and applying it at every login.

The wallpaper Windows actually displays is stored in `TranscodedWallpaper`:

```
C:\Users\<you>\AppData\Roaming\Microsoft\Windows\Themes\TranscodedWallpaper
```

Intune overwrites this file on login, which is why the corporate wallpaper keeps coming back.

## How this works

`WallpaperFix.ps1` runs 60 seconds after login (giving Intune time to finish applying its policy), then:

1. Overwrites `TranscodedWallpaper` with the preferred image
2. Updates the `HKCU\Control Panel\Desktop` registry key to point to it
3. Calls `SystemParametersInfo` via the Win32 API to signal the change
4. Restarts Explorer so it picks up the new wallpaper immediately

The 60-second delay is the key — without it, Intune would apply its wallpaper *after* this script runs and undo the change.

## Files

| File | Purpose |
|---|---|
| `WallpaperFix.ps1` | The main script that applies the wallpaper |
| `Setup.ps1` | One-time setup: installs the script and registers the scheduled task |

## Setup

**Run this once** in a PowerShell window from the repo folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\Setup.ps1
```

This will:
- Copy `WallpaperFix.ps1` to `%LOCALAPPDATA%\WallpaperFix\`
- Register a Windows Task Scheduler task called `WallpaperFix` that runs at your login

## Changing the wallpaper image

Open `WallpaperFix.ps1` and update the path on line 1:

```powershell
$imagePath = "C:\Windows\Web\Wallpaper\ThemeA\img23.jpg"
```

Point it to any `.jpg` or `.png` on your machine, then re-run `Setup.ps1`.

## Running manually

```powershell
powershell -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\WallpaperFix\WallpaperFix.ps1"
```

Note: the script waits 60 seconds before applying. Change `$delaySeconds = 60` to `$delaySeconds = 0` in the script to skip the wait.

## Uninstall

```powershell
Unregister-ScheduledTask -TaskName "WallpaperFix" -Confirm:$false
Remove-Item "$env:LOCALAPPDATA\WallpaperFix" -Recurse -Force
```
