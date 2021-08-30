


Set-Variable -Name Now -Force
Set-Variable -Name Log -Force

$Log = $Env:windir + "\Logs"
$File = $Log + "\" + "NotRebooted.log"
If (Test-Path $File) {
	$Now = Get-Date -Format "dd-MMM-yyyy"
	$Now = $Now + ".log"
	If (Test-Path -Path $File) {
		Remove-Item $File -Force
		$File = $Log + "\Rebooted---" + $Now
		New-Item $File -ItemType File -Force
	}
}
