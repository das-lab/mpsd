

[CmdletBinding()]
param ()

function Uninstall-MSIbyGUID {

	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][String]$GUID,
		[ValidateNotNullOrEmpty()][String]$Switches
	)
	
	[string]$DisplayName = ((Get-ChildItem -Path REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products).Name | Foreach-object { Get-ChildItem REGISTRY::$_ } | ForEach-Object { If ($_ -like "*InstallProperties*") { Get-ItemProperty -path REGISTRY::$_ } } | Where-Object { $_.UninstallString -like "*" + $GUID + "*" }).DisplayName
	If (($DisplayName -ne "") -and ($DisplayName -ne $null)) {
		$Executable = $Env:windir + "\system32\msiexec.exe"
		$Parameters = "/x" + [char]32 + $GUID + [char]32 + $Switches
		Write-Host "Uninstall"$DisplayName.Trim()"....." -NoNewline
		$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
		If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
			Write-Host "Success" -ForegroundColor Yellow
		} elseIf ($ErrCode -eq 1605) {
			Write-Host "Not Present" -ForegroundColor Green
		} else {
			Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
			Exit $ErrCode
		}
	}
}


Uninstall-MSIbyGUID -GUID "{26A24AE4-039D-4CA4-87B4-2F32180161F0}" -Switches "/qb- /norestart"
