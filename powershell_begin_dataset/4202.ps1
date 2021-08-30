
[CmdletBinding()]
param
(
		[string]$LogFileLocation,
		[string]$LogFileName,
		[string]$EventLogName,
		[string]$LogMessage
)


Set-Variable -Name Logs -Value $null -Scope Local -Force

cls
$ReportFile = $LogFileLocation + $LogFileName
$LogMessage = [char]42 + $LogMessage + [char]42
$Logs = Get-EventLog -LogName $EventLogName | where { $_.Message -like $LogMessage }
If ($Logs -ne $null) {
	$Logs
	Do {
		Try {
			$Written = $true
			Out-File -FilePath $ReportFile -InputObject $env:COMPUTERNAME -Append -Encoding UTF8 -ErrorAction SilentlyContinue
		} Catch {
			Start-Sleep -Seconds 1
			$Written = $false
		}
	} while ($Written -eq $false)
}
