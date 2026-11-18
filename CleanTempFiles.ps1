# 1. Setup - Identify script location for the log
$scriptFolder = $PSScriptRoot
if (-not $scriptFolder) { $scriptFolder = Get-Location } # Fallback for copy-paste into console
$logFile = Join-Path $scriptFolder "CleanTempFiles.log"

# 2. Setup - Identify the folder to clean (Current Working Directory)
$targetPath = Get-Location
$extensions = @("*.bak", "*.org", "*.tmp")

# Load the assembly for Recycle Bin support
Add-Type -AssemblyName Microsoft.VisualBasic

# 3. Find the files
$files = Get-ChildItem -Path $targetPath -Include $extensions -Recurse -File

# 4. Process the files
if ($files.Count -gt 0) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "--- Cleanup started at $timestamp ---" | Out-File $logFile -Append
    "Target Directory: $targetPath" | Out-File $logFile -Append
    
    foreach ($file in $files) {
        try {
            # Log the full path before deleting
            "RECYCLED: $($file.FullName)" | Out-File $logFile -Append
            
            # Move to Recycle Bin
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
                $file.FullName, 
                'OnlyErrorDialogs', 
                'SendToRecycleBin'
            )
            Write-Host "Recycled: $($file.Name)" -ForegroundColor Cyan
        } catch {
            "ERROR: Could not process $($file.FullName) - $($_.Exception.Message)" | Out-File $logFile -Append
        }
    }
    
    "--- Cleanup Finished ---`n" | Out-File $logFile -Append
    cd
    # 5. Success Notification
    $wshell = New-Object -ComObject WScript.Shell
    $wshell.Popup("Cleanup Complete!`n$($files.Count) files moved to Recycle Bin.`nLog saved to: $logFile", 0, "Done", 64) | Out-Null
} else {
    Write-Host "No .bak, .org, or .tmp files found in $targetPath" -ForegroundColor Yellow | Out-File $logFile -Append
    $wshell = New-Object -ComObject WScript.Shell
    $wshell.Popup( "No .bak, .org, or .tmp files found in $targetPath", 0, "Done", 64) | Out-Null
}