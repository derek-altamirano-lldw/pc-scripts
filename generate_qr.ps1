# Pre-check for the 'qr' CLI command
$qrCheck = Get-Command qr -ErrorAction SilentlyContinue

if (-not $qrCheck) {
    Write-Host "Error: 'qr' command-line tool not found." -ForegroundColor Red
    Write-Host "Please install it by running:" -ForegroundColor Yellow
    Write-Host "  pip install qrcode[pil]" -ForegroundColor Cyan
    exit 1
}

try {
    # Verify execution runs cleanly
    $null = qr --version 2>&1
} catch {
    Write-Host "Error: Failed to execute 'qr --version'." -ForegroundColor Red
    Write-Host "Please reinstall or install by running:" -ForegroundColor Yellow
    Write-Host "  pip install qrcode[pil]" -ForegroundColor Cyan
    exit 1
}

# Prompt for inputs
$url = Read-Host "Enter the URL"
$fileNameInput = Read-Host "Enter output file name or path (e.g., my_qr.svg)"

# Clean quotes if dragged/pasted into terminal
$url = $url.Trim('"').Trim("'")
$fileNameInput = $fileNameInput.Trim('"').Trim("'")

if (-not $url -or -not $fileNameInput) {
    Write-Host "URL and filename are required." -ForegroundColor Red
    exit 1
}

# Ensure .svg extension
if (-not $fileNameInput.EndsWith(".svg", [System.StringComparison]::OrdinalIgnoreCase)) {
    $fileNameInput += ".svg"
}

# Determine full path (defaulting relative paths to Downloads)
if ([System.IO.Path]::IsPathRooted($fileNameInput)) {
    $outputPath = $fileNameInput
} else {
    $downloadsFolder = Join-Path $env:USERPROFILE "Downloads"
    $outputPath = Join-Path $downloadsFolder $fileNameInput
}

# Ensure parent directory exists if a full path was provided
$parentDir = [System.IO.Path]::GetDirectoryName($outputPath)
if (-not (Test-Path $parentDir)) {
    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
}

# Run the python qr CLI tool
try {
    qr --factory=svg-path $url | Set-Content -Path $outputPath -Encoding utf8
    Write-Host "`nSuccess! SVG saved to:" -ForegroundColor Green
    Write-Host $outputPath -ForegroundColor Cyan
} catch {
    Write-Host "`nFailed to generate QR code: $_" -ForegroundColor Red
}