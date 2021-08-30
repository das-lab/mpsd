
[CmdletBinding()]
param
(
	[string]
	$DomainUserName,
	[string]
	$DomainPassword,
	[string]
	$NetworkPath,
	[string]
	$DriveLetter
)

function Copy-Folder {

	
	[CmdletBinding()]
	param
	(
		[string]
		$SourceFolder,
		[string]
		$DestinationFolder
	)
	
	$Executable = $env:windir + "\system32\Robocopy.exe"
	$Switches = $SourceFolder + [char]32 + $DestinationFolder + [char]32 + "/e /eta /mir"
	Write-Host "Copying "$SourceFolder"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 1)) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code"$ErrCode -ForegroundColor Red
	}
}

function Get-Architecture {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$OSArchitecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
	$OSArchitecture = $OSArchitecture.OSArchitecture
	Return $OSArchitecture
	
}


function New-NetworkDrive {

	
	[CmdletBinding()]
	param ()
	
	$Executable = $env:windir + "\system32\net.exe"
	$Switches = "use" + [char]32 + $DriveLetter + ":" + [char]32 + $NetworkPath + [char]32 + "/user:" + $DomainUserName + [char]32 + $DomainPassword
	Write-Host "Mapping"$DriveLetter":\ drive....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	If ((Test-Path $DriveLetter":\") -eq $true) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed" -ForegroundColor Yellow
	}
}

function Remove-NetworkDrive {

	
	[CmdletBinding()]
	param ()
	
	$Executable = $env:windir + "\system32\net.exe"
	$Switches = "use" + [char]32 + $DriveLetter + ":" + [char]32 + "/delete"
	Write-Host "Deleting"$DriveLetter":\ drive....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	If ((Test-Path $DriveLetter":\") -eq $true) {
		Write-Host "Failed" -ForegroundColor Yellow
	} else {
		Write-Host "Success" -ForegroundColor Yellow
	}
}

cls

$Architecture = Get-Architecture

New-NetworkDrive

$MicrosoftWindowsIvecenterResources = Get-ChildItem $DriveLetter":\" | where { $_.Attributes -eq 'Directory' } | Where-Object { $_.FullName -like "*msil_microsoft-windows-d..ivecenter.resources*" }

$WinSxSMicrosoftActiveDirectoryManagementResources = Get-ChildItem $DriveLetter":\" | where { $_.Attributes -eq 'Directory' } | Where-Object { $_.FullName -like "*x86_microsoft.activedirectory.management*" }

$WinSxSMicrosoftActiveDirectoryManagementResources_x64 = Get-ChildItem $DriveLetter":\" | where { $_.Attributes -eq 'Directory' } | Where-Object { $_.FullName -like "*amd64_microsoft.activedir..anagement.resources*" }


Copy-Folder -SourceFolder $NetworkPath"\ActiveDirectory" -DestinationFolder $env:windir"\System32\WindowsPowerShell\v1.0\Modules\ActiveDirectory"

Copy-Folder -SourceFolder $NetworkPath"\Microsoft.ActiveDirectory.Management" -DestinationFolder $env:windir"\Microsoft.NET\assembly\GAC_32\Microsoft.ActiveDirectory.Management"

Copy-Folder -SourceFolder $NetworkPath"\Microsoft.ActiveDirectory.Management.Resources" -DestinationFolder $env:windir"\Microsoft.NET\assembly\GAC_32\Microsoft.ActiveDirectory.Management.Resources"

Copy-Folder -SourceFolder $NetworkPath"\"$MicrosoftWindowsIvecenterResources -DestinationFolder $env:windir"\WinSxS\"$MicrosoftWindowsIvecenterResources

Copy-Folder -SourceFolder $NetworkPath"\"$WinSxSMicrosoftActiveDirectoryManagementResources -DestinationFolder $env:windir"WinSxS\"$WinSxSMicrosoftActiveDirectoryManagementResources

If ($Architecture -eq "64-bit") {
	
	Copy-Folder -SourceFolder $NetworkPath"\ActiveDirectory" -DestinationFolder $env:SystemDrive"\"
	
	Copy-Folder -SourceFolder $NetworkPath"\Microsoft.ActiveDirectory.Management" -DestinationFolder $env:windir"\Microsoft.NET\assembly\GAC_64\Microsoft.ActiveDirectory.Management"
	
	Copy-Folder -SourceFolder $NetworkPath"\Microsoft.ActiveDirectory.Management.Resources" -DestinationFolder $env:windir"\Microsoft.NET\assembly\GAC_64\Microsoft.ActiveDirectory.Management.Resources"
	
	Copy-Folder -SourceFolder $NetworkPath"\"$WinSxSMicrosoftActiveDirectoryManagementResources_x64 -DestinationFolder $env:windir"\WinSxS\"$WinSxSMicrosoftActiveDirectoryManagementResources_x64
}


Remove-NetworkDrive
