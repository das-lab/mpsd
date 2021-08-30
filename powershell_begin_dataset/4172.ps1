

cls
$File = Get-Content -Path "C:\Users\Mick\Desktop\BDD.log" -Force
Foreach ($Entry in $File) {
	If (($Entry -like '*INSTALL - *') -and ($Entry -like '*ZTIWindowsUpdate*')) {
		
		$SplitLine = $Entry.Split('KB')
		$Update = $SplitLine[2]
		$Update = $Update.Split(')')
		$Update = $Update.Split('(')
		Write-Host "KB"$Update[0]
	}
}

Remove-Variable -Name Entry -Force
Remove-Variable -Name File -Force
Remove-Variable -Name Update -Force