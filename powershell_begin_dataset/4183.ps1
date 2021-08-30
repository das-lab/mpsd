



Set-Variable -Name CurrentTime -Scope Local -Force
Set-Variable -Name Difference -Scope Local -Force
Set-Variable -Name Output1 -Scope Local -Force
Set-Variable -Name Output2 -Scope Local -Force
Set-Variable -Name Output3 -Scope Local -Force
Set-Variable -Name Process -Value $null -Scope Local -Force
Set-Variable -Name StartTime -Scope Local -Force

Clear-Host
$StartTime = Get-Date
$Output1 = "Waiting for Bitlocker Encryption to begin....."
$Output1
While ($Process -eq $null) {
	Start-Sleep -Seconds 5
	$Process = Get-Process -Name fvenotify -ErrorAction SilentlyContinue
	$CurrentTime = Get-Date
	$Difference = (New-TimeSpan -Start $StartTime -End $CurrentTime).minutes
	If ($Difference -eq 5) {
		Exit 1
	}
}
$Output1 = $Output1 + "Completed"
Clear-Host
$Output1
$Output2 = "Bitlockering System....."
$Output2
while ($Process -ne $null) {
	$Process = $null
	$Process = Get-Process -Name fvenotify -ErrorAction SilentlyContinue
	$Output3 = manage-bde -status $env:HOMEDRIVE
	Clear-Host
	$Output1
	$Output2
	Write-Host
	$Output3[9].TRIM()
	Start-Sleep -Seconds 60
}
Write-Host "Complete" -ForegroundColor Yellow


Remove-Variable -Name CurrentTime -Scope Local -Force
Remove-Variable -Name Difference -Scope Local -Force
Remove-Variable -Name Output1 -Scope Local -Force
Remove-Variable -Name Output2 -Scope Local -Force
Remove-Variable -Name Output3 -Scope Local -Force
Remove-Variable -Name Process -Scope Local -Force
Remove-Variable -Name StartTime -Scope Local -Force
