
[CmdletBinding()]
[OutputType([array])]
param
(
	[string[]]$Computername = 'localhost',
	[Parameter(ValueFromPipeline = $true,
			   ValueFromPipelineByPropertyName = $true)]
	[ValidatePattern('[A-Z]')]
	[string]$DriveLetter,
	[ValidateSet('KB','MB','GB','TB')]
	[string]$SizeOutputLabel = 'MB'
	
)

Begin {
	try {
		$WhereQuery = "SELECT FreeSpace,DeviceID FROM Win32_Logicaldisk"
		
		if ($PsBoundParameters.DriveLetter) {
			$WhereQuery += ' WHERE'
			$BuiltQueryParams = { @() }.Invoke()
			foreach ($Letter in $DriveLetter) {
				$BuiltQueryParams.Add("DeviceId = '$DriveLetter`:'")
			}
			$WhereQuery = "$WhereQuery $($BuiltQueryParams -join ' OR ')"
		}
		Write-Debug "Using WQL query $WhereQuery"
		$WmiParams = @{
			'Query' = $WhereQuery
			'ErrorVariable' = 'MyError';
			'ErrorAction' = 'SilentlyContinue'
		}
	} catch {
		Write-Error $_.Exception.Message
	}
}
Process {
	try {
		foreach ($Computer in $Computername) {
			$WmiParams.Computername = $Computer
			$WmiResult = Get-WmiObject @WmiParams
			if ($MyError) {
				throw $MyError
			}
			foreach ($Result in $WmiResult) {
				if ($Result.Freespace) {
					[pscustomobject]@{
						'Computername' = $Computer;
						'DriveLetter' = $Result.DeviceID;
						'Freespace' = [int]($Result.FreeSpace / "1$SizeOutputLabel")
					}
				}
			}
		}
	} catch {
		Write-Error $_.Exception.Message	
	}
	