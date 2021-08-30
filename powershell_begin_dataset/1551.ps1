
function Get-MrAvailableDriveLetter {



    [CmdletBinding()]
    param (
        [string[]]$ExcludeDriveLetter = ('A-F', 'Z'),

        [switch]$Random,

        [switch]$All
    )
    
    $Drives = Get-ChildItem -Path Function:[a-z]: -Name

    if ($ExcludeDriveLetter) {
        $Drives = $Drives -notmatch "[$($ExcludeDriveLetter -join ',')]"
    }

    if ($Random) {
        $Drives = $Drives | Get-Random -Count $Drives.Count
    }

    if (-not($All)) {
        
        foreach ($Drive in $Drives) {
            if (-not(Test-Path -Path $Drive)){
                return $Drive
            }
        }

    }
    else {
        Write-Output $Drives | Where-Object {-not(Test-Path -Path $_)}
    }

}