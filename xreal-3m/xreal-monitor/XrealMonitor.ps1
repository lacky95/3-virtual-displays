# XREAL One Pro Device Monitor Service
# Monitors for device plug-in/plug-out events and displays notifications

$LogFile = "$PSScriptRoot\XrealMonitor.log"
$DeviceName = "XREAL One Pro"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Add-Content -Path $LogFile -Value $logMessage
    Write-Host $logMessage
}

function Show-Notification {
    param(
        [string]$Title,
        [string]$Message
    )
    
    # Use COM object popup - most reliable for background scripts
    try {
        $wshell = New-Object -ComObject Wscript.Shell
        $wshell.Popup($Message, 0, $Title, 0x0 + 0x40) | Out-Null
    }
    catch {
        Write-Log "Failed to show notification: $_"
    }
}

function Show-QuestionDialog {
    param(
        [string]$Title,
        [string]$Message
    )
    
    # Show Yes/No question dialog
    # Returns: 6 = Yes, 7 = No
    try {
        $wshell = New-Object -ComObject Wscript.Shell
        $result = $wshell.Popup($Message, 0, $Title, 0x4 + 0x20)  # 0x4 = Yes/No buttons, 0x20 = Question icon
        return $result
    }
    catch {
        Write-Log "Failed to show question dialog: $_"
        return 7  # Default to No
    }
}

function Get-XrealDevice {
    # Query for XREAL One Pro Speaker only
    $devices = Get-PnpDevice -Status OK | Where-Object { 
        $_.FriendlyName -eq "Lautsprecher (XREAL One Pro)" -or
        $_.FriendlyName -eq "Speaker (XREAL One Pro)"
    }
    return $devices
}

Write-Log "XREAL Monitor Service Starting..."

# Initial device check
$previousState = $null
$currentDevice = Get-XrealDevice

if ($currentDevice) {
    $previousState = $true
    Write-Log "Service started - XREAL One Pro is currently connected"
} else {
    $previousState = $false
    Write-Log "Service started - XREAL One Pro is not connected"
}

# Main monitoring loop
# Track each device separately to show individual notifications
$previousDevices = @()
$ParsecServiceName = "ParsecVDAAC"
$ParsecServiceRunning = $false
$userWantsService = $false

while ($true) {
    try {
        $currentDevices = @(Get-XrealDevice)
        $hasDevices = $currentDevices.Count -gt 0
        
        # Check for newly connected devices
        $newDevicesConnected = $false
        foreach ($device in $currentDevices) {
            $deviceId = $device.InstanceId
            if ($deviceId -notin $previousDevices) {
                # New device connected
                $message = "$($device.FriendlyName) has been connected!"
                Write-Log $message
                $newDevicesConnected = $true
            }
        }
        
        # Show question dialog when transitioning from no devices to devices
        if ($newDevicesConnected -and $previousDevices.Count -eq 0) {
            $response = Show-QuestionDialog -Title "XREAL Device Connected" -Message "Do you want to start XREAL - Virtual Monitors?"
            
            if ($response -eq 6) {
                # User clicked Yes
                Write-Log "User chose to start virtual monitors"
                $userWantsService = $true
            } else {
                # User clicked No
                Write-Log "User chose NOT to start virtual monitors"
                $userWantsService = $false
            }
        }
        elseif ($newDevicesConnected -and $previousDevices.Count -gt 0) {
            # Additional devices connected, don't ask again
            Write-Log "Additional XREAL device connected (not showing dialog)"
        }
        
        # Check for disconnected devices (log only, don't show notification yet)
        $deviceDisconnected = $false
        foreach ($deviceId in $previousDevices) {
            if ($deviceId -notin $currentDevices.InstanceId) {
                # Device disconnected
                Write-Log "XREAL One Pro device has been disconnected!"
                $deviceDisconnected = $true
            }
        }
        
        # Start/Stop Parsec task based on device presence and user choice
        if ($hasDevices -and -not $ParsecServiceRunning -and $userWantsService) {
            # Device connected and user wants service - start Parsec task
            try {
                $task = Get-ScheduledTask -TaskName $ParsecServiceName -ErrorAction SilentlyContinue
                if ($task -and $task.State -ne 'Running') {
                    Write-Log "Starting Parsec task..."
                    
                    # Start with admin rights
                    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command Start-ScheduledTask -TaskName $ParsecServiceName" -Wait
                    
                    $ParsecServiceRunning = $true
                    Write-Log "Parsec task started"
                }
            } catch {
                Write-Log "Failed to start Parsec task: $_"
            }
        }
        elseif (-not $hasDevices -and $ParsecServiceRunning) {
            # Device disconnected - stop Parsec task and clean up FIRST
            try {
                Write-Log "Stopping Parsec task..."
                
                # Run the stop script to properly clean up all processes
                $stopScript = Join-Path $PSScriptRoot "..\parsec-xreal-driver-addon\stop-parsec.ps1"
                Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$stopScript`"" -WindowStyle Hidden
                
                $ParsecServiceRunning = $false
                $userWantsService = $false  # Reset user choice
                Write-Log "Parsec task stopped"
            } catch {
                Write-Log "Failed to stop Parsec task: $_"
            }
            
            # NOW show the notification after cleanup is done
            if ($deviceDisconnected) {
                Show-Notification -Title "Device Disconnected" -Message "XREAL One Pro device has been disconnected!"
            }
        }
        
        # Update previous state
        $previousDevices = $currentDevices.InstanceId
        
        # Wait 3 seconds before next check
        Start-Sleep -Seconds 3
        
    } catch {
        Write-Log "Error in monitoring loop: $_"
        Start-Sleep -Seconds 5
    }
}
