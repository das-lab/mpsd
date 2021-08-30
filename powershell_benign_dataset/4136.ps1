
[CmdletBinding()]
param ()

function Uninstall-MSIByName {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][String]$ApplicationName,
		[ValidateNotNullOrEmpty()][String]$Switches
	)
	
	
	$Executable = $Env:windir + "\system32\msiexec.exe"
	
	$Uninstall = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ErrorAction SilentlyContinue
	If (((Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture).OSArchitecture) -eq "64-Bit") {
		$Uninstall += Get-ChildItem HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ErrorAction SilentlyContinue
	}
	
	$Key = $uninstall | foreach-object { Get-ItemProperty REGISTRY::$_ } | where-object { $_.DisplayName -like "*$ApplicationName*" }
	If ($Key -ne $null) {
		Write-Host "Uninstall"$Key.DisplayName"....." -NoNewline
		
		$Parameters = "/x " + $Key.PSChildName + [char]32 + $Switches
		
		$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
		
		If (($ErrCode -eq 0) -or ($ErrCode -eq 3010) -or ($ErrCode -eq 1605)) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		}
	}
}

Uninstall-MSIByName -ApplicationName "Adobe Acrobat" -Switches "/qb- /norestart"
Uninstall-MSIByName -ApplicationName "Adobe Reader" -Switches "/qb- /norestart"
