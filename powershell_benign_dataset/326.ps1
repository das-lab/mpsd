function Select-PSFPropertyValue
{

	[CmdletBinding(DefaultParameterSetName = 'Default')]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string[]]
		$Property,
		
		[Parameter(ParameterSetName = 'Fallback')]
		[switch]
		$Fallback,
		
		[Parameter(ParameterSetName = 'Select')]
		[ValidateSet('Lowest', 'Largest')]
		[string]
		$Select,
		
		[Parameter(ParameterSetName = 'Join')]
		[string]
		$JoinBy,
		
		[Parameter(ParameterSetName = 'Format')]
		[string]
		$FormatWith,
		
		[Parameter(ValueFromPipeline = $true)]
		$InputObject
	)
	
	process
	{
		foreach ($object in $InputObject)
		{
			switch ($PSCmdlet.ParameterSetName)
			{
				'Default'
				{
					foreach ($prop in $Property)
					{
						$object.$Prop
					}
				}
				'Fallback'
				{
					foreach ($prop in $Property)
					{
						if ($null -ne ($object.$Prop | Remove-PSFNull -Enumerate))
						{
							$object.$prop
							break
						}
					}
				}
				'Select'
				{
					$values = @()
					foreach ($prop in $Property)
					{
						$values += $object.$Prop
					}
					if ($Select -eq 'Largest') { $values | Sort-Object -Descending | Select-Object -First 1 }
					else { $values | Sort-Object | Select-Object -First 1 }
					
				}
				'Join'
				{
					$values = @()
					foreach ($prop in $Property)
					{
						$values += $object.$Prop
					}
					$values -join $JoinBy
				}
				'Format'
				{
					$values = @()
					foreach ($prop in $Property)
					{
						$values += $object.$Prop
					}
					$FormatWith -f $values
				}
			}
		}
	}
}