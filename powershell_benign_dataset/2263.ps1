
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,

    [parameter(Mandatory=$true, HelpMessage="Specify a Configuration Manager version that should be installed. Valid format is e.g. 1602 or 1606.")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({$_.Length -eq 4})]
    [string]$Version,

    [parameter(Mandatory=$false, HelpMessage="Specify how many times the script will check if an UpdatePackage is available for installation.")]
    [ValidateNotNullOrEmpty()]
    [int]$AvailabilityCheckCount = 120,

    [parameter(Mandatory=$false, HelpMessage="Specify how many times the script will check if the prerequisite checks has completed for an UpdatePackage.")]
    [ValidateNotNullOrEmpty()]
    [int]$PrerequisiteCheckCount = 120
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
}
Process {
    
    $UpdateCheckCount = 0
    $PrereqCheckCount = 0
    $UpdatePackageAvailibility = $false

    
    $CMUpdatePackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_CM_UpdatePackages -ComputerName $SiteServer -Filter "(Name like 'Configuration Manager $($Version)%') AND (UpdateType = 0) AND (State != 196612)" -Verbose:$false
    if (($CMUpdatePackage | Measure-Object).Count -eq 1) {
        do {
            
            $UpdateCheckCount++

            
            Write-Verbose -Message "Configuration Manager Servicing: Attempting to locate Update Package in SMS_CM_UpdatePackages matching 'Configuration Manager $($Version)'"
            $CMUpdatePackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_CM_UpdatePackages -ComputerName $SiteServer -Filter "(Name like 'Configuration Manager $($Version)%') AND (UpdateType = 0)" -Verbose:$false

            
            if ($CMUpdatePackage -eq $null) {
                Write-Verbose -Message "Configuration Manager Servicing ($($UpdateCheckCount) / $($AvailabilityCheckCount)): UpdatePackage was not found matching 'Configuration Manager $($Version)', sleeping for 30 seconds"
            }
            else {
                Write-Verbose -Message "Configuration Manager Servicing ($($UpdateCheckCount) / $($AvailabilityCheckCount)): UpdatePackage found, validating if $($CMUpdatePackage.Name.TrimEnd()) is ready for installation"
                switch ($CMUpdatePackage.State) {
                    327682 {
                        Write-Verbose -Message "Configuration Manager Servicing ($($UpdateCheckCount) / $($AvailabilityCheckCount)): UpdatePackage state is Downloading, sleeping for 30 seconds"
                        if ($UpdateCheckCount -eq $AvailabilityCheckCount) {
                            Write-Verbose -Message "Configuration Manager Servicing ($($UpdateCheckCount) / $($AvailabilityCheckCount)): Downloading state detected for longer than $($AvailabilityCheckCount * 30 / 60) minutes, restarting SMS_EXECUTIVE service"
                            if ($PSCmdlet.ShouldProcess("SMS_EXECUTIVE", "Restart")) {
                                Restart-Service -Name "SMS_EXECUTIVE" -Force -Verbose:$false
                            }
                            $UpdateCheckCount = 0
                        }                
                    }
                    262146 {
                        Write-Verbose -Message "Configuration Manager Servicing ($($UpdateCheckCount) / $($AvailabilityCheckCount)): UpdatePackage state is Available, attempting to initiate installation of $($CMUpdatePackage.Name.TrimEnd())"
                        $UpdatePackageAvailibility = $true
                    }
                }
            }

            
            if ($UpdatePackageAvailibility -eq $false) {
                Start-Sleep -Seconds 30
            }
        }
        while ($CMUpdatePackage.State -ne 262146)

        
        Write-Verbose -Message "Configuration Manager Servicing: Starting prerequisite checks for $($CMUpdatePackage.Name.TrimEnd())"
        $CMUpdatePackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_CM_UpdatePackages -ComputerName $SiteServer -Filter "(Name like 'Configuration Manager $($Version)%') AND (UpdateType = 0)" -Verbose:$false
        if ($CMUpdatePackage -ne $null) {
            if ($PSCmdlet.ShouldProcess($CMUpdatePackage.Name.TrimEnd(), "Install")) {
                $CMUpdatePackage.UpdatePrereqAndStateFlags(0,2) | Out-Null
            }
        }

        
        do {
            
            $PrereqCheckCount++

            
            if ($PrereqCheckCount -eq $PrerequisiteCheckCount) {
                Write-Verbose -Message "Configuration Manager Servicing ($($PrereqCheckCount) / $($PrerequisiteCheckCount)): Prerequisite checks has been in running state for $($PrerequisiteCheckCount * 30 / 60) min, restarting SMS_EXECUTIVE service"
                if ($PSCmdlet.ShouldProcess("SMS_EXECUTIVE", "Restart")) {
                    Restart-Service -Name "SMS_EXECUTIVE" -Force -Verbose:$false
                }
                $PrereqCheckCount = 0
            }
            else {
                Write-Verbose -Message "Configuration Manager Servicing ($($PrereqCheckCount) / $($PrerequisiteCheckCount)): Waiting for prerequisite checks to complete for $($CMUpdatePackage.Name.TrimEnd()), sleeping for 30 seconds"
                $CMUpdatePackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_CM_UpdatePackages -ComputerName $SiteServer -Filter "(Name like 'Configuration Manager $($Version)%') AND (UpdateType = 0)" -Verbose:$false

                
                Start-Sleep -Seconds 30
            }
        }
        while ($CMUpdatePackage.State -ne 196609)

        
        Write-Verbose -Message "Configuration Manager Servicing: Installation was successfully initated for $($CMUpdatePackage.Name.TrimEnd()), for more details, review the CMUpdate.log"        
    }
    elseif (($CMUpdatePackage | Measure-Object).Count -gt 1) {
        Write-Warning -Message "Query for Update Packages returned more than 1 instance, please define your search with a specific version"
    }
    else {
        Write-Warning -Message "Query for Update Packages did not return any instances"
    }
}