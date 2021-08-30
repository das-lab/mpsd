
function Get-CPathToHostsFile
{
    
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    return Join-Path $env:windir system32\drivers\etc\hosts
}

