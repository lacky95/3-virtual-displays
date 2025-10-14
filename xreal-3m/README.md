# XREAL One Pro Monitor Service

This service monitors for the "Generic Monitor (XREAL One Pro)" device and displays notifications when it's plugged in or unplugged.

## Files

- **XrealMonitor.ps1** - PowerShell script that monitors device events
- **install-service.ps1** - Easy installation script (run as Administrator)
- **test-monitor.ps1** - Test the monitor without installing as service
- **XrealMonitor.xml** - Service configuration for NSSM (alternative method)
- **XrealMonitor.log** - Log file (created automatically)

## Features

- Detects when "Generic Monitor (XREAL One Pro)" is connected
- Detects when "Generic Monitor (XREAL One Pro)" is disconnected
- Shows popup message boxes for each event
- Logs all events to XrealMonitor.log

## Quick Start

### Option 1: Install as Windows Service (Recommended)

1. **Right-click PowerShell** and select **"Run as Administrator"**
2. Navigate to this folder:
   ```powershell
   cd "C:\Users\z194812\Documents\Local Scripts\Parsec Monitor Driver\xreal-3m"
   ```
3. Run the installation script:
   ```powershell
   .\install-service.ps1
   ```

The service will start automatically and run in the background!

### Option 2: Test Without Installing

Just double-click **test-monitor.ps1** or run:
```powershell
.\test-monitor.ps1
```

Press Ctrl+C to stop.

## Managing the Service

After installation, you can control the service with these commands (run as Administrator):

```powershell
# Check service status
Get-Service XrealMonitor

# Stop the service
Stop-Service XrealMonitor

# Start the service
Start-Service XrealMonitor

# Restart the service
Restart-Service XrealMonitor

# Uninstall the service
.\install-service.ps1 -Uninstall
```

## Viewing Logs

Check the log file to see all device events:
```powershell
Get-Content .\XrealMonitor.log -Tail 20
```

Or just open `XrealMonitor.log` in any text editor.

## Troubleshooting

**Message boxes not appearing?**
- Windows services run in "Session 0" and may not show interactive popups
- Check the log file to verify the device is being detected
- For guaranteed popups, use the test script instead, or install with NSSM (see below)

**Device not detected?**
- Verify the exact device name in Device Manager
- The script looks for exactly: "Generic Monitor (XREAL One Pro)"

## Alternative Installation (using NSSM)

For better interactive support with message boxes:

1. Download NSSM from https://nssm.cc/
2. Extract nssm.exe to this folder
3. Run as Administrator:
   ```powershell
   .\nssm.exe install XrealMonitor
   ```
4. In the NSSM GUI:
   - **Path:** `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`
   - **Startup directory:** `C:\Users\z194812\Documents\Local Scripts\Parsec Monitor Driver\xreal-3m`
   - **Arguments:** `-ExecutionPolicy Bypass -NoProfile -File "XrealMonitor.ps1"`
   - **Process tab:** Check "Interact with desktop"
5. Click "Install service"
6. Start it: `nssm start XrealMonitor`

## Notes

- The service checks for device changes every 3 seconds
- All events are logged to XrealMonitor.log
- The service starts automatically on system boot
