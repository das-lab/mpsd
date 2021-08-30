function ConvertFrom-PSFArray
{

	[CmdletBinding()]
	param (
		[Parameter(Position = 0)]
		[string]
		$JoinBy = ', ',
		
		[Parameter(Position = 1)]
		[string[]]
		$PropertyName = '*',
		
		[Parameter(ValueFromPipeline = $true)]
		$InputObject
	)
	
	process
	{
		$props = [ordered]@{ }
		foreach ($property in $InputObject.PSObject.Properties)
		{
			
			if ($property.Value -isnot [System.Collections.ICollection])
			{
				$props[$property.Name] = $property.Value
				continue
			}
			
			
			
			$found = $false
			foreach ($name in $PropertyName)
			{
				if ($property.Name -like $name)
				{
					$found = $true
					break
				}
			}
			if (-not $found)
			{
				$props[$property.Name] = $property.Value
				continue
			}
			
			
			$props[$property.Name] = $property.Value -join $JoinBy
		}
		[PSCustomObject]$props
	}
}