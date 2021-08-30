
function Clear-CDscLocalResourceCache
{
    
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Get-WmiObject msft_providers | 
        Where-Object {$_.provider -like 'dsccore'} | 
        Select-Object -ExpandProperty HostProcessIdentifier | 
        ForEach-Object { Get-Process -ID $_ } | 
        Stop-Process -Force
}
