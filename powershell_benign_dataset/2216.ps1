
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,
    [parameter(Mandatory=$true, HelpMessage="Specify the Knowledge Base Article ID to be removed from all Deployment Packages")]
    [ValidateNotNullOrEmpty()]
    [string[]]$ArticleID
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
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message $_.Exception.Message ; break
    }
}
Process {
    try {
        $DeploymentPackageList = New-Object -TypeName System.Collections.ArrayList
        foreach ($ArticleIDItem in $ArticleID) {
            
            if ($ArticleIDItem.StartsWith("KB")) {
                $ArticleIDItem = $ArticleIDItem.Replace("KB","")
            }
            
            Write-Verbose -Message "Execute query: SELECT * FROM SMS_SoftwareUpdate WHERE ArticleID like '$($ArticleIDItem)'"
            $SoftwareUpdate = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_SoftwareUpdate -Filter "ArticleID like '$($ArticleIDItem)'" -ErrorAction Stop
            foreach ($CIID in $SoftwareUpdate.CI_ID) {
                if ($SoftwareUpdate -ne $null) {
                    
                    Write-Verbose -Message "Execute query: SELECT SMS_PackageToContent.ContentID,SMS_PackageToContent.PackageID from SMS_PackageToContent JOIN SMS_CIToContent on SMS_CIToContent.ContentID = SMS_PackageToContent.ContentID where SMS_CIToContent.CI_ID in ($($CIID))"
                    $ContentData = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Query "SELECT SMS_PackageToContent.ContentID,SMS_PackageToContent.PackageID from SMS_PackageToContent JOIN SMS_CIToContent on SMS_CIToContent.ContentID = SMS_PackageToContent.ContentID where SMS_CIToContent.CI_ID in ($($CIID))" -ErrorAction Stop
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
                else {
                    Write-Warning -Message "Unable to find a Software Update with ArticleID '$($ArticleIDItem)'"
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
    catch [System.UnauthorizedAccessException] {
        Write-Warning -Message "Access denied" ; break
    }
    catch [System.Exception] {
        Write-Warning -Message "$($_.Exception.Message) at line: $($_.InvocationInfo.ScriptLineNumber)" ; break
    }
}