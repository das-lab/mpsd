Register-PSFConfigValidation -Name "stringarray" -ScriptBlock {
	Param (
		$Value
	)
	
	$Result = New-Object PSObject -Property @{
		Success  = $True
		Value    = $null
		Message  = ""
	}
	
	try
	{
		$data = @()
		
		foreach ($item in $Value)
		{
			$data += [string]$item
		}
	}
	catch
	{
		$Result.Message = "Not a string array: $Value"
		$Result.Success = $False
		return $Result
	}
	
	$Result.Value = $data
	
	return $Result
}