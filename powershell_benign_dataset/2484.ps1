function Get-MyCimInstance {
	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, ValueFromPipeline)]
		[string[]]$Computername,
		[Parameter(Mandatory)]
		[Alias('ClassName')]
		[string]$Class,
		[Parameter()]
		[string]$Namespace,
		[Parameter()]
		[string]$Filter,
		[Parameter()]
		[string]$Property
	)
	process {
		
		$ErrorActionBefore = $ErrorActionPreference
		$ErrorActionPreference = 'SilentlyContinue'
		foreach ($Computer in $Computername) {
			try {
				
				$Params = @{ 'Computername' = $Computer; 'Class' = $Class; 'ErrorAction' = 'SilentlyContinue' }
				if ($PsBoundParameters.Property) {
					$Params.Property = $PsBoundParameters.Property
				}
				if ($Filter) {
					$Params.Filter = $Filter
				}
				if ($Namespace) {
					$Params.Namespace = $Namespace
				}
				Write-Verbose "Attempting to query '$Computer' via WinRM"
				$Result = Get-CimInstance @Params -ev WinRmError
				if ($WinRmError) {
					Write-Verbose "Failed to query $Computer via WinRM. Attempting with DCOM"
					
					$GwmiParams = @{ 'Computername' = $Computer; 'Class' = $Class; 'ErrorAction' = 'SilentlyContinue' }
					if ($Filter) {
						$GwmiParams.Filter = $Filter
					}
					if ($Namespace) {
						$GwmiParams.Namespace = $Namespace
					}
					if ($Property) {
						$GwmiParams.Property = $Property
					}
					$Result = Get-WmiObject @GwmiParams -ev DcomError
					if ($DcomError) {
						throw 'Failed query via DCOM. Giving up.'
					} else {
						$ErrorActionPreference = $ErrorActionBefore
						$Result
					}
				} else {
					$ErrorActionPreference = $ErrorActionBefore
					$Result
				}
			} catch {
				$ErrorActionPreference = $ErrorActionBefore
				Write-Error "$($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
			}
		}
		
	}
}