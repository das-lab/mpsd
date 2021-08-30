
function Get-CComSecurityDescriptor
{
    
    [CmdletBinding()]
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
        
        [Switch]
        
        $AsComAccessRule
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $regValueName = $pscmdlet.ParameterSetName
    
    $bytes = Get-CRegistryKeyValue -Path $ComRegKeyPath -Name $regValueName
    
    $converter = New-Object Management.ManagementClass 'Win32_SecurityDescriptorHelper'

    if( -not $bytes -and $pscmdlet.ParameterSetName -eq 'DefaultAccessPermission')
    {
        Write-Warning "COM Default Access Permission not found. Using reverse-engineered, hard-coded default access permissions."

        
        
        $DEFAULT_SDDL = 'O:BAG:BAD:(A;;CCDCLC;;;PS)(A;;CCDC;;;SY)(A;;CCDCLC;;;BA)'
        $sd = $converter.SDDLToWin32SD( $DEFAULT_SDDL )
    }
    else
    {
        $sd = $converter.BinarySDToWin32SD( $bytes )
    }
    
    if( $AsComAccessRule )
    {
        $sd.Descriptor.DACL | 
            ForEach-Object {
                
                if( -not $_.Trustee.Domain -and -not $_.Trustee.Name )
                {
                    Write-Debug ('Unresolved trustee: SID: {0}' -f $_.Trustee.SidString)
                    return
                }
                
                $identity = New-Object Security.Principal.NTAccount $_.Trustee.Domain,$_.Trustee.Name
                $rights = [Carbon.Security.ComAccessRights]$_.AccessMask
                $controlType = [Security.AccessControl.AccessControlType]$_.AceType

                New-Object Carbon.Security.ComAccessRule $identity,$rights,$controlType
            }
    }
    else
    {
        $sd.Descriptor
    }
}

