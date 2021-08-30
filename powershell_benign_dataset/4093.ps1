

cls
$Printers = Get-WmiObject Win32_Printer
$EXE = $env:windir + "\system32\printui.exe"
$PrintUI = "/dn /n "
Foreach ($Printer in $Printers) {
	If ($Printer.ShareName -ne $null) {
		Write-Host "Uninstall"$Printer.ShareName"....." -NoNewline
		$Parameters = $PrintUI + [char]34+ $Printer.Name + [char]34
		$ErrCode = (Start-Process -FilePath $EXE -ArgumentList $Parameters -Wait -Passthru).ExitCode
		If ($ErrCode -eq 0) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
		}
	}
}
