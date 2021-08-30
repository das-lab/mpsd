
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()][string]$PrinterName
)

Clear-Host

$Files = Get-ChildItem -Path $env:windir"\system32\spool\printers" -Filter *.SHD

$DeleteFiles = @()
foreach ($File in $Files) {
	
	$Contents = [System.IO.File]::ReadAllBytes($File.FullName)
	
	$Contents = $Contents | Where-Object { (($_ -ge 65) -and ($_ -le 90)) -or (($_ -ge 97) -and ($_ -le 122)) }
	
	foreach ($Value in $Contents) {
		$Output += [char]$Value
	}
	
	If ($Output -like "*$PrinterName*") {
		$DeleteFiles += $File.BaseName
	}
}

foreach ($File in $DeleteFiles) {
	
	Stop-Service -Name Spooler -Force | Out-Null
	
	$FileFilter = $File + ".*"
	
	$Filenames = Get-ChildItem -Path $env:windir"\system32\spool\printers" -Filter $FileFilter
	
	foreach ($Filename in $Filenames) {
		Remove-Item -Path $Filename.FullName -Force | Out-Null
	}
	
	Start-Service -Name Spooler | Out-Null
}
