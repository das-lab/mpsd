
function Test-COSIs64Bit
{
    
    [CmdletBinding()]
    param(
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    return ([Environment]::Is64BitOperatingSystem)
}

