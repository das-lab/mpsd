
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