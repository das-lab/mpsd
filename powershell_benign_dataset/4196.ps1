
param
(
		[string]$ApplicationName = 'quicktime',
		[string]$WindowTitle = 'Uninstall Apple Quicktime',
		[string]$MSI_Switches = '/qb- /norestart'
)

function Set-ConsoleTitle {

	
	[CmdletBinding()]
	param
	(
			[Parameter(Mandatory = $true)][String]$Title
	)
	
	$host.ui.RawUI.WindowTitle = $Title
}


Function InitializeVariables {
	$Global:BuildLog = $Env:windir + "\Waller\Logs\BuildLogs\Build.csv"
	$Global:Errors = $null
	$Global:LogFile = $Env:windir + "\Waller\Logs\BuildLogs\AppleQuicktime.log"
	$Global:Phase = "Software Deployment"
	$Global:RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
}

function Uninstall-MSIByName {

	
	[CmdletBinding()]
	param ()
	
	$Uninstall = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ErrorAction SilentlyContinue
	$Uninstall += Get-ChildItem HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ErrorAction SilentlyContinue
	$SearchName = "*" + $ApplicationName + "*"
	$Executable = $Env:windir + "\system32\msiexec.exe"
	Foreach ($Key in $Uninstall) {
		$TempKey = $Key.Name -split "\\"
		If ($TempKey[002] -eq "Microsoft") {
			$Key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" + $Key.PSChildName
		} else {
			$Key = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" + $Key.PSChildName
		}
		If ((Test-Path $Key) -eq $true) {
			$KeyName = Get-ItemProperty -Path $Key
			If ($KeyName.DisplayName -like $SearchName) {
				$TempKey = $KeyName.UninstallString -split " "
				If ($TempKey[0] -eq "MsiExec.exe") {
					Write-Host "Uninstall"$KeyName.DisplayName"....." -NoNewline
					$Parameters = "/x " + $KeyName.PSChildName + [char]32 + $MSI_Switches
					$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
					If (($ErrCode -eq 0) -or ($ErrCode -eq 3010) -or ($ErrCode -eq 1605)) {
						Write-Host "Success" -ForegroundColor Yellow
					} else {
						Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
					}
				}
			}
		}
	}
}

Clear-Host
Set-ConsoleTitle -Title $WindowTitle
Uninstall-MSIByName
Exit-PowerShell
