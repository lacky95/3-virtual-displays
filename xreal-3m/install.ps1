# Install XREAL Monitor + Parsec Virtual Displays
# Both as scheduled tasks (100% Windows native)

param([switch]$Uninstall)

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($Uninstall) { $arguments += " -Uninstall" }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments -Wait
    Write-Host "Installation completed in elevated window." -ForegroundColor Green
    pause
    exit
}

$xrealMonitorScript = Join-Path $PSScriptRoot "xreal-monitor\XrealMonitor.ps1"
$parsecScript = Join-Path $PSScriptRoot "parsec-xreal-driver-addon\service-wrapper.ps1"

# === UNINSTALL ===
if ($Uninstall) {
    Write-Host "=== Uninstalling XREAL Services ===" -ForegroundColor Yellow
    Write-Host ""
    
    # Stop and remove XrealMonitor task
    Write-Host "Removing XrealMonitor task..." -ForegroundColor Yellow
    Stop-ScheduledTask -TaskName "XrealMonitor" -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName "XrealMonitor" -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "XrealMonitor removed" -ForegroundColor Green
    
    # Stop and remove ParsecVDAAC task
    Write-Host "Removing ParsecVDAAC task..." -ForegroundColor Yellow
    Stop-ScheduledTask -TaskName "ParsecVDAAC" -ErrorAction SilentlyContinue
    
    # Kill processes
    Get-WmiObject Win32_Process | Where-Object { $_.CommandLine -like "*service-wrapper.ps1*" } | ForEach-Object {
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }
    
    Unregister-ScheduledTask -TaskName "ParsecVDAAC" -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "ParsecVDAAC removed" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Uninstall complete!" -ForegroundColor Green
    pause
    exit 0
}

# === INSTALL ===
Write-Host "=== Installing XREAL Monitor + Parsec Virtual Displays ===" -ForegroundColor Cyan
Write-Host ""

# STEP 1: Install ParsecVDAAC (manual trigger only)
Write-Host "Step 1: Installing ParsecVDAAC task..." -ForegroundColor Cyan

Unregister-ScheduledTask -TaskName "ParsecVDAAC" -Confirm:$false -ErrorAction SilentlyContinue

$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$parsecScript`""

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit 0
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

try {
    $result = Register-ScheduledTask -TaskName "ParsecVDAAC" `
        -Action $action `
        -Settings $settings `
        -Principal $principal `
        -Description "Starts exactly 3 Parsec virtual displays (Manual start only)" `
        -Force -ErrorAction Stop
    Write-Host "ParsecVDAAC task created (Manual trigger)" -ForegroundColor Green
    Write-Host "Task State: $($result.State)" -ForegroundColor Gray
} catch {
    Write-Host "Failed to create ParsecVDAAC task!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Script path: $parsecScript" -ForegroundColor Yellow
}

# STEP 2: Install XrealMonitor (runs at logon)
Write-Host ""
Write-Host "Step 2: Installing XrealMonitor task..." -ForegroundColor Cyan

Unregister-ScheduledTask -TaskName "XrealMonitor" -Confirm:$false -ErrorAction SilentlyContinue

$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$xrealMonitorScript`""

$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

try {
    Register-ScheduledTask -TaskName "XrealMonitor" `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Description "Monitors XREAL device and controls Parsec virtual displays" `
        -Force | Out-Null
    
    Write-Host "XrealMonitor task created (Runs at logon)" -ForegroundColor Green
    
    # Start it now
    Write-Host "Starting XrealMonitor..." -ForegroundColor Cyan
    Start-ScheduledTask -TaskName "XrealMonitor"
    Write-Host "XrealMonitor started!" -ForegroundColor Green
    
} catch {
    Write-Host "Failed to create XrealMonitor task: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Installation Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Installed:" -ForegroundColor White
Write-Host "  1. XrealMonitor - Monitors XREAL device (Auto-start at logon)" -ForegroundColor White
Write-Host "  2. ParsecVDAAC - 3 virtual displays (Manual, controlled by XrealMonitor)" -ForegroundColor White
Write-Host ""
Write-Host "How it works:" -ForegroundColor Cyan
Write-Host "  - XrealMonitor runs in background" -ForegroundColor Gray
Write-Host "  - When XREAL connects: Shows Yes/No dialog" -ForegroundColor Gray
Write-Host "  - Click Yes: Starts ParsecVDAAC (3 virtual displays)" -ForegroundColor Gray
Write-Host "  - When XREAL disconnects: Stops ParsecVDAAC" -ForegroundColor Gray
Write-Host ""
Write-Host "To uninstall:" -ForegroundColor Cyan
Write-Host "  .\uninstall.bat" -ForegroundColor Gray
Write-Host ""

pause
