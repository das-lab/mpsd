

$MasterLog = "\\NetworkLocation\LocalAdministrators.csv"
$Files = Get-ChildItem -Path \\NetworkLocation -Force
If ((Test-Path $MasterLog) -eq $true) {
	Remove-Item -Path $MasterLog -Force
}
If ((Test-Path $MasterLog) -eq $false) {
	$TitleBar = "ComputerName,UserName"+[char]13
	New-Item -Path $MasterLog -ItemType File -Value $TitleBar -Force
}
Foreach ($File in $Files) {
	If ($File.Extension -eq ".log") {
		$Usernames = Get-Content -Path $File.FullName
		Foreach ($Username in $Usernames) {
			$Entry = $File.BaseName+","+$Username
			Add-Content -Path $MasterLog -Value $Entry -Force
		}
	}
}

























