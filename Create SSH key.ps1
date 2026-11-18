param (
    [Parameter(Mandatory=$true, HelpMessage="Please enter name for this key (i.e. the 'therock' part of id_ed25519_therock.")]
    [string]$id
)

ssh-keygen -t ed25519 -C "therock@cyberrock.net" -f "$HOME\.ssh\id_ed25519_$id"

Get-Content "$HOME\.ssh\id_ed25519_$id.pub" | Set-Clipboard


# Paste on GitHub
Write-Host "Public key copied to clipboard."
Write-Host -NoNewLine "Once you pasted it in GitHub, Bluehose, etc, press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Host "" # Moves cursor to the next line

# Define the menu options. The ampersand (&) defines the hotkey.
$options = [System.Management.Automation.Host.ChoiceDescription[]] @(
    [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Yes")
    [System.Management.Automation.Host.ChoiceDescription]::new("&No", "No")
)

# 0 = Default to Yes, 1 = Default to No
$default = 1 

$result = $Host.UI.PromptForChoice("GitHum", "Do you want to configure this key with GitHub?", $options, $default)

if ($result -eq 0) {
    Write-Host "You selected Yes!" -ForegroundColor Green
} else {
    Write-Host "You selected No!" -ForegroundColor Red
}