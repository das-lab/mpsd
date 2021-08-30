
[CmdletBinding()]
param (
	[Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
	[string[]]$ServiceName,
	[Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
	[ValidateScript({Test-Connection -ComputerName $_ -Quiet -Count 1 })]
	[string[]]$Computername = 'localhost',
	[Parameter(Mandatory)]
	[string]$Username,
	[Parameter(Mandatory)]
	[string]$Password
)

process {
	foreach ($Computer in $Computername) {
		foreach ($Service in $ServiceName) {
			try {
				Write-Verbose -Message "Changing service '$Service' on the computer '$Computer'"
				$s = Get-WmiObject -ComputerName $Computer -Class Win32_Service -Filter "Name = '$Service'"
				if (!$s) {
					throw "The service '$Service' does not exist"
				}
				$s.Change($null, $null, $null, $null, $null, $null, $Username, $Password) | Out-Null
				$s | Restart-Service -Force
			} catch {
				Write-Error -Message "Error: Computer: $Computer - Service: $Service - Error: $($_.Exception.Message)"	
			}
		}
	}
}