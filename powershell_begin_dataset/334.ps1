function Compare-PSFArray
{
    
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "")]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[object[]]
		$ReferenceObject,
		
		[Parameter(Mandatory = $true, Position = 1)]
		[object[]]
		$DifferenceObject,
		
		[switch]
		$OrderSpecific,
		
		[switch]
		$Quiet
	)
	
	process
	{
		
		if (-not $OrderSpecific)
		{
			$delta = Compare-Object -ReferenceObject $ReferenceObject -DifferenceObject $DifferenceObject
			if ($delta)
			{
				if ($Quiet) { return $false }
				[PSCustomObject]@{
					ReferenceObject  = $ReferenceObject
					DifferenceObject = $DifferenceObject
					Delta		     = $delta
					IsEqual		     = $false
				}
				return
			}
			else
			{
				if ($Quiet) { return $true }
				[PSCustomObject]@{
					ReferenceObject  = $ReferenceObject
					DifferenceObject = $DifferenceObject
					Delta		     = $delta
					IsEqual		     = $true
				}
				return
			}
		}
		
		
		
		else
		{
			if ($Quiet -and ($ReferenceObject.Count -ne $DifferenceObject.Count)) { return $false }
			$result = [PSCustomObject]@{
				ReferenceObject  = $ReferenceObject
				DifferenceObject = $DifferenceObject
				Delta		     = @()
				IsEqual		     = $true
			}
			
			$maxCount = [math]::Max($ReferenceObject.Count, $DifferenceObject.Count)
			[System.Collections.ArrayList]$indexes = @()
			
			foreach ($number in (0 .. ($maxCount - 1)))
			{
				if ($number -ge $ReferenceObject.Count)
				{
					$null = $indexes.Add($number)
					continue
				}
				if ($number -ge $DifferenceObject.Count)
				{
					$null = $indexes.Add($number)
					continue
				}
				if ($ReferenceObject[$number] -ne $DifferenceObject[$number])
				{
					if ($Quiet) { return $false }
					$null = $indexes.Add($number)
					continue
				}
			}
			
			if ($indexes.Count -gt 0)
			{
				$result.IsEqual = $false
				$result.Delta = $indexes.ToArray()
			}
			
			$result
		}
		
	}
}
