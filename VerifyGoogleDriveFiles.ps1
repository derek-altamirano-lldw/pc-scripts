# 1. Locate Source Drive dynamically
$DriveFolder = "LiveLoveDrinkTravel"
Write-Host "Searching drives for source folder matching '$DriveFolder'..." -ForegroundColor Cyan

$SourceDrive = Get-PSDrive -PSProvider FileSystem | Where-Object {
    ($_.Name.Length -eq 1) -and (Test-Path (Join-Path $_.Root "My Drive"))
} | Where-Object {
    Test-Path (Join-Path -Path (Join-Path $_.Root "My Drive") -ChildPath $DriveFolder)
} | Select-Object -First 1 -ExpandProperty Root

if (-not $SourceDrive) {
    Write-Error "Could not automatically find a drive containing the folder '$DriveFolder'."
    exit
}

$f1 = Join-Path (Join-Path $SourceDrive "My Drive") $DriveFolder

# 2. Locate Destination Folder dynamically
$TargetDestKeyword = "*LiveLoveDrinkTravel*"
Write-Host "Searching your user profile for destination folder matching '$TargetDestKeyword'..." -ForegroundColor Cyan

$f2 = Get-ChildItem -Path $env:USERPROFILE -Depth 3 -Directory -Filter $TargetDestKeyword -ErrorAction SilentlyContinue | 
      Select-Object -First 1 -ExpandProperty FullName

if (-not $f2) {
    Write-Error "Could not automatically find a destination folder matching '$TargetDestKeyword' in your user profile."
    exit
}

$f2 = Join-Path $f2 $DriveFolder

# Helper function to write to both Console (with colors) and Log file
function Write-Result {
    param (
        [string]$Message,
        [ConsoleColor]$Color,
        [string]$LogFilePath
    )
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $LogFilePath -Value $Message -Encoding utf8
}

# 3. Define Log File Path
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptBaseName = [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name)
$log = Join-Path $scriptDirectory "$scriptBaseName.log"
if (Test-Path $log) { Remove-Item $log }

"--- FOLDER COMPARISON LOG: $(Get-Date) ---`n" | Out-File -FilePath $log -Encoding utf8
Write-Result -Message "Source dynamically found at: $f1" -Color Cyan -LogFilePath $log
Write-Result -Message "Destination dynamically found at: $f2`r`n" -Color Cyan -LogFilePath $log

# 4. Exclusion Definitions
$excludedNames = @("desktop.ini", "thumbs.db")
# Google Docs shortcuts created by Google Drive for Desktop
$excludedExtensions = @(".gdoc", ".gsheet", ".gslides", ".gdraw", ".gform", ".gmap", ".gshortcut")

# 5. Gather file structures
Write-Host "Indexing files and folders... (this may take a few minutes)" -ForegroundColor Cyan

$filterScript = {
    param($item)
    if ($excludedNames -contains $item.Name.ToLower()) { return $false }
    if (-not $item.PSIsContainer -and $excludedExtensions -contains $item.Extension.ToLower()) { return $false }
    return $true
}

$items1 = Get-ChildItem -Path $f1 -Recurse -Force | Where-Object { &$filterScript $_ }
$items2 = Get-ChildItem -Path $f2 -Recurse -Force | Where-Object { &$filterScript $_ }

# Build lookup hashtables for both files and folders
$dict1 = @{}
foreach ($item in $items1) {
    $relPath = $item.FullName.Substring($f1.Length).TrimStart('\', '/')
    if ([string]::IsNullOrEmpty($relPath)) { continue }
    $dict1[$relPath] = $item
}

$dict2 = @{}
foreach ($item in $items2) {
    $relPath = $item.FullName.Substring($f2.Length).TrimStart('\', '/')
    if ([string]::IsNullOrEmpty($relPath)) { continue }
    $dict2[$relPath] = $item
}

$allPaths = ($dict1.Keys + $dict2.Keys) | Select-Object -Unique
$totalCount = $allPaths.Count
$currentIndex = 0

Write-Result -Message "Starting folder comparison across $totalCount files..." -Color Cyan -LogFilePath $log

# 6. Compare with Progress and Color-Coded Output
foreach ($relPath in $allPaths) {
    $currentIndex++
    $percent = [math]::Round(($currentIndex / $totalCount) * 100)

    Write-Progress -Activity "Comparing Folders" `
                   -Status "Processing: $relPath" `
                   -PercentComplete $percent `
                   -CurrentOperation "$currentIndex of $totalCount files"

    $inSrc = $dict1.ContainsKey($relPath)
    $inDst = $dict2.ContainsKey($relPath)

    # Check 1: Item Presence
    if ($inSrc -and -not $inDst) {
        $itemType = if ($dict1[$relPath].PSIsContainer) { 'FOLDER' } else { 'FILE' }
        Write-Result -Message "[ONLY IN SOURCE] [$itemType] -> $relPath" -Color Yellow -LogFilePath $log
        continue
    }
    if (-not $inSrc -and $inDst) {
        $itemType = if ($dict2[$relPath].PSIsContainer) { 'FOLDER' } else { 'FILE' }
        Write-Result -Message "[ONLY IN TARGET] [$itemType] -> $relPath" -Color DarkYellow -LogFilePath $log
        continue
    }

    $item1 = $dict1[$relPath]
    $item2 = $dict2[$relPath]

    if ($item1.PSIsContainer -or $item2.PSIsContainer) {
        continue
    }

    $isLink = $item1.Extension.ToLower() -eq ".lnk"

    # Check 2: Timestamp Check First
    # Standardizing to UTC to avoid daylight saving time offset mismatches
    $timeDiff = [math]::Abs(($item1.LastWriteTimeUtc - $item2.LastWriteTimeUtc).TotalSeconds)
    
    if ($timeDiff -gt 2) {
        # Timestamps differ; check content hash
        $hash1 = (Get-FileHash $item1.FullName -Algorithm SHA256).Hash
        $hash2 = (Get-FileHash $item2.FullName -Algorithm SHA256).Hash

        if ($hash1 -ne $hash2) {
            if ($isLink) {
                # .lnk files noted specially
                Write-Result -Message "[LNK MISMATCH (Expected)] -> $relPath" -Color DarkGray -LogFilePath $log
            } else {
                Write-Result -Message "[MODIFIED CONTENT] -> $relPath" -Color Red -LogFilePath $log
            }
        } else {
            # Same content, but timestamp was modified
            Write-Result -Message "[TIMESTAMP DIFFERENCE ONLY] -> $relPath" -Color Magenta -LogFilePath $log
        }
    } else {
        # If timestamps match and it's a shortcut (.lnk), explicitly flag as matching
        if ($isLink) {
            Write-Result -Message "[LNK MATCH] -> $relPath" -Color DarkGray -LogFilePath $log
        }
    }
}

# Clear progress bar UI
Write-Progress -Activity "Comparing Folders" -Completed

Write-Host "`nComparison complete! Log saved to: $log" -ForegroundColor Green