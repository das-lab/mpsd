

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False,Position=1)]
        [String]$BasePath="C:\"
)


if (Test-Path "$env:SystemRoot\du.exe") {
    & $env:SystemRoot\du.exe -q -c -l 3 $BasePath 2> $null | ConvertFrom-Csv
} else {
    Write-Error "du.exe not found in $env:SystemRoot."
}