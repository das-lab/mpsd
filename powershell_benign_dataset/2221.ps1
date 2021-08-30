
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, ParameterSetName="Array", HelpMessage="Site server name with SMS Provider installed")]
    [parameter(ParameterSetName="Text")]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [ValidateNotNullorEmpty()]
    [string]$SiteServer,
    [parameter(Mandatory=$true, ParameterSetName="Array", HelpMessage="Specify a single or an array of CI_UniqueIDs to remove memberships from Software Update Groups")]
    [ValidateNotNullorEmpty()]
    [string[]]$CIUniqueID,
    [parameter(Mandatory=$true, ParameterSetName="Text", HelpMessage="Path to a text file containing CI_UniqueID's on a seperate line that will their have memberships with Software Update Groups removed")]
    [ValidateNotNullorEmpty()]
    [ValidatePattern("^(?:[\w]\:|\\)(\\[a-z_\-\s0-9\.]+)+\.(txt)$")]
    [ValidateScript({
	    
	    if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
		    Write-Warning -Message "$(Split-Path -Path $_ -Leaf) contains invalid characters" ; break
	    }
	    else {
		    
		    if (-not(Test-Path -Path (Split-Path -Path $_) -PathType Container -ErrorAction SilentlyContinue)) {
			    Write-Warning -Message "Unable to locate part of or the whole specified path" ; break
		    }
		    elseif (Test-Path -Path (Split-Path -Path $_) -PathType Container -ErrorAction SilentlyContinue) {
			    return $true
		    }
		    else {
			    Write-Warning -Message "Unhandled error" ; break
		    }
	    }
    })]
    [string]$Path
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
    
    $CIUniqueList = Get-Content -Path $Path
    $RemovedSoftwareUpdatesList = New-Object -TypeName System.Collections.ArrayList
    $RemovedSoftwareUpdatesList.AddRange(@($CIUniqueList))
}
Process {
    try {
        $AuthorizationLists = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_AuthorizationList -ComputerName $SiteServer -ErrorAction Stop
        foreach ($AuthorizationList in $AuthorizationLists) {
            $AuthorizationList.Get()
            Write-Verbose -Message "Enumerating Software Update Group: $($AuthorizationList.LocalizedDisplayName)"
            foreach ($CI in $CIUniqueList) {
                $CIObject = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_SoftwareUpdate -ComputerName $SiteServer -Filter "CI_UniqueID = '$($CI)'" -ErrorAction Stop
                Write-Verbose -Message "Searching for Software Update with CI_UniqueID: $($CIObject.CI_UniqueID)"
                if ($CIObject.CI_ID -in ($AuthorizationList.Updates)) {
                    if ($PSCmdlet.ShouldProcess($AuthorizationList.LocalizedDisplayName, "Remove Software Update with CI_UniqueID '$($CIObject.CI_UniqueID)'")) {
                        Write-Verbose -Message "Software Update with CI_UniqueID '$($CIObject.CI_UniqueID)' and 'KB$($CIObject.ArticleID)' will be removed from '$($AuthorizationList.LocalizedDisplayName)'"
                        $NewSoftwareUpdatesList = New-Object -TypeName System.Collections.ArrayList
                        $NewSoftwareUpdatesList.AddRange(@($AuthorizationList.Updates)) | Out-Null
                        Write-Verbose -Message "Count for '$($AuthorizationList.LocalizedDisplayName)': $($NewSoftwareUpdatesList.Count)"
                        Write-Verbose -Message "Removing Software Update with CI_UniqueID '$($CIObject.CI_UniqueID)' from '$($AuthorizationList.LocalizedDisplayName)'"
                        $NewSoftwareUpdatesList.Remove($CIObject.CI_ID)
                        $ErrorActionPreference = "Stop"
                        try {
                            $AuthorizationList.Updates = $NewSoftwareUpdatesList
                            $AuthorizationList.Put() | Out-Null
                            Write-Verbose -Message "Count for '$($AuthorizationList.LocalizedDisplayName)': $($NewSoftwareUpdatesList.Count)"
                            Write-Warning -Message "Successfully removed Software Update with CI_UniqueID '$($CIObject.CI_UniqueID)' from '$($AuthorizationList.LocalizedDisplayName)'"
                        }
                        catch [System.Exception] {
                            Write-Warning -Message "Unable to remove Software Update with CI_UniqueID '$($CIObject.CI_UniqueID)' from '$($AuthorizationList.LocalizedDisplayName)'"
                        }
                    }
                }
            }
        }
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to retrieve Software Update Groups from $($SiteServer)"
    }
}