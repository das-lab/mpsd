
function Invoke-CAppCmd
{
    
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments=$true)]
        
        $AppCmdArgs
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-Warning ('Invoke-CAppCmd is obsolete and will be removed in a future major version of Carbon. Use Carbon''s IIS functions, or `Get-CIisConfigurationSection` to get `ConfigurationElement` objects to manipulate using the `Microsoft.Web.Administration` API.')

    Write-Verbose ($AppCmdArgs -join " ")
    & (Join-Path $env:SystemRoot 'System32\inetsrv\appcmd.exe') $AppCmdArgs
    if( $LastExitCode -ne 0 )
    {
        Write-Error "``AppCmd $($AppCmdArgs)`` exited with code $LastExitCode."
    }
}

