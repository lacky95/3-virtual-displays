Set shell = CreateObject("WScript.Shell")
' Path to your PowerShell script — change if needed
scriptPath = "C:\Users\z194812\Documents\Local Scripts\Parsec Monitor Driver\ParsecDriverControl.ps1"

' Build PowerShell command
cmd = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & scriptPath & """"

' Run hidden (0 = hidden window, False = don’t wait)
shell.Run cmd, 0, False
