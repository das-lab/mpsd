
function Test-CPowerShellIs32Bit
{
    
    [CmdletBinding()]
    param(
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    return -not (Test-CPowerShellIs64Bit)
}
