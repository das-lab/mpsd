
function Get-CComPermission
{
    
    [CmdletBinding()]
    [OutputType([Carbon.Security.ComAccessRights])]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='DefaultAccessPermission')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineAccessRestriction')]
        [Switch]
        
        $Access,
        
        [Parameter(Mandatory=$true,ParameterSetName='DefaultLaunchPermission')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineLaunchRestriction')]
        [Switch]
        
        $LaunchAndActivation,
        
        [Parameter(Mandatory=$true,ParameterSetName='DefaultAccessPermission')]
        [Parameter(Mandatory=$true,ParameterSetName='DefaultLaunchPermission')]
        [Switch]
        
        $Default,
        
        [Parameter(Mandatory=$true,ParameterSetName='MachineAccessRestriction')]
        [Parameter(Mandatory=$true,ParameterSetName='MachineLaunchRestriction')]
        [Switch]
        
        $Limits,
        
        [string]
        
        $Identity        
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $comArgs = @{ }
    if( $pscmdlet.ParameterSetName -like 'Default*' )
    {
        $comArgs.Default = $true
    }
    else
    {
        $comArgs.Limits = $true
    }
    
    if( $pscmdlet.ParameterSetName -like '*Access*' )
    {
        $comArgs.Access = $true
    }
    else
    {
        $comArgs.LaunchAndActivation = $true
    }
    
    Get-CComSecurityDescriptor @comArgs -AsComAccessRule |
        Where-Object {
            if( $Identity )
            {
                $account = Resolve-CIdentity -Name $Identity
                if( -not $account )
                {
                    return $false
                }
                return ( $_.IdentityReference.Value -eq $account.FullName )
            }
            
            return $true
        }
}

Set-Alias -Name 'Get-ComPermissions' -Value 'Get-CComPermission'
