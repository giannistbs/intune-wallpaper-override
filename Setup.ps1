# Setup.ps1
# Run this once to install WallpaperFix on a machine.
# It copies the script to AppData and registers a scheduled task
# that runs it automatically at every login.

$scriptName  = "WallpaperFix.ps1"
$installDir  = "$env:LOCALAPPDATA\WallpaperFix"
$installPath = "$installDir\$scriptName"
$taskName    = "WallpaperFix"
$sourceScript = "$PSScriptRoot\$scriptName"

# --- 1. Verify the wallpaper image exists ---
$wallpaperPath = "C:\Windows\Web\Wallpaper\ThemeA\img23.jpg"
if (-not (Test-Path $wallpaperPath)) {
    Write-Host "ERROR: Wallpaper image not found at: $wallpaperPath"
    Write-Host "Update the `$imagePath variable in $scriptName to point to your preferred image."
    exit 1
}

# --- 2. Copy script to AppData ---
New-Item -ItemType Directory -Path $installDir -Force | Out-Null
Copy-Item -Path $sourceScript -Destination $installPath -Force
Write-Host "Installed script to: $installPath"

# --- 3. Register scheduled task (runs at logon, 60s delay) ---
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$installPath`""

$trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"

$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 5) `
    -MultipleInstances IgnoreNew `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries

Register-ScheduledTask `
    -TaskName    $taskName `
    -Action      $action `
    -Trigger     $trigger `
    -Settings    $settings `
    -Description "Restores preferred wallpaper after Intune policy applies at logon." | Out-Null

Write-Host "Scheduled task '$taskName' registered."
Write-Host ""
Write-Host "Setup complete. The wallpaper will be applied automatically on next login."
Write-Host "To apply it right now, run: powershell -ExecutionPolicy Bypass -File `"$installPath`""
