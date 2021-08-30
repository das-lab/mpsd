

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
	Do {
		
		$Uninstall = Get-ChildItem REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ErrorAction SilentlyContinue -Force
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


Uninstall-MSIByName -ApplicationName "Java 8" -Switches "/qb- /norestart"
