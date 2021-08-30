
[CmdletBinding()]
param ()
function Get-Architecture {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$OSArchitecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
	$OSArchitecture = $OSArchitecture.OSArchitecture
	Return $OSArchitecture
	
}

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Install-MSUFile {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$FileName
	)
	
	$RelativePath = Get-RelativePath
	$Executable = $env:windir + "\System32\wusa.exe"
	$Parameters = $RelativePath + $FileName + [char]32 + "/quiet /norestart"
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
	Return $ErrCode
}

$Architecture = Get-Architecture
If ($Architecture -eq "32-Bit") {
	$ReturnCode = Install-MSUFile -FileName Windows6.1-KB4019990-x86.msu
} else {
	$ReturnCode = Install-MSUFile -FileName Windows6.1-KB4019990-x64.msu
}



If ($ReturnCode -eq 2359301) {
	$ReturnCode = 3010
}
If ($ReturnCode -eq 2359302) {
	$ReturnCode = 0
}
$ReturnCode
Exit $ReturnCode
