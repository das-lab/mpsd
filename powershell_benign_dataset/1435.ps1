
function Grant-CPrivilege
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Identity,
        
        [Parameter(Mandatory=$true)]
        [string[]]
        
        $Privilege
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $account = Resolve-CIdentity -Name $Identity
    if( -not $account )
    {
        return
    }
    
    try
    {
        [Carbon.Security.Privilege]::GrantPrivileges( $account.FullName, $Privilege )
    }
    catch
    {
        $ex = $_.Exception
        do
        {
            if( $ex -is [ComponentModel.Win32Exception] -and $ex.Message -eq 'No such privilege. Indicates a specified privilege does not exist.' )
            {
                $msg = 'Failed to grant {0} {1} privilege(s): {2}  *Privilege names are **case-sensitive**.*' -f `
                        $account.FullName,($Privilege -join ','),$ex.Message
                Write-Error -Message $msg
                return
            }
            else
            {
                $ex = $ex.InnerException
            }
        }
        while( $ex )

        $ex = $_.Exception        
        Write-Error -Message ('Failed to grant {0} {1} privilege(s): {2}' -f $account.FullName,($Privilege -join ', '),$ex.Message)
        
        while( $ex.InnerException )
        {
            $ex = $ex.InnerException
            Write-Error -Exception $ex
        }
    }
}

