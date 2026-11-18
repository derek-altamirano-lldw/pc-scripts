if (!(Test-Path $PROFILE)) { New-Item -Type File -Path $PROFILE -Force }
Add-Content $PROFILE @"
function webp {
    param([Parameter(Mandatory=`$true, ValueFromPipeline=`$true)][string]`$Path)
    Get-ChildItem `$Path | ForEach-Object {
        magick `$_.FullName -auto-orient -strip -quality 80 "`$(`$_.DirectoryName)\`$(`$_.BaseName).webp"
    }
}
"@