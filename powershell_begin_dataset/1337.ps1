
function Revoke-CComPermission
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]        
        $Identity,
        
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
        
        $Limits
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $comArgs = @{ }
    if( $pscmdlet.ParameterSetName -like 'Default*' )
    {
        $typeDesc = 'default security permissions'
        $comArgs.Default = $true
    }
    else
    {
        $typeDesc = 'security limits'
        $comArgs.Limits = $true
    }
    
    if( $pscmdlet.ParameterSetName -like '*Access*' )
    {
        $permissionsDesc = 'Access'
        $comArgs.Access = $true
    }
    else
    {
        $permissionsDesc = 'Launch and Activiation'
        $comArgs.LaunchAndActivation = $true
    }
    
    $account = Resolve-CIdentity -Name $Identity
    if( -not $account )
    {
        return
    }

    Write-Verbose ("Revoking {0}'s COM {1} {2}." -f $Identity,$permissionsDesc,$typeDesc)
    $currentSD = Get-CComSecurityDescriptor @comArgs

    $newSd = ([wmiclass]'win32_securitydescriptor').CreateInstance()
    $newSd.ControlFlags = $currentSD.ControlFlags
    $newSd.Group = $currentSD.Group
    $newSd.Owner = $currentSD.Owner

    
    $newSd.DACL = $currentSD.DACL | 
                    Where-Object { $_.Trustee.SIDString -ne $account.Sid.Value } | 
                    ForEach-Object { $_.PsObject.BaseObject }

    $converter = New-Object Management.ManagementClass 'Win32_SecurityDescriptorHelper'
    $sdBytes = $converter.Win32SDToBinarySD( $newSd )

    $regValueName = $pscmdlet.ParameterSetName
    Set-CRegistryKeyValue -Path $ComRegKeyPath -Name $regValueName -Binary $sdBytes.BinarySD
}

Set-Alias -Name 'Revoke-ComPermissions' -Value 'Revoke-CComPermission'

