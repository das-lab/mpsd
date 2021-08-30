
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, HelpMessage="Site server where the SMS Provider is installed.", ParameterSetName="SingleInstance")]
    [parameter(Mandatory=$true, ParameterSetName="Recursive")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 1 -Quiet})]
    [string]$SiteServer,

    [parameter(Mandatory=$true, HelpMessage="Specify a local path to a XML file that contains the required sequence data.", ParameterSetName="SingleInstance")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern("^[A-Za-z]{1}:\\\w+\\\w+")]
    [ValidateScript({
	    
	    if ((Split-Path -Path $_ -Leaf).IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
		    Write-Warning -Message "$(Split-Path -Path $_ -Leaf) contains invalid characters" ; break
	    }
	    else {
            
		    if (-not(Test-Path -Path $_ -ErrorAction SilentlyContinue)) {
			    Write-Warning -Message "Unable to locate specified file" ; break
            }
            else {
	            
		        if ([System.IO.Path]::GetExtension((Split-Path -Path $_ -Leaf)) -like ".xml") {
			        return $true
		        }
		        else {
			        Write-Warning -Message "$(Split-Path -Path $_ -Leaf) contains unsupported file extension. Supported extension is '.xml'" ; break
		        }
            }
	    }
    })]
    [string]$File,

    [parameter(Mandatory=$true, HelpMessage="Specify a local path to a folder that contains XML files with required sequence data.", ParameterSetName="Recursive")]
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

    [parameter(Mandatory=$false, HelpMessage="Specify the Boot Image PackageID that will be associated with the imported Task Sequence.", ParameterSetName="SingleInstance")]
    [parameter(Mandatory=$false, ParameterSetName="Recursive")]
    [ValidateNotNullOrEmpty()]
    [string]$BootImageID = $null,

    [parameter(Mandatory=$false, HelpMessage="Show a progressbar displaying the current operation.", ParameterSetName="Recursive")]
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

    
    if ($BootImageID -ne $null) {
        try {
            $BootImage = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_BootImagePackage -ComputerName $SiteServer -Filter "PackageID like '$($BootImageID)'" -ErrorAction Stop
            if ($BootImage -ne $null) {
                $BootImageID = $BootImage.PackageID
            }
            else {
                Write-Warning -Message "Unable to determine Boot Image ID, please verify that you've specified an existing Boot Image" ; break
            }
        }
        catch [System.Exception] {
            Write-Warning -Message $_.Exception.Message ; break
        }
    }
}
Process {
    
    function Import-TaskSequence {
        param(
            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [System.Xml.XmlNode]$XML,

            [parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$TaskSequenceName
        )
        Process {
            
            $TaskSequenceValidate = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_TaskSequencePackage -ComputerName $SiteServer -Filter "Name like '$($TaskSequenceName)'"
            if ($TaskSequenceValidate -eq $null) {
                
                try {
                    Write-Verbose -Message "Attempting to convert XML Document for '$($TaskSequenceName)' to Task Sequence Package WMI object"
                    $TaskSequence = Invoke-WmiMethod -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_TaskSequencePackage -ComputerName $SiteServer -Name "ImportSequence" -ArgumentList $XML.OuterXml -ErrorAction Stop
                }
                catch [System.Exception] {
                    Write-Warning -Message "Unable to convert XML Document for '$($TaskSequenceName)' to Task Sequence Package WMI object" ; break
                }

                
                try {
                    Write-Verbose -Message "Attempting to create new Task Sequence Package instance for '$($TaskSequenceName)'"
                    $ErrorActionPreference = "Stop"
                    $TaskSequencePackageInstance = ([WmiClass]"\\$($SiteServer)\root\SMS\site_$($SiteCode):SMS_TaskSequencePackage").CreateInstance()
                    $TaskSequencePackageInstance.Name = $TaskSequenceName
                    $TaskSequencePackageInstance.BootImageID = $Script:BootImageID
                    $ErrorActionPreference = "Continue"
                }
                catch [System.Exception] {
                    Write-Warning -Message "Unable to create new Task Sequence Package instance for '$($TaskSequenceName)'" ; break
                }

                
                try {
                    Write-Verbose -Message "Attempting to import '$($TaskSequenceName)' Task Sequence"
                    $TaskSequenceImport = Invoke-WmiMethod -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_TaskSequencePackage -ComputerName $SiteServer -Name "SetSequence" -ArgumentList @($TaskSequence.TaskSequence, $TaskSequencePackageInstance) -ErrorAction Stop
                }
                catch [System.Exception] {
                    Write-Warning -Message "Unable to set $($TaskSequenceName) Task Sequence" ; break
                }
            }
            else {
                Write-Warning -Message "Duplicate Task Sequence name detected. Existing Task Sequence with name '$($TaskSequenceName)' PackageID '$($TaskSequenceValidate.PackageID)' already exists"
            }
        }
    }

    
    if ($PSBoundParameters["ShowProgress"]) {
        $ProgressCount = 0
    }

    switch ($PSCmdlet.ParameterSetName) {
        "SingleInstance" {
            
            try {
                $TaskSequenceName = Get-Item -LiteralPath $File -ErrorAction Stop | Select-Object -ExpandProperty BaseName
            }
            catch [System.Exception] {
                Write-Warning -Message "Unable to determine Task Sequence name from '$($File)'" ; break
            }

            
            try {
                Write-Verbose -Message "Loading XML Document from '$($File)'"
                $TaskSequenceXML = [xml](Get-Content -LiteralPath $File -Encoding UTF8 -ErrorAction Stop)
            }
            catch [System.Exception] {
                Write-Warning -Message "Unable to load XML Document from '$($File)'" ; break
            }

            
            if ($TaskSequenceXML.Sequence.HasChildNodes) {
                Import-TaskSequence -XML $TaskSequenceXML -TaskSequenceName $TaskSequenceName
            }
            else {
                Write-Warning -Message "XML file '$($File)', could not be validated successfully" ; break
            }
        }
        "Recursive" {
            
            try {
                Write-Verbose -Message "Gathering XML files from '$($Path)'"
                $XMLFiles = Get-ChildItem -LiteralPath $Path -Filter *.xml -ErrorAction Stop
            }
            catch [System.Exception] {
                Write-Warning -Message "Unable to gather XML files in '$($Path)'" ; break
            }

            
            if ($XMLFiles -ne $null) {
                
                $XMLFilesCount = ($XMLFiles | Measure-Object).Count

                
                foreach ($XMLFile in $XMLFiles) {
                    
                    try {
                        $TaskSequenceName = Get-Item -LiteralPath $XMLFile.FullName -ErrorAction Stop | Select-Object -ExpandProperty BaseName
                    }
                    catch [System.Exception] {
                        Write-Warning -Message "Unable to determine Task Sequence name from '$($XMLFile.FullName)'" ; break
                    }

                    
                    if ($PSBoundParameters["ShowProgress"]) {
                        $ProgressCount++
                        Write-Progress -Activity "Importing Task Sequences" -Id 1 -Status "$($ProgressCount) / $($XMLFilesCount)" -CurrentOperation "Current Task Sequence: $($TaskSequenceName)" -PercentComplete (($ProgressCount / $XMLFilesCount) * 100)
                    }

                    
                    try {
                        Write-Verbose -Message "Loading XML Document from '$($XMLFile.FullName)'"
                        $TaskSequenceXML = [xml](Get-Content -LiteralPath $XMLFile.FullName -Encoding UTF8 -ErrorAction Stop)
                    }
                    catch [System.Exception] {
                        Write-Warning -Message "Unable to load XML Document from '$($File)'" ; break
                    }

                    
                    if ($TaskSequenceXML.Sequence.HasChildNodes) {
                        Import-TaskSequence -XML $TaskSequenceXML -TaskSequenceName $TaskSequenceName
                    }
                    else {
                        Write-Warning -Message "XML file '$($XMLFile.FullName)', could not be validated successfully" ; break
                    }
                }
            }
        }
    }
}