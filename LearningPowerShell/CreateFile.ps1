Param
(
    [Parameter(Mandatory, HelpMessage = "Please provide a valid path")]
    [string]$Path
)

If (-Not (Test-Path $Path))
{
    Throw "The source directory $Path does not exist"
}

New-Item $Path
Write-Host "File $Path was created"

