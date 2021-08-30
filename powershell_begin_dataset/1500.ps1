













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
