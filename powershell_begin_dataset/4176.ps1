
[CmdletBinding()]
param ()

function Get-Architecture {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$OSArchitecture = (Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture).OSArchitecture
	Return $OSArchitecture
	
}

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Install-MSIFile {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$File,
		[ValidateNotNullOrEmpty()][string]$Arguments
	)
	
	$RelativePath = Get-RelativePath
	$Executable = $env:windir + "\System32\msiexec.exe"
	$Parameters = "/i" + [char]32 + $File.Fullname + [char]32 + $Arguments
	Write-Host "Installing"($File.Name).Trim()"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		Write-Host "Success" -ForegroundColor Yellow
		Return $true
	} else {
		Write-Host "Failed" -ForegroundColor Red
		Return $false
	}
}


$Architecture = Get-Architecture

$RelativePath = Get-RelativePath

If ($Architecture -eq "32-bit") {
	$File = Get-ChildItem -Path $RelativePath -Filter *x86.msi
} else {
	$File = Get-ChildItem -Path $RelativePath -Filter *x64.msi
}

$Results = Install-MSIFile -File $File -Arguments "/qb- /norestart"
If ($Results -eq $true) {
	
	Install-PackageProvider nuget -Force -Verbose
	Exit 0
} else {
	Exit 1
}

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

Install-Module -Name ((Find-Module -Name DellBIOSProvider).Name) -Force -Verbose
