function Get-VMError
{
	
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory, ValueFromPipelineByPropertyName)]
		[ValidateNotNullOrEmpty()]
		[Alias('ComputerName')]
		[string]$Server,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[pscredential]$Credential
	)
	
		$whereFilter = { $_.TimeCreated -gt (Get-Date).AddDays(-1) -and ($_.LevelDisplayName -in @('Error', 'Critical')) }
		
		$properties = @('Machinename', 'TimeCreated', 'LevelDisplayName', 'Message')
		$winParams = @{
			'ComputerName' = $Server
			'LogName' = 'Microsoft-Windows-Hyper-V-*'
		}
		if ($PSBoundParameters.ContainsKey('Credential')) {
			$winParams.Credential = $Credential
		}
		Get-WinEvent @winParams | where -FilterScript $whereFilter | Select $properties
}