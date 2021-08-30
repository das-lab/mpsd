function Out-Excel
{

	[CmdletBinding()]
	PARAM ([string[]]$property, [switch]$raw)

	BEGIN
	{
		
		$Excel = New-Object -Com Excel.Application
		$Excel.visible = $True
		$Excel = $Excel.Workbooks.Add()
		$Sheet = $Excel.Worksheets.Item(1)
		
		
		$Row = 1
		$HeaderHash = @{ }
	}

	PROCESS
	{
		if ($_ -eq $null) { return }
		if ($Row -eq 1)
		{
			
			if (-not $property)
			{
				
				
				$property = @()
				if ($raw)
				{
					$_.properties.PropertyNames | ForEach-Object{ $property += @($_) }
				}
				else
				{
					$_.PsObject.get_properties() | ForEach-Object { $property += @($_.Name.ToString()) }
				}
			}
			$Column = 1
			foreach ($header in $property)
			{
				
				
				
				$HeaderHash[$header] = $Column
				$Sheet.Cells.Item($Row, $Column) = $header.toupper()
				$Column++
			}
			
			$WorkBook = $Sheet.UsedRange
			$WorkBook.Interior.ColorIndex = 19
			$WorkBook.Font.ColorIndex = 11
			$WorkBook.Font.Bold = $True
			$WorkBook.HorizontalAlignment = -4108
		}
		$Row++
		foreach ($header in $property)
		{
			
			
			
			
			if ($thisColumn = $HeaderHash[$header])
			{
				if ($raw)
				{
					$Sheet.Cells.Item($Row, $thisColumn) = [string]$_.properties.$header
				}
				else
				{
					$Sheet.Cells.Item($Row, $thisColumn) = [string]$_.$header
				}
			}
		}
	}

	end
	{
		
		if ($Row -gt 1) { [void]$WorkBook.EntireColumn.AutoFit() }
	}
}