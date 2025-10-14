Add-Type -AssemblyName PresentationFramework

# --- Relaunch as Administrator if not already ---
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$($MyInvocation.MyCommand.Path)`""
    $psi.Verb = "runas"
    try {
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    } catch {
        [System.Windows.MessageBox]::Show("Admin permission was not granted.","Parsec Driver Control")
    }
    exit
}

# --- Hide current PowerShell window ---
$code = @'
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
'@
Add-Type $code
$hwnd = [Win32]::GetConsoleWindow()
if ($hwnd -ne [IntPtr]::Zero) {
    [Win32]::ShowWindow($hwnd, 0) # 0 = SW_HIDE
}

# --- UI XAML ---
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Parsec Driver Control" Height="200" Width="320" WindowStartupLocation="CenterScreen">
  <Grid Margin="10">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    <TextBlock Text="Parsec Driver" FontSize="18" HorizontalAlignment="Center" Margin="0,0,0,15"/>
    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Grid.Row="1">
      <Button Name="BtnOn" Content="On" Width="70" Margin="5"/>
      <Button Name="BtnOff" Content="Off" Width="70" Margin="5"/>
      <Button Name="BtnCancel" Content="Cancel" Width="70" Margin="5"/>
    </StackPanel>
    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Grid.Row="2" Margin="0,10,0,0">
      <Button Name="BtnResolution" Content="Display Settings" Width="150" Margin="5"/>
    </StackPanel>
  </Grid>
</Window>
"@

# --- Parse XAML ---
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)
$BtnOn = $window.FindName("BtnOn")
$BtnOff = $window.FindName("BtnOff")
$BtnCancel = $window.FindName("BtnCancel")
$BtnResolution = $window.FindName("BtnResolution")

# --- Actions ---
$serviceName = "ParsecVDA - Always Connected"

$BtnOn.Add_Click({
    Start-Process "net" "start `"$serviceName`"" -Verb runas
    [System.Windows.MessageBox]::Show("Service started.", "Parsec Driver")
})

$BtnOff.Add_Click({
    Start-Process "net" "stop `"$serviceName`"" -Verb runas
    [System.Windows.MessageBox]::Show("Service stopped.", "Parsec Driver")
})

$BtnResolution.Add_Click({
    Start-Process "ms-settings:display"
})

$BtnCancel.Add_Click({ $window.Close() })

# --- Run Window ---
$window.Topmost = $true
$window.ShowDialog() | Out-Null
