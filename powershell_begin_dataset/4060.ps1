
[CmdletBinding()]
param
(
	[string]$Parameters = 'INSTALL_SILENT=Enable AUTO_UPDATE=Disable WEB_JAVA=Enable WEB_ANALYTICS=Disable EULA=Disable REBOOT=Disable'
)

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

function Install-EXE {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$DisplayName,
		[ValidateNotNullOrEmpty()][string]$Executable,
		[ValidateNotNullOrEmpty()][string]$Switches
	)
	
	Write-Host "Install"$DisplayName.Trim()"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		Exit $ErrCode
	}
}

function Uninstall-MSIByName {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][String]$ApplicationName,
		[ValidateNotNullOrEmpty()][String]$Switches
	)
	
	
	$Executable = $Env:windir + "\system32\msiexec.exe"
	Do {
		
		$Uninstall =  Get-ChildItem REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ErrorAction SilentlyContinue -Force
		$Uninstall += Get-ChildItem REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ErrorAction SilentlyContinue
		
		$Key = $uninstall | foreach-object { Get-ItemProperty REGISTRY::$_ -ErrorAction SilentlyContinue} | where-object { $_.DisplayName -like "*$ApplicationName*" }
		If ($Key -ne $null) {
			Write-Host "Uninstall"$Key[0].DisplayName"....." -NoNewline
			
			$Parameters = "/x " + $Key[0].PSChildName + [char]32 + $Switches
			
			$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
			
			If (($ErrCode -eq 0) -or ($ErrCode -eq 3010) -or ($ErrCode -eq 1605)) {
				Write-Host "Success" -ForegroundColor Yellow
			} else {
				Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
			}
		}
	} While ($Key -ne $null)
}

$Architecture = Get-Architecture
$RelativePath = Get-RelativePath

Uninstall-MSIByName -ApplicationName "Java 6" -Switches "/qb- /norestart"
Uninstall-MSIByName -ApplicationName "Java 7" -Switches "/qb- /norestart"
Uninstall-MSIByName -ApplicationName "Java 8" -Switches "/qb- /norestart"
$Javax86 = $RelativePath + (Get-ChildItem -Path $RelativePath -Filter "*i586*").Name
$Javax64 = $RelativePath + (Get-ChildItem -Path $RelativePath -Filter "*x64*").Name
If ($Architecture -eq "32-Bit") {
	Install-EXE -DisplayName "Java Runtime Environment x86" -Executable $Javax86 -Switches $Parameters
} else {
	Install-EXE -DisplayName "Java Runtime Environment x86" -Executable $Javax86 -Switches $Parameters
	Install-EXE -DisplayName "Java Runtime Environment x64" -Executable $Javax64 -Switches $Parameters
	
}
