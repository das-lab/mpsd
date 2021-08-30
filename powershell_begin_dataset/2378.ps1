
[CmdletBinding()]
param (
	[Parameter(ValueFromPipeline,
		ValueFromPipelineByPropertyName)]
	[string]$Computername = 'localhost'
)

begin {
	Set-StrictMode -Version Latest
}

process {
	try {
		$WmiResult = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName
		$LastBoot = $WmiResult.ConvertToDateTime($WmiResult.LastBootupTime)
		$ObjParams = [ordered]@{'Computername' = $Computername }
		((Get-Date) - $LastBoot).psobject.properties | foreach { $ObjParams[$_.Name] = $_.Value }
		New-Object -TypeName PSObject -Property $ObjParams
	} catch {
		Write-Error $_.Exception.Message	
	}
}

end {
	
}