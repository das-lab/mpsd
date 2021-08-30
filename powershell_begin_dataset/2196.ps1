
[CmdletBinding()]
param(
    [parameter(Mandatory=$true, HelpMessage="Specify Primary Site server")]
    [string]$SiteServer = "$($env:COMPUTERNAME)",
    [parameter(Mandatory=$true, HelpMessage="Path to text file")]
    [ValidateScript({Test-Path -Path $_ -Include *.txt})]
    [string]$FilePath,
    [parameter(Mandatory=$true)]
    [string]$LimitingCollectionName,
    [parameter(Mandatory=$false)]
    [string]$FolderName
)

Begin {
    
    try {
        Write-Verbose "Determining SiteCode for Site Server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Verbose "SiteCode: $($SiteCode)"
                Write-Debug "SiteCode: $($SiteCode)"
            }
        }
    }
    catch [Exception] {
        Throw "Unable to determine SiteCode"
    }
    
    try {
        $LimitingCollectionID = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name like '$($LimitingCollectionName)'" | Select-Object -ExpandProperty CollectionID
    }
    catch [Exception] {
        Throw "Unable to determine Limiting Collection ID"
    }
}
Process {
    
    function New-ScheduleToken {
        param(
        [parameter(Mandatory=$false)]
        $DayDuration = 0,
        [parameter(Mandatory=$false)]
        $DaySpan = 0,
        [parameter(Mandatory=$false)]
        $HourDuration = 0,
        [parameter(Mandatory=$false)]
        $HourSpan = 0,
        [parameter(Mandatory=$false)]
        [bool]$IsGMT = $false,
        [parameter(Mandatory=$false)]
        $MinuteDuration = 0,
        [parameter(Mandatory=$false)]
        $MinuteSpan = 0,
        [parameter(Mandatory=$true)]
        $StartTimeHour = 0,
        [parameter(Mandatory=$true)]
        $StartTimeMin = 0,
        [parameter(Mandatory=$true)]
        $StartTimeSec = 0
        )
        $StartTime = [System.Management.ManagementDateTimeconverter]::ToDMTFDateTime((Get-Date -Hour $StartTimeHour -Minute $StartTimeMin -Second $StartTimeSec))
        $ScheduleToken = ([WMIClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_ST_RecurInterval").CreateInstance()
        $ScheduleToken.DayDuration = $DayDuration
        $ScheduleToken.DaySpan = $DaySpan
        $ScheduleToken.HourDuration = $HourDuration
        $ScheduleToken.HourSpan = $HourSpan
        $ScheduleToken.IsGMT = $IsGMT
        $ScheduleToken.MinuteDuration = $MinuteDuration
        $ScheduleToken.MinuteSpan = $MinuteSpan
        $ScheduleToken.StartTime = $StartTime
        return $ScheduleToken
    }
    
    try {
        $CollectionNames = Get-Content -Path $FilePath
        foreach ($CollectionName in $CollectionNames) {
            Write-Verbose "Creating collection: $($CollectionName)"
            $WMIConnection = [WmiClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_Collection"
            $NewDeviceCollection = $WMIConnection.psbase.CreateInstance()
            $NewDeviceCollection.Name = "$($CollectionName)"
            $NewDeviceCollection.OwnedByThisSite = $True
            $NewDeviceCollection.LimitToCollectionID = "$($LimitingCollectionID)"
            $NewDeviceCollection.RefreshSchedule = (New-ScheduleToken -HourSpan 12 -StartTimeHour 7 -StartTimeMin 0 -StartTimeSec 0)
            $NewDeviceCollection.RefreshType = 2
            $NewDeviceCollection.CollectionType = 2
            $Create = $NewDeviceCollection.Put() | Out-Null
            if ($Create.ReturnValue -eq "0") {
                Write-Verbose "Successfully created collection '$($CollectionName)'"
            }
            
            if ($PSBoundParameters["FolderName"]) {
                try {
                    
                    $CollectionID = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_Collection -Filter "Name='$($CollectionName)' and CollectionType = '2'" | Select-Object -ExpandProperty CollectionID
                    
                    [int]$TargetFolder = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_ObjectContainerNode -Filter "ObjectType = '5000' and Name = '$($FolderName)'" -ComputerName $SiteServer | Select-Object -ExpandProperty ContainerNodeID
                    
                    [int]$SourceFolder = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_ObjectContainerItem -Filter "InstanceKey = '$($CollectionID)'" -ComputerName $SiteServer | Select-Object -ExpandProperty ContainerNodeID
                    
                    $Parameters = ([WmiClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_ObjectContainerItem").psbase.GetMethodParameters("MoveMembers")
                    $Parameters.ObjectType = 5000
                    $Parameters.ContainerNodeID = $SourceFolder
                    $Parameters.TargetContainerNodeID = $TargetFolder
                    $Parameters.InstanceKeys = $CollectionID
                    $Move = ([WmiClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_ObjectContainerItem").psbase.InvokeMethod("MoveMembers",$Parameters,$null)
                    if ($Move.ReturnValue -eq "0") {
                        Write-Verbose "Moved collection '$($CollectionName)' to '$($FolderName)' folder"
                    }
                }
                catch [Exception] {
                    Throw $_.Exception.Message
                }
            }
        }
    }
    catch [Exception] {
        Write-Error $_.Exception.Message
    }
}