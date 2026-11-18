#Requires -RunAsAdministrator
# Replaces InstallCleanTempFilesSetup.reg and Max Cached Icons.reg. Safe to re-run.

function Set-RegValue($Path, $Name, $Value) {
    if (!(Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value
}

# Folder right-click: "Clean Temp Files (.bak, .org, .tmp)"
$key = 'HKLM:\SOFTWARE\Classes\Directory\shell\CleanTempFiles'
Set-RegValue $key '(default)' 'Clean Temp Files (.bak, .org, .tmp)'
Set-RegValue $key 'Icon' 'powershell.exe'
Set-RegValue "$key\command" '(default)' 'powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\Scripts\CleanTempFiles.ps1"'

# Image right-click: "Convert to WebP" -> calls the webp function from the pwsh profile
# (installed by "Install Webp helper function.ps1", which must be run in pwsh 7, not Windows PowerShell)
foreach ($ext in '.jpg', '.jpeg', '.png') {
    $key = "HKLM:\SOFTWARE\Classes\SystemFileAssociations\$ext\Shell\ConvertToWebP"
    Set-RegValue $key '(default)' 'Convert to WebP'
    Set-RegValue "$key\command" '(default)' 'pwsh.exe -NoLogo -WindowStyle Hidden -Command "webp -Path \"%1\""'
}

# Larger icon cache (takes effect after sign-out or Repair-Taskbar)
Set-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' 'Max Cached Icons' '4096'
