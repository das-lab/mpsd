Function Add-SCCMUserDeviceAffinity
{

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True, HelpMessage = "Please Enter Site Server Site code")]
        $SiteCode,

        [Parameter(Mandatory = $True, HelpMessage = "Please Enter Site Server Name")]
        $SiteServer,

        [Parameter(Mandatory = $True, HelpMessage = "Please Enter Device Name")]
        $DeviceName,

        [Parameter()]
        $DeviceID,

        [Parameter(Mandatory = $True, HelpMessage = "Please Enter User Name")]
        $UserName,

        [Alias("RunAs")]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    $Splatting = @{
        NameSpace = "root\sms\site_$SiteCode"
        ComputerName = $SiteServer
    }

    IF ($PSBoundParameters['Credential'])
    {
        $Splatting.Credential = $Credential
    }


    $AffinityType = 2 

    IF ($PSBoundParameters['DeviceName'])
    {
        $ResourceID = (Get-WmiObject @Splatting -Class "SMS_CombinedDeviceResources" -Filter "Name='$DeviceName'" -ErrorAction STOP).resourceID
    }
    IF ($PSBoundParameters['DeviceID'])
    {
        $ResourceID = $DeviceID
    }

    Invoke-WmiMethod @Splatting -Class "SMS_UserMachineRelationship" -Name "CreateRelationship" -ArgumentList @($ResourceID, $AffinityType, 1, $UserName)
}