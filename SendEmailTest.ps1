# 1. Define your mail configuration
$SmtpServer  = "mail.cyberrock.net"
$SmtpPort    = 465
$FromAddress = "no-reply@livelovedigitalworks.com"
$ToAddress   = "therock@cyberrock.net"

# 2. Securely prompt for your SMTP Username and Password
Write-Host "Please enter your SMTP credentials below." -ForegroundColor Cyan
$Credentials = Get-Credential -UserName $FromAddress -Message "SMTP Authentication"

# 3. Load the MailKit assemblies shipped with the Send-MailKitMessage module
$ModuleBase = (Get-Module -ListAvailable Send-MailKitMessage | Sort-Object Version -Descending | Select-Object -First 1).ModuleBase
Add-Type -Path (Join-Path $ModuleBase "MimeKit.dll")
Add-Type -Path (Join-Path $ModuleBase "MailKit.dll")

# 4. Build the message
$Message = [MimeKit.MimeMessage]::new()
$Message.From.Add([MimeKit.MailboxAddress]::new("", $FromAddress))
$Message.To.Add([MimeKit.MailboxAddress]::new("", $ToAddress))
$Message.Subject = "PowerShell SMTP Test"
$Message.Body = [MimeKit.TextPart]::new("plain")
$Message.Body.Text = "This is a successful test email sent securely using PowerShell and TLS encryption."

# 5. Send using MailKit directly, with TLS still required but CRL/OCSP revocation checking disabled
try {
    $Client = [MailKit.Net.Smtp.SmtpClient]::new()
    $Client.CheckCertificateRevocation = $false

    $Client.Connect($SmtpServer, $SmtpPort, [MailKit.Security.SecureSocketOptions]::SslOnConnect)
    $Client.Authenticate($Credentials.UserName, $Credentials.GetNetworkCredential().Password)
    $Client.Send($Message)
    $Client.Disconnect($true)

    Write-Host "Success! The email has been sent to $ToAddress." -ForegroundColor Green
}
catch {
    Write-Error "Failed to send email. Error details: $_"
}
finally {
    if ($Client) { $Client.Dispose() }
}
