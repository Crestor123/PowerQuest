$data = [System.Collections.ArrayList]::new()
$input

Write-Host "Please input text or numbers"

do 
{
    $input = Read-Host
    If (!$input)
    {
        break
    }
    Else
    {
        [void]$data.add($input)
    }
}
while (!$input -eq "")

$data | sort | get-unique