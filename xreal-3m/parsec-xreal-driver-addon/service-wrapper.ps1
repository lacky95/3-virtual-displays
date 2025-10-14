# Service wrapper - starts monitors and keeps service alive
# When this script is killed, it cleans up all monitors

$ErrorActionPreference = 'Stop'
$exe = "C:\Program Files\ParsecVDA - Always Connected\ParsecVDA - Always Connected.exe"

# Custom display resolution (width, height, refresh rate)
# Based on ratio 1295x1087 (1.191352345906164) scaled to 1920 width
# Height = 1920 / 1.191352345906164 = 1612
$customWidth = 1920
$customHeight = 1612
$customHz = 60

# Cleanup function
function Stop-AllMonitors {
    try {
        $procs = Get-Process -Name "ParsecVDA - Always Connected" -ErrorAction SilentlyContinue
        foreach ($p in $procs) {
            taskkill /F /PID $p.Id 2>&1 | Out-Null
        }
        Start-Sleep -Milliseconds 500
        taskkill /F /IM "ParsecVDA - Always Connected.exe" 2>&1 | Out-Null
        Start-Sleep -Seconds 1
        pnputil /disable-device "ROOT\Parsec\VDA" 2>&1 | Out-Null
    } catch {}
}

# Register cleanup on exit (multiple methods for reliability)
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Stop-AllMonitors
}

# Also register for Ctrl+C
[Console]::TreatControlCAsInput = $false
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -SupportEvent -Action {
    Stop-AllMonitors
}

# Clean up any stale helpers from earlier runs
try { 
    Stop-Process -Name "ParsecVDA - Always Connected" -Force -ErrorAction SilentlyContinue
} catch {}

# Disable device first to ensure clean state
try { 
    pnputil /disable-device "ROOT\Parsec\VDA" 2>&1 | Out-Null
    Start-Sleep -Seconds 1
} catch {}

# Set custom resolution in registry BEFORE enabling device
try {
    $regPath = "HKLM:\SOFTWARE\Parsec\vdd\0"
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    # Set custom resolution as separate DWORD values
    Set-ItemProperty -Path $regPath -Name "width" -Value $customWidth -Type DWord
    Set-ItemProperty -Path $regPath -Name "height" -Value $customHeight -Type DWord
    Set-ItemProperty -Path $regPath -Name "hz" -Value $customHz -Type DWord
} catch {
    Write-Warning "Failed to set custom resolution in registry: $_"
}

# Now enable device - it will read the registry values
try { 
    pnputil /enable-device "ROOT\Parsec\VDA" 2>&1 | Out-Null
    Start-Sleep -Seconds 1
} catch {}

if (-not (Test-Path -LiteralPath $exe)) {
    throw "Helper EXE not found: $exe"
}

# Launch exactly three instances
1..3 | ForEach-Object {
    Start-Process -FilePath $exe -WorkingDirectory "C:\Program Files\ParsecVDA - Always Connected" -WindowStyle Hidden
    Start-Sleep -Milliseconds 800
}

# Give monitors time to initialize
Start-Sleep -Seconds 2

# Verify at least 3 instances are running
$running = @(Get-Process -Name "ParsecVDA - Always Connected" -ErrorAction SilentlyContinue)
if ($running.Count -lt 3) {
    throw "Failed to start 3 monitors. Only $($running.Count) running."
}

# Wait before starting OBS
Start-Sleep -Seconds 2

# Start OBS Studio
$obsShortcut = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\OBS Studio\OBS Studio (64bit).lnk"
if (Test-Path $obsShortcut) {
    try {
        # Launch via shortcut which has correct working directory configured
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($obsShortcut)
        Start-Process -FilePath $shortcut.TargetPath -WorkingDirectory $shortcut.WorkingDirectory
        Start-Sleep -Seconds 2
    } catch {
        # OBS failed to start, but continue anyway
    }
}

# Keep service alive - when this is killed, cleanup will run
try {
    while ($true) {
        Start-Sleep -Seconds 10
    }
} finally {
    # Final cleanup when script exits
    Stop-AllMonitors
}
