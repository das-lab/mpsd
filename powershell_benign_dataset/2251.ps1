
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed.", ParameterSetName="SingleInstance")]
    [parameter(Mandatory=$true, ParameterSetName="AllInstances")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,

    [parameter(Mandatory=$true, HelpMessage="Specify a PackageID for a Task Sequence that will be exported.", ParameterSetName="SingleInstance")]
    [ValidateNotNullOrEmpty()]
    [string]$PackageID,

    [parameter(Mandatory=$true, HelpMessage="Export all Task Sequences.", ParameterSetName="AllInstances")]
    [ValidateNotNull()]
    [switch]$All,

    [parameter(Mandatory=$true, HelpMessage="Specify an existing valid path to where the file will be stored.", ParameterSetName="SingleInstance")]
    [parameter(Mandatory=$true, ParameterSetName="AllInstances")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("^[A-Za-z]{1}:\\\w+")]
    [ValidateScript({
	    
	    if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
		    Write-Warning -Message "$(Split-Path -Path $_ -Leaf) contains invalid characters"
	    }
	    else {
		    
		    if (Test-Path -Path $_ -PathType Container) {
				    return $true
		    }
		    else {
			    Write-Warning -Message "Unable to locate part of or the whole specified path, specify a valid path"
		    }
	    }
    })]
    [string]$Path,

    [parameter(Mandatory=$false, HelpMessage="Show a progressbar displaying the current operation.", ParameterSetName="AllInstances")]
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
}
Process {
    
    function Export-TaskSequence {
        param(
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [System.Management.ManagementBaseObject]$TaskSequencePackage
        )
        Process {
            
            $XMLFileName = ($TaskSequencePackage | Select-Object -ExpandProperty Name) + ".xml"

            
            try {
                Write-Verbose -Message "Attempting to deserialize sequence for Task Sequence Package '$($TaskSequencePackage.Name)'"
                $TaskSequence = Invoke-WmiMethod -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_TaskSequencePackage -ComputerName $SiteServer -Name "GetSequence" -ArgumentList $TaskSequencePackage -ErrorAction Stop
            }
            catch [System.Exception] {
                Write-Warning -Message "Unable to deserialize sequence for Task Sequence Package: '$($TaskSequencePackage.Name)'" ; break
            }

            
            try {
                Write-Verbose -Message "Attempting to convert sequence for Task Sequence Package '$($TaskSequencePackage.Name)' to XML Document"
                $TaskSequenceResult = Invoke-WmiMethod -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_TaskSequence -ComputerName $SiteServer -Name "SaveToXml" -ArgumentList $TaskSequence.TaskSequence -ErrorAction Stop
                $TaskSequenceXML = [xml]$TaskSequenceResult.ReturnValue
            }
            catch [System.Exception] {
                Write-Warning -Message "Unable to convert sequence for Task Sequence Package '$($TaskSequencePackage.Name)' to XML Document" ; break
            }

            
            try {
                Write-Verbose -Message "Attempting to save '$($XMLFileName)' to '$($Script:Path)"
                $TaskSequenceXML.Save((Join-Path -Path $Script:Path -ChildPath $XMLFileName -ErrorAction Stop))
            }
            catch [System.Exception] {
                Write-Warning -Message "Unable to save XML Document to: '$($Script:Path)" ; break
            }
        }
    }

    
    if ($PSBoundParameters["ShowProgress"]) {
        $ProgressCount = 0
    }

    switch ($PSCmdlet.ParameterSetName) {
        "SingleInstance" {
            
            try {
                Write-Verbose -Message "Querying the SMS Provider for Task Sequence Package with PackageID of '$($PackageID)'"
                $TaskSequencePackage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_TaskSequencePackage -ComputerName $SiteServer -Filter "PackageID like '$($PackageID)'" -ErrorAction Stop
            }
            catch [System.Exception] {
                Write-Warning -Message $_.Exception.Message ; break
            }

            
            if ($TaskSequencePackage -ne $null) {
                $TaskSequencePackage.Get()
                Export-TaskSequence -TaskSequencePackage $TaskSequencePackage
            }
            else {
                Write-Warning -Message "Query for Task Sequence Package with PackageID '$($PackageID)' did not return any objects"
            }
        }
        "AllInstances" {
            
            try {
                Write-Verbose -Message "Querying the SMS Provider for all Task Sequence Packages"
                $TaskSequencePackages = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_TaskSequencePackage -ComputerName $SiteServer -ErrorAction Stop
            }
            catch [System.Exception] {
                Write-Warning -Message $_.Exception.Message ; break
            }

            
            if ($TaskSequencePackages -ne $null) {
                
                $TaskSequencePackagesCount = ($TaskSequencePackages | Measure-Object).Count

                
                foreach ($TaskSequencePackage in $TaskSequencePackages) {
                    
                    if ($PSBoundParameters["ShowProgress"]) {
                        $ProgressCount++
                        Write-Progress -Activity "Exporting Task Sequences" -Id 1 -Status "$($ProgressCount) / $($TaskSequencePackagesCount)" -CurrentOperation "Current Task Sequence: $($TaskSequencePackage.Name)" -PercentComplete (($ProgressCount / $TaskSequencePackagesCount) * 100)
                    }

                    
                    $TaskSequencePackage.Get()
                    Export-TaskSequence -TaskSequencePackage $TaskSequencePackage
                }
            }
            else {
                Write-Warning -Message "Query for all Task Sequence Packages did not return any objects"
            }
        }
    }
}
End {
    if ($PSBoundParameters["ShowProgress"]) {
        Write-Progress -Activity "Exporting Task Sequences" -Id 1 -Completed
    }
}