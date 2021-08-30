
[CmdletBinding()]
param
(
	[switch]
	$Build,
	[ValidateNotNullOrEmpty()][string]
	$ClientInstallationDirectory = '',
	[ValidateNotNullOrEmpty()][string]
	$ClientInstallationFile = 'ccmsetup.exe',
	[switch]
	$Install,
	[string]
	$ManagementPoint = '',
	[string]
	$SMSSiteCode = '',
	[switch]
	$Uninstall,
	[switch]
	$UsePKICert,
	[switch]
	$NOCRLCheck,
	[string]
	$Source
)


function Get-MetaData {

	
	[CmdletBinding()][OutputType([object])]
	param
	(
		[ValidateNotNullOrEmpty()][string]
		$FileName
	)
	
	Write-Host "Retrieving File Description Data....." -NoNewline
	$MetaDataObject = New-Object System.Object
	$shell = New-Object -COMObject Shell.Application
	$folder = Split-Path $FileName
	$file = Split-Path $FileName -Leaf
	$shellfolder = $shell.Namespace($folder)
	$shellfile = $shellfolder.ParseName($file)
	$MetaDataProperties = 0..287 | Foreach-Object { '{0} = {1}' -f $_, $shellfolder.GetDetailsOf($null, $_) }
	For ($i = 0; $i -le 287; $i++) {
		$Property = ($MetaDataProperties[$i].split("="))[1].Trim()
		$Property = (Get-Culture).TextInfo.ToTitleCase($Property).Replace(' ', '')
		$Value = $shellfolder.GetDetailsOf($shellfile, $i)
		If ($Property -eq 'Attributes') {
			switch ($Value) {
				'A' {
					$Value = 'Archive (A)'
				}
				'D' {
					$Value = 'Directory (D)'
				}
				'H' {
					$Value = 'Hidden (H)'
				}
				'L' {
					$Value = 'Symlink (L)'
				}
				'R' {
					$Value = 'Read-Only (R)'
				}
				'S' {
					$Value = 'System (S)'
				}
			}
		}
		
		If (($Value -ne $null) -and ($Value -ne '')) {
			$MetaDataObject | Add-Member -MemberType NoteProperty -Name $Property -Value $Value
		}
	}
	[string]$FileVersionInfo = (Get-ItemProperty $FileName).VersionInfo
	$SplitInfo = $FileVersionInfo.Split([char]13)
	foreach ($Item in $SplitInfo) {
		$Property = $Item.Split(":").Trim()
		switch ($Property[0]) {
			"InternalName" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name InternalName -Value $Property[1]
			}
			"OriginalFileName" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name OriginalFileName -Value $Property[1]
			}
			"Product" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name Product -Value $Property[1]
			}
			"Debug" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name Debug -Value $Property[1]
			}
			"Patched" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name Patched -Value $Property[1]
			}
			"PreRelease" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name PreRelease -Value $Property[1]
			}
			"PrivateBuild" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name PrivateBuild -Value $Property[1]
			}
			"SpecialBuild" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name SpecialBuild -Value $Property[1]
			}
		}
	}
	
	
	$ReadOnly = (Get-ChildItem $FileName) | Select-Object IsReadOnly
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name ReadOnly -Value $ReadOnly.IsReadOnly
	
	$DigitalSignature = get-authenticodesignature -filepath $FileName
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name SignatureCertificateSubject -Value $DigitalSignature.SignerCertificate.Subject
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name SignatureCertificateIssuer -Value $DigitalSignature.SignerCertificate.Issuer
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name SignatureCertificateSerialNumber -Value $DigitalSignature.SignerCertificate.SerialNumber
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name SignatureCertificateNotBefore -Value $DigitalSignature.SignerCertificate.NotBefore
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name SignatureCertificateNotAfter -Value $DigitalSignature.SignerCertificate.NotAfter
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name SignatureCertificateThumbprint -Value $DigitalSignature.SignerCertificate.Thumbprint
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name SignatureStatus -Value $DigitalSignature.Status
	If (($MetaDataObject -ne "") -and ($MetaDataObject -ne $null)) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed" -ForegroundColor Red
	}
	Return $MetaDataObject
}

function Invoke-EXE {

	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
		[object]
		$InstallerMetaData,
		[switch]
		$Install,
		[switch]
		$Uninstall,
		[ValidateNotNullOrEmpty()][string]
		$Executable,
		[string]
		$Switches,
		[string]
		$DisplayName
	)
	
	If ($Install.IsPresent) {
		Write-Host "Initiating Installation of"$DisplayName"....." -NoNewline
		$File = $env:windir + "\ccmsetup\ccmsetup.exe"
		$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -WindowStyle Minimized -Wait -Passthru).ExitCode
		If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
			Write-Host "Success" -ForegroundColor Yellow
			If ((Test-Path $File) -eq $true) {
				Wait-ProcessEnd -ProcessName ccmsetup
			} else {
				Write-Host "Failed" -ForegroundColor Red
				$Failed = $true
			}
		} else {
			Write-Host "Failed with error"$ErrCode -ForegroundColor Red
		}
	} elseif ($Uninstall.IsPresent) {
		Write-Host "Uninstalling"$DisplayName"....." -NoNewline
		$File = $env:windir + "\ccmsetup\ccmsetup.exe"
		If ((Test-Path $File) -eq $true) {
			$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -WindowStyle Minimized -Wait -Passthru).ExitCode
			If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
				Write-Host "Success" -ForegroundColor Yellow
				If ((Test-Path $File) -eq $true) {
					Wait-ProcessEnd -ProcessName ccmsetup
				}
			} else {
				$Failed = $true
				Write-Host "Failed with error"$ErrCode -ForegroundColor Red
			}
		} else {
			Write-Host "Not Present" -ForegroundColor Green
		}
	}
	If ($Failed -eq $true) {
		Return $false
	} else {
		Return $true
	}
}

function Remove-File {

	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
		[ValidateNotNullOrEmpty()][string]
		$Filename
	)
	
	If ((Test-Path $Filename) -eq $false) {
		Write-Host $Filename" already deleted"
	} else {
		$File = Get-Item $Filename -Force
		Write-Host "Deleting"$File.Name"....." -NoNewline
		If (Test-Path $File) {
			Remove-Item $File -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Out-Null
			If ((Test-Path $Filename) -eq $False) {
				Write-Host "Success" -ForegroundColor Yellow
			} else {
				$Failed = $true
				Write-Host "Failed" -ForegroundColor Red
			}
		} else {
			Write-Host "Not Present" -ForegroundColor Green
		}
	}
	If ($Failed -eq $true) {
		Return $false
	} else {
		Return $true
	}
}

function Remove-RegistryKey {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]
		$RegistryKey,
		[switch]
		$Recurse
	)
	
	$RegKey = "Registry::" + $RegistryKey
	If ((Test-Path $RegKey) -eq $false) {
		Write-Host $RegKey" already deleted"
	} else {
		$RegKeyItem = Get-Item $RegKey
		If ($Recurse.IsPresent) {
			Write-Host "Recursive Deletion of"$RegKeyItem.PSChildName"....." -NoNewline
			Remove-Item $RegKey -Recurse -Force | Out-Null
		} else {
			Write-Host "Deleting"$RegKeyItem.PSChildName"....." -NoNewline
			Remove-Item $RegKey -Force | Out-Null
		}
		If ((Test-Path $RegKey) -eq $false) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			$Failed = $true
			Write-Host "Failed" -ForegroundColor Red
		}
	}
	If ($Failed -eq $true) {
		Return $false
	} else {
		Return $true
	}
}

function Set-ConsoleTitle {

	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)][String]
		$ConsoleTitle
	)
	
	$host.ui.RawUI.WindowTitle = $ConsoleTitle
}

function Suspend-Service {

	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
		[ValidateNotNullOrEmpty()][string]
		$Service
	)
	
	$ServiceStatus = Get-Service $Service -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
	If ($ServiceStatus -ne $null) {
		Write-Host "Stopping"$ServiceStatus.DisplayName"....." -NoNewline
		If ($ServiceStatus.Status -ne 'Stopped') {
			Stop-Service -Name $Service -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -Force
			$ServiceStatus = Get-Service $Service -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
			If ($ServiceStatus.Status -eq 'Stopped') {
				Write-Host "Success" -ForegroundColor Yellow
			} else {
				$Failed = $true
				Write-Host "Failed" -ForegroundColor Red
			}
		} else {
			Write-Host "Service already stopped" -ForegroundColor Yellow
		}
	} else {
		Write-Host $Service"service does not exist"
	}
	If ($Failed -eq $true) {
		Return $false
	} else {
		Return $true
	}
}

function Wait-ProcessEnd {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]
		$ProcessName
	)
	
	$Process = Get-Process $ProcessName -ErrorAction SilentlyContinue
	$Process = $Process | Where-Object { $_.ProcessName -eq $ProcessName }
	Write-Host "Waiting for"$Process.Product"to complete....." -NoNewline
	If ($Process -ne $null) {
		Do {
			Start-Sleep -Seconds 2
			$Process = Get-Process $ProcessName -ErrorAction SilentlyContinue
			$Process = $Process | Where-Object { $_.ProcessName -eq $ProcessName }
		}
		While ($Process -ne $null)
		Write-Host "Completed" -ForegroundColor Yellow
	} else {
		Write-Host "Process already completed" -ForegroundColor Yellow
	}
}

cls

Set-ConsoleTitle -ConsoleTitle "SCCM Client"

If ($ClientInstallationDirectory -ne $null) {
	If ($ClientInstallationFile -ne $null) {
		If ($ClientInstallationDirectory[$ClientInstallationDirectory.Length - 1] -ne '\') {
			$ClientInstallationDirectory += '\'
		}
		
		$File = $ClientInstallationDirectory + $ClientInstallationFile
		
		$FileMetaData = Get-MetaData -FileName $File
	}
}

If ($Install.IsPresent) {
	
	$Parameters = "/uninstall"
	$InstallStatus = Invoke-EXE -Uninstall -DisplayName $FileMetaData.Product -Executable $File -Switches $Parameters
	If ($InstallStatus = $false) {
		$Failed = $true
	}
	
	$Parameters = ""
	If (($ManagementPoint -ne $null) -and ($ManagementPoint -ne "")) {
		$Parameters += "/mp:" + $ManagementPoint
	}
	If (($SMSSiteCode -ne $null) -and ($SMSSiteCode -ne "")) {
		If ($Parameters -ne "") {
			$Parameters += [char]32
		}
		$Parameters += "SMSSITECODE=" + $SMSSiteCode
	}
	If ($UsePKICert.IsPresent) {
		If ($Parameters -ne "") {
			$Parameters += [char]32
		}
		$Parameters += "/UsePKICert"
	}
	If ($NOCRLCheck.IsPresent) {
		If ($Parameters -ne "") {
			$Parameters += [char]32
		}
		$Parameters += "/NOCRLCheck"
	}
	If (($Source -ne $null) -and ($Source -ne "")) {
		If ($Parameters -ne "") {
			$Parameters += [char]32
		}
		$Parameters += "/source:" + [char]34 + $Source + [char]34
	}
	$InstallStatus = Invoke-EXE -Install -DisplayName $FileMetaData.Product -Executable $File -Switches $Parameters
	If ($InstallStatus -eq $false) {
		$Failed = $true
	}
	
} elseif ($Uninstall.IsPresent) {
	
	$Parameters = "/Uninstall"
	$InstallStatus = Invoke-EXE -Uninstall -DisplayName $FileMetaData.Product -Executable $File -Switches $Parameters
	If ($InstallStatus -eq $false) {
		$Failed = $true
	}
}

If ($Build.IsPresent) {
	
	$InstallStatus = Suspend-Service -Service ccmexec
	If ($InstallStatus -eq $false) {
		$Failed = $true
	}
	
	$InstallStatus = Remove-File -Filename $env:windir"\smscfg.ini"
	If ($InstallStatus -eq $false) {
		$Failed = $true
	}
	
	$InstallStatus = Remove-RegistryKey -RegistryKey "HKEY_LOCAL_MACHINE\Software\Microsoft\SystemCertificates\SMS\Certificates" -Recurse
	If ($InstallStatus -eq $false) {
		$Failed = $true
	}
}
If ($Failed -eq $true) {
	$wshell = New-Object -ComObject Wscript.Shell
	$wshell.Popup("Installation Failed", 0, "Installation Failed", 0x0)
	Exit 1
} else {
	Exit 0
}
