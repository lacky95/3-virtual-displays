# Stop all Parsec VDA helper processes and remove all virtual displays
# Run this to completely clean up all monitors

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Not running as Administrator. Restarting with elevated privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = 'Continue'

Write-Host "Stopping all Parsec VDA processes..." -ForegroundColor Yellow

# Get all process IDs first
$processes = Get-Process -Name "ParsecVDA - Always Connected" -ErrorAction SilentlyContinue
if ($processes) {
    Write-Host "Found $($processes.Count) process(es). Terminating..." -ForegroundColor Cyan
    
    # Method 1: Kill by PID using taskkill (most reliable)
    foreach ($proc in $processes) {
        Write-Host "  Killing PID $($proc.Id)..." -ForegroundColor Gray
        taskkill /F /PID $proc.Id 2>&1 | Out-Null
    }
    Start-Sleep -Milliseconds 800
    
    # Method 2: PowerShell Stop-Process with -Force
    $remaining = Get-Process -Name "ParsecVDA - Always Connected" -ErrorAction SilentlyContinue
    if ($remaining) {
        Write-Host "  Using Stop-Process for remaining..." -ForegroundColor Gray
        foreach ($proc in $remaining) {
            try {
                $proc.Kill()
            } catch {
                Write-Host "    Failed to kill PID $($proc.Id): $_" -ForegroundColor Red
            }
        }
        Start-Sleep -Milliseconds 500
    }
    
    # Method 3: Fallback - taskkill by image name
    Write-Host "  Final cleanup with taskkill..." -ForegroundColor Gray
    taskkill /F /IM "ParsecVDA - Always Connected.exe" 2>&1 | Out-Null
    
} else {
    Write-Host "No processes found by name." -ForegroundColor Gray
}

# Wait for processes to fully terminate
Start-Sleep -Seconds 1

# Verify all processes are stopped
$remaining = Get-Process -Name "ParsecVDA - Always Connected" -ErrorAction SilentlyContinue
if ($remaining) {
    Write-Host "`nWARNING: $($remaining.Count) process(es) still running!" -ForegroundColor Red
    $remaining | Format-Table Id, ProcessName, StartTime -AutoSize
    Write-Host "These processes may require administrator privileges to terminate." -ForegroundColor Yellow
} else {
    Write-Host "`nAll processes stopped successfully." -ForegroundColor Green
}

# Optional: Disable the device to force monitors to disconnect
Write-Host "`nDisabling Parsec VDA device..." -ForegroundColor Yellow
try {
    $result = pnputil /disable-device "ROOT\Parsec\VDA" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Device disabled successfully." -ForegroundColor Green
    } else {
        Write-Host "Device disable failed or already disabled." -ForegroundColor Gray
    }
} catch {
    Write-Host "Could not disable device: $_" -ForegroundColor Gray
}

Write-Host "`nDone. All displays should be removed." -ForegroundColor Green
