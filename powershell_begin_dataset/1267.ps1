
function Revoke-CServicePermission
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name,
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $Identity
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $account = Resolve-CIdentity -Name $Identity
    if( -not $account )
    {
        return
    }
    
    if( -not (Assert-CService -Name $Name) )
    {
        return
    }
    
    if( (Get-CServicePermission -Name $Name -Identity $account.FullName) )
    {
        Write-Verbose ("Revoking {0}'s {1} service permissions." -f $account.FullName,$Name)
        
        $dacl = Get-CServiceAcl -Name $Name
        $dacl.Purge( $account.Sid )
        
        Set-CServiceAcl -Name $Name -Dacl $dacl
    }
 }
 
