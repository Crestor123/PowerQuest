Param(
    [string]$Path = './app',
    [string]$DestinationPath = './',
    [switch]$PathIsWebApp
)

If (-Not (Test-Path $Path))
{
    Throw "The source directory $Path does not exist"
}

$date = Get-Date -format "yyyy-MM-dd"
$DestinationFile = "$($DestinationPath + 'backup-')$date.zip"

If (-Not (Test-Path $DestinationFile))
{
    Compress-Archive -Path $Path -CompressionLevel 'Fastest' -Destination "$($DestinationPath + 'backup-' + $date)"
    Write-Host "Created backup at $('./backup' + $date).zip"
}
Else 
{
    Write-Error "Today's backup already exists"
}