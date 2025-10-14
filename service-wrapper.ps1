# Service wrapper - starts monitors and keeps service alive
# When this script is killed, it cleans up all monitors

$ErrorActionPreference = 'Stop'
$exe = Join-Path $PSScriptRoot 'ParsecVDA - Always Connected.exe'

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

# Register cleanup on exit
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Stop-AllMonitors
}

# Clean up any stale helpers from earlier runs
try { 
    Stop-Process -Name "ParsecVDA - Always Connected" -Force -ErrorAction SilentlyContinue
} catch {}

# Ensure device is enabled
try { 
    pnputil /enable-device "ROOT\Parsec\VDA" 2>&1 | Out-Null 
} catch {}

if (-not (Test-Path -LiteralPath $exe)) {
    throw "Helper EXE not found: $exe"
}

# Launch exactly three instances
1..3 | ForEach-Object {
    Start-Process -FilePath $exe -WorkingDirectory $PSScriptRoot -WindowStyle Hidden
    Start-Sleep -Milliseconds 800
}

# Give monitors time to initialize
Start-Sleep -Seconds 2

# Verify at least 3 instances are running
$running = @(Get-Process -Name "ParsecVDA - Always Connected" -ErrorAction SilentlyContinue)
if ($running.Count -lt 3) {
    throw "Failed to start 3 monitors. Only $($running.Count) running."
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
