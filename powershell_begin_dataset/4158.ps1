


Set-Variable -Name DefaultPrinter -Scope Global -Force

cls
If ((Test-Path $env:APPDATA"\DefaultPrinter.txt") -eq $true) {
	Remove-Item -Path $env:APPDATA"\DefaultPrinter.txt" -Force
}
$DefaultPrinter = Get-WmiObject -Class win32_printer -ComputerName "localhost" -Filter "Default='true'" | Select-Object ShareName
Write-Host "Default Printer: " -NoNewline
If ($DefaultPrinter.ShareName -ne $null) {
	$DefaultPrinter.ShareName | Out-File -FilePath $env:APPDATA"\DefaultPrinter.txt" -Force -Encoding "ASCII"
	Write-Host $DefaultPrinter.ShareName
} else {
	$DefaultPrinter = "No Default Printer"
	$DefaultPrinter | Out-File -FilePath $env:APPDATA"\DefaultPrinter.txt" -Force -Encoding "ASCII"
	Write-Host $DefaultPrinter
}


Remove-Variable -Name DefaultPrinter -Scope Global -Force

























