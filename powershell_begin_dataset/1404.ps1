
function Grant-CServicePermission
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name,
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $Identity,
        
        [Parameter(Mandatory=$true,ParameterSetName='FullControl')]
        [Switch]
        
        $FullControl,
        
        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        
        $QueryConfig,
        
        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        
        $ChangeConfig,
        
        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        
        $QueryStatus,
        
        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        
        $EnumerateDependents,
        
        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        
        $Start,
        
        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        
        $Stop,
        
        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        
        $PauseContinue,
        
        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        
        $Interrogate,
        
        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        
        $UserDefinedControl,
        
        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        
        $Delete,
        
        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        
        $ReadControl,
        
        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        
        $WriteDac,
        
        [Parameter(ParameterSetName='PartialControl')]
        [Switch]
        
        $WriteOwner
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
    
    $accessRights = [Carbon.Security.ServiceAccessRights]::FullControl
    if( $pscmdlet.ParameterSetName -eq 'PartialControl' )
    {
        $accessRights = 0
        [Enum]::GetValues( [Carbon.Security.ServiceAccessRights] ) |
            Where-Object { $PSBoundParameters.ContainsKey( $_ ) } |
            ForEach-Object { $accessRights = $accessRights -bor [Carbon.Security.ServiceAccessRights]::$_ }
    }
    
    $dacl = Get-CServiceAcl -Name $Name
    $dacl.SetAccess( [Security.AccessControl.AccessControlType]::Allow, $account.Sid, $accessRights, 'None', 'None' )
    
    Set-CServiceAcl -Name $Name -DACL $dacl
}


