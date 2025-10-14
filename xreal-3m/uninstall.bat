@echo off
:: Uninstall XREAL Monitor + Parsec Virtual Displays
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -Uninstall
