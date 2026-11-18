# 1. Configuration (Set this to match your mail server)
$SmtpServer = "smtp.cyberrock.net"
$SmtpPort   = 465

try {
    Write-Host "Connecting to $SmtpServer on port $SmtpPort..." -ForegroundColor Cyan
    $TcpClient = New-Object System.Net.Sockets.TcpClient($SmtpServer, $SmtpPort)
    $Stream    = $TcpClient.GetStream()
    $Reader    = New-Object System.IO.StreamReader($Stream)
    $Writer    = New-Object System.IO.StreamWriter($Stream)
    $Writer.AutoFlush = $true

    # 1. Read Server Greeting
    $Line = $Reader.ReadLine(); Write-Host "Server: $Line" -ForegroundColor Gray

    # 2. Send EHLO
    $Writer.WriteLine("EHLO localhost")
    while ($true) {
        $Line = $Reader.ReadLine(); Write-Host "Server: $Line" -ForegroundColor Gray
        if ($Line -match "^\d{3}\s") { break } # End of multiline response
    }

    # 3. Send STARTTLS Command
    $Writer.WriteLine("STARTTLS")
    $Line = $Reader.ReadLine(); Write-Host "Server: $Line" -ForegroundColor Gray
    if ($Line -notmatch "^220") {
        throw "Server did not accept STARTTLS command."
    }

    # 4. NOW upgrade the stream to SSL/TLS safely
    Write-Host "`nNegotiating TLS handshake..." -ForegroundColor Cyan
    $SslStream = New-Object System.Net.Security.SslStream($Stream, $false, { $true })
    $SslStream.AuthenticateAsClient($SmtpServer)
    
    # Extract and show the certificate info
    $Cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]$SslStream.RemoteCertificate
    Write-Host "`n--- SERVER CERTIFICATE DETAILS ---" -ForegroundColor Green
    Write-Host "Issued To (Subject):   $($Cert.Subject)"
    Write-Host "Issued By (Issuer):    $($Cert.Issuer)"
    Write-Host "Valid Until:           $($Cert.NotAfter)"
    
    Write-Host "`nValid Alternative Hostnames (SAN):" -ForegroundColor Yellow
    $SanExtension = $Cert.Extensions | Where-Object { $_.Oid.Value -eq "2.5.29.17" } # SAN OID
    if ($SanExtension) { $SanExtension.Format($true) } else { Write-Host " No Alternative names found." }

} 
catch {
    Write-Error "Failed to pull certificate. Details: $_"
}
finally {
    if ($SslStream) { $SslStream.Close() }
    if ($TcpClient) { $TcpClient.Close() }
}