param([Parameter(Mandatory=$true, ValueFromPipeline=$true)][string]$Path)
Get-ChildItem $Path | ForEach-Object {
    magick $_.FullName -auto-orient -strip -quality 80 "$($_.DirectoryName)\$($_.BaseName).webp"
}
