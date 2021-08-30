

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$Path
)



$files = ls -r $Path | ? { $_.Name -match ".*\-.*" }

$files | Select-Object BaseName, Length | Sort-Object Length | ConvertTo-Csv -Delimiter "`t"