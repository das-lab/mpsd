
[CmdletBinding()]
param
(
	[string]$BIOSPassword = $null
)

function Get-Architecture {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	
	$OSArchitecture = (Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture).OSArchitecture
	Return $OSArchitecture
}

function Get-BIOSPasswordStatus {

	
	[CmdletBinding()][OutputType([boolean])]
	param ()
	
	$Architecture = Get-Architecture
	
	If ($Architecture -eq "32-Bit") {
		$File = Get-ChildItem ${Env:ProgramFiles(x86)}"\Dell\" -Filter cctk.exe -Recurse | Where-Object { $_.Directory -notlike "*x86_64*" }
	} else {
		$File = Get-ChildItem ${Env:ProgramFiles(x86)}"\Dell\" -Filter cctk.exe -Recurse | Where-Object { $_.Directory -like "*x86_64*" }
	}
	$cmd = [char]38 + [char]32 + [char]34 + $file.FullName + [char]34 + [char]32 + "--setuppwd=" + $BIOSPassword
	$Output = Invoke-Expression $cmd
	
	If ($Output -like "*The old password must be provided to set a new password using*") {
		Return $true
	}
	
	If ($Output -like "*Password is set successfully*") {
		$cmd = [char]38 + [char]32 + [char]34 + $file.FullName + [char]34 + [char]32 + "--setuppwd=" + [char]32 + "--valsetuppwd=" + $BIOSPassword
		$Output = Invoke-Expression $cmd
		Return $false
	}
}

function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Install-BIOSUpdate {

	
	[CmdletBinding()]
	param ()
	
	$BIOSLocation = Get-RelativePath
	$Model = ((Get-WmiObject Win32_ComputerSystem).Model).split(" ")[1]
	$File = Get-ChildItem -Path $BIOSLocation | Where-Object { $_.Name -like "*"+$Model+"*" } | Get-ChildItem -Filter *.exe
	
	If ($File -ne $null) {
		
		If ($File -like "*"+$Model+"*") {
			
			$BIOSPasswordSet = Get-BIOSPasswordStatus
			If ($BIOSPasswordSet -eq $false) {
				$Arguments = "/f /s /l=" + $env:windir + "\waller\Logs\ApplicationLogs\BIOS.log"
			} else {
				$Arguments = "/f /s /p=" + $BIOSPassword + [char]32 + "/l=" + $env:windir + "\waller\Logs\ApplicationLogs\BIOS.log"
			}
			
			$ErrCode = (Start-Process -FilePath $File.FullName -ArgumentList $Arguments -Wait -PassThru).ExitCode
			If (($ErrCode -eq 0) -or ($ErrCode -eq 2)) {
				Exit 3010
			} else {
				Exit $ErrCode
			}
		} else {
			Exit 1
		}
	} else {
		Exit 1
	}
}




Install-BIOSUpdate
