function Remove-SCCMUserDeviceAffinity
{


    [CmdletBinding(DefaultParameterSetName = 'ResourceName')]
    param
    (
        [Parameter(ParameterSetName = 'ResourceName')]
        [Parameter(ParameterSetName = 'ResourceID')]
        $SiteCode,

        [Parameter(ParameterSetName = 'ResourceName',
                   Mandatory = $true)]
        [Parameter(ParameterSetName = 'ResourceID')]
        $SiteServer,

        [Parameter(ParameterSetName = 'ResourceName')]
        [Alias('Name', 'ResourceName')]
        $DeviceName,

        [Parameter(ParameterSetName = 'ResourceID')]
        [Alias('ResourceID')]
        $DeviceID,

        [Parameter(ParameterSetName = 'ResourceName')]
        [Parameter(ParameterSetName = 'ResourceID')]
        [Alias('RunAs')]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    $CIMsessionSplatting = @{
        ComputerName = $SiteServer
    }


    
    IF ($PSBoundParameters['Credential'])
    {
        $CIMsessionSplatting.Credential = $Credential
    }

    
    $CIMSession = New-CimSession @CIMsessionSplatting

    
    $CIMSplatting = @{
        CimSession = $CIMSession
        NameSpace = "root\sms\site_$SiteCode"
        ClassName = "SMS_UserMachineRelationship"
    }

    
    IF ($PSBoundParameters['DeviceName'])
    {
        $CIMSplatting.Filter = "ResourceName='$DeviceName' AND isActive=1 AND TYPES NOT NULL"
    }

    
    IF ($PSBoundParameters['DeviceID'])
    {
        $CIMSplatting.Filter = "ResourceID='$DeviceID' AND isActive=1 AND TYPES NOT NULL"
    }

    Get-CimInstance @CIMSplatting | Remove-CimInstance
}