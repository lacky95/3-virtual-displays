# Stop all Parsec VDA helper processes
# This can be called to cleanly stop the ParsecVDAAC task

$ErrorActionPreference = 'Continue'

Write-Host "Stopping ParsecVDAAC task..." -ForegroundColor Yellow

# Stop the scheduled task first
Stop-ScheduledTask -TaskName "ParsecVDAAC" -ErrorAction SilentlyContinue

# Kill the service-wrapper.ps1 process
Get-WmiObject Win32_Process | Where-Object { $_.CommandLine -like "*service-wrapper.ps1*" } | ForEach-Object {
    Write-Host "Killing wrapper process $($_.ProcessId)..." -ForegroundColor Yellow
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
}

Start-Sleep -Milliseconds 500

# Get all Parsec VDA processes
$processes = Get-Process -Name "ParsecVDA - Always Connected" -ErrorAction SilentlyContinue
if ($processes) {
    Write-Host "Killing $($processes.Count) Parsec VDA processes..." -ForegroundColor Yellow
    
    # Method 1: Kill by PID using taskkill (most reliable)
    foreach ($proc in $processes) {
        taskkill /F /PID $proc.Id 2>&1 | Out-Null
    }
    Start-Sleep -Milliseconds 800
    
    # Method 2: PowerShell Stop-Process with -Force
    $remaining = Get-Process -Name "ParsecVDA - Always Connected" -ErrorAction SilentlyContinue
    if ($remaining) {
        foreach ($proc in $remaining) {
            try {
                $proc.Kill()
            } catch {}
        }
        Start-Sleep -Milliseconds 500
    }
    
    # Method 3: Fallback - taskkill by image name
    taskkill /F /IM "ParsecVDA - Always Connected.exe" 2>&1 | Out-Null
}

# Wait for processes to fully terminate
Start-Sleep -Seconds 1

# Optional: Disable the device to force monitors to disconnect
try {
    pnputil /disable-device "ROOT\Parsec\VDA" 2>&1 | Out-Null
} catch {}

Write-Host "ParsecVDAAC stopped!" -ForegroundColor Green

exit 0
