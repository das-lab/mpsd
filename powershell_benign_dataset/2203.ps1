
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