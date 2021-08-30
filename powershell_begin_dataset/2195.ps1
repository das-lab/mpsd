
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed")]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [ValidateNotNullOrEmpty()]
    [string]$SiteServer,
    [parameter(Mandatory=$true, HelpMessage="Name of the collection to be used as limiting collection for all maintenance collections")]
    [ValidateNotNullOrEmpty()]
    [string]$LimitingCollectionName,
    [parameter(Mandatory=$false, HelpMessage="Name of a Device Collections folder where the collections will be created. If not specified, the collections will be created in the root of Device Collections")]
    [ValidateNotNullOrEmpty()]
    [string]$FolderName
)
Begin {
    
    try {
        Write-Verbose "Determining SiteCode for Site Server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Debug "SiteCode: $($SiteCode)"
            }
        }
    }
    catch [Exception] {
        Write-Warning -Message "Unable to determine SiteCode" ; break
    }
    
    if (-not(Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name like '$($LimitingCollectionName)'")) {
        Write-Warning -Message "Unable to determine the existence of a collection named '$($LimitingCollectionName)'" ; break
    }
}
Process {
    
    function New-ScheduleToken {
        param(
            [parameter(Mandatory=$false)]
            [int]$DayDuration = 0,
            [parameter(Mandatory=$false)]
            [int]$DaySpan = 0,
            [parameter(Mandatory=$false)]
            [int]$HourDuration = 0,
            [parameter(Mandatory=$false)]
            [int]$HourSpan = 0,
            [parameter(Mandatory=$false)]
            [bool]$IsGMT = $false,
            [parameter(Mandatory=$false)]
            [int]$MinuteDuration = 0,
            [parameter(Mandatory=$false)]
            [int]$MinuteSpan = 0,
            [parameter(Mandatory=$true)]
            [int]$StartTimeHour = 0,
            [parameter(Mandatory=$true)]
            [int]$StartTimeMin = 0,
            [parameter(Mandatory=$true)]
            [int]$StartTimeSec = 0
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

    function Get-LimitingCollectionID {
        param(
            [parameter(Mandatory=$true)]
            [string]$LimitingCollection
        )
        
        $LimitingCollectionID = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name like '$($LimitingCollectionName)'" | Select-Object -ExpandProperty CollectionID
        return $LimitingCollectionID
    }

    function Create-Collection {
        param(
            [parameter(Mandatory=$true)]
            [string]$CollectionName,
            [parameter(Mandatory=$true)]
            [string]$CollectionQuery,
            [parameter(Mandatory=$true)]
            [string]$QueryRuleName
        )
        
        $ValidateQuery = Invoke-WmiMethod -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_CollectionRuleQuery -Name ValidateQuery -ArgumentList $CollectionQuery -ComputerName $SiteServer
        
        if ($ValidateQuery) {
            $NewRule = ([WMIClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_CollectionRuleQuery").CreateInstance()
            $NewRule.QueryExpression = $CollectionQuery
            $NewRule.RuleName = $QueryRuleName
            
            Write-Verbose -Message "Creating collection: $($CollectionName)"
            $NewDeviceCollection = ([WmiClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_Collection").CreateInstance()
            $NewDeviceCollection.Name = $CollectionName
            $NewDeviceCollection.OwnedByThisSite = $true
            $NewDeviceCollection.CollectionRules += $NewRule
            $NewDeviceCollection.LimitToCollectionID = (Get-LimitingCollectionID -LimitingCollection $LimitingCollectionName)
            $NewDeviceCollection.RefreshSchedule = (New-ScheduleToken -HourSpan 12 -StartTimeHour 7 -StartTimeMin 0 -StartTimeSec 0)
            $NewDeviceCollection.RefreshType = 2
            $NewDeviceCollection.CollectionType = 2
            $NewDeviceCollection.Put() | Out-Null
            
            if ((Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name like '$($CollectionName)'" | Measure-Object).Count -eq 1) {
                Write-Verbose -Message "Successfully created collection '$($CollectionName)'"
            }
            else {
                Write-Warning -Message "Unable to create collection '$($CollectionName)'"
            }
            
            if ($Script:PSBoundParameters["FolderName"]) {
                $CollectionID = Get-WmiObject -Namespace "root\SMS\Site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name like '$($CollectionName)' AND CollectionType = 2" | Select-Object -ExpandProperty CollectionID
                [int]$TargetFolder = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_ObjectContainerNode -ComputerName $SiteServer -Filter "ObjectType = 5000 AND Name like '$($FolderName)'" | Select-Object -ExpandProperty ContainerNodeID
                [int]$SourceFolder = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_ObjectContainerItem -ComputerName $SiteServer -Filter "InstanceKey like '$($CollectionID)'" | Select-Object -ExpandProperty ContainerNodeID
                $Parameters = ([WmiClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_ObjectContainerItem").GetMethodParameters("MoveMembers")
                $Parameters.ObjectType = 5000
                $Parameters.ContainerNodeID = $SourceFolder
                $Parameters.TargetContainerNodeID = $TargetFolder
                $Parameters.InstanceKeys = $CollectionID
                $MoveCollectionToFolder = ([WmiClass]"\\$($SiteServer)\root\SMS\Site_$($SiteCode):SMS_ObjectContainerItem").InvokeMethod("MoveMembers", $Parameters, $null)
                if ($MoveCollectionToFolder.ReturnValue -eq 0) {
                    Write-Verbose -Message "Successfully moved collection '$($CollectionName)' to the '$($FolderName)' folder"
                }
            }
            
            $NewDeviceCollection.RequestRefresh() | Out-Null
        }
    }

    
    $CollectionsTable = @{
        "All Obsolete Systems" = 'select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.Obsolete = "1"'
        "All Inactive Systems" = 'select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_CH_ClientSummary on SMS_G_System_CH_ClientSummary.ResourceId = SMS_R_System.ResourceId where SMS_G_System_CH_ClientSummary.ClientActiveStatus = 0'
        "All Active Systems" = 'select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_CH_ClientSummary on SMS_G_System_CH_ClientSummary.ResourceID = SMS_R_System.ResourceId where SMS_G_System_CH_ClientSummary.ClientActiveStatus = 1 and SMS_R_System.Client is not null'
        "All Systems with a ConfigMgr Client" = 'select MS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.Client is not NULL'
        "All Systems without a ConfigMgr Client" = 'select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.Client is null'
        "All Systems with Pending Reboot" = 'select SMS_R_SYSTEM.ResourceID, SMS_R_SYSTEM.ResourceType, SMS_R_SYSTEM.Name, SMS_R_SYSTEM.SMSUniqueIdentifier, SMS_R_SYSTEM.ResourceDomainORWorkgroup, SMS_R_SYSTEM.Client FROM sms_r_system inner join SMS_UpdateComplianceStatus ON SMS_UpdateComplianceStatus.MachineId = SMS_R_System.ResourceId WHERE SMS_UpdateComplianceStatus.LastEnforcementMessageID = 9'
        "All Servers not rebooted in the last 30 days" = 'select SMS_R_SYSTEM.ResourceID, SMS_R_SYSTEM.ResourceType, SMS_R_SYSTEM.Name, SMS_R_SYSTEM.SMSUniqueIdentifier, SMS_R_SYSTEM.ResourceDomainORWorkgroup, SMS_R_SYSTEM.Client from SMS_R_System INNER JOIN SMS_G_System_OPERATING_SYSTEM ON SMS_G_System_OPERATING_SYSTEM.ResourceID = SMS_R_System.ResourceId WHERE (SMS_G_System_OPERATING_SYSTEM.Caption like "%2003%" or SMS_G_System_OPERATING_SYSTEM.Caption like "%2008%") or SMS_G_System_OPERATING_SYSTEM.Caption like "%2012%") and (DateDiff(day, SMS_G_System_OPERATING_SYSTEM.LastBootUpTime, GetDate()) >30)'
    }
    foreach ($Collection in $CollectionsTable.Keys) {
        Create-Collection -CollectionName $Collection -CollectionQuery $CollectionsTable["$Collection"] -QueryRuleName $Collection
    }
}