
function Uninstall-CUser
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,20)]
        [string]
        
        $Username
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    if( Test-CUser -Username $username )
    {
        $user = Get-CUser -Username $Username
        try
        {
            if( $pscmdlet.ShouldProcess( $Username, "remove local user" ) )
            {
                $user.Delete()
            }
        }
        finally
        {
            $user.Dispose()
        }
    }
}

Set-Alias -Name 'Remove-User' -Value 'Uninstall-CUser'

