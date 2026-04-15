# WallpaperFix.ps1
# Overrides the Intune/org-enforced wallpaper with a preferred image.
# Runs at logon via Task Scheduler; delay ensures Intune finishes first.

$imagePath    = "C:\Windows\Web\Wallpaper\ThemeA\img23.jpg"
$twPath       = "$env:APPDATA\Microsoft\Windows\Themes\TranscodedWallpaper"
$delaySeconds = 60

Start-Sleep -Seconds $delaySeconds

if (-not (Test-Path $imagePath)) { exit 1 }

# 1. Overwrite the TranscodedWallpaper cache (what Windows actually renders)
Copy-Item -Path $imagePath -Destination $twPath -Force

# 2. Set HKCU registry so Windows knows the source path
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value $imagePath -ErrorAction SilentlyContinue

# 3. Call Win32 API to signal the change
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
[Wallpaper]::SystemParametersInfo(0x0014, 0, $imagePath, 0x01 -bor 0x02) | Out-Null

# 4. Restart Explorer to force it to re-read the wallpaper
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Process explorer
