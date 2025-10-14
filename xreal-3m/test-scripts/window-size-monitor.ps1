# Window Size Monitor
# Shows a window with live display of its outer dimensions

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Window Size Monitor"
$form.Size = New-Object System.Drawing.Size(400, 300)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable

# Create label to display size
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 10)
$label.Size = New-Object System.Drawing.Size(380, 280)
$label.Font = New-Object System.Drawing.Font("Consolas", 16, [System.Drawing.FontStyle]::Bold)
$label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$label.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right

# Function to update label with current size
function Update-SizeLabel {
    $width = $form.Width
    $height = $form.Height
    $label.Text = "Window Size:`n`nWidth: $width px`nHeight: $height px`n`n($width x $height)"
}

# Update label on resize
$form.Add_Resize({
    Update-SizeLabel
})

# Initial update
Update-SizeLabel

# Add label to form
$form.Controls.Add($label)

# Show the form
[void]$form.ShowDialog()
