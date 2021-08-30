


[CmdletBinding()]
[OutputType('Selected.Microsoft.Management.Infrastructure.CimInstance')]
param ()
process {
	try {
		Get-ScheduledTask | Select-Object TaskName,Author, @{ 'n' = 'CreationDate'; 'e' = { [datetime]$_.Date } }
	} catch {
		Write-Error "$($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
	}
}