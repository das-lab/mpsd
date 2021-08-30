
function Revoke-CPrivilege
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
    
    
    $cPrivileges = Get-CPrivilege -Identity $account.FullName |
                        Where-Object { $Privilege -contains $_ }
    if( -not $cPrivileges )
    {
        return
    }
    
    try
    {
        [Carbon.Security.Privilege]::RevokePrivileges($account.FullName,$cPrivileges)
    }
    catch
    {
        Write-Error -Message ('Failed to revoke {0}''s {1} privilege(s).' -f $account.FullName,($cPrivileges -join ', ')) 

        $ex = $_.Exception
        while( $ex.InnerException )
        {
            $ex = $ex.InnerException
            Write-Error -Exception $ex
        }
    }
}

