function ConvertFrom-PSFClixml
{

	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline = $true, Mandatory = $true)]
		$InputObject
	)
	
	begin
	{
		$byteList = New-Object System.Collections.ArrayList
		
		function Convert-Item
		{
			[CmdletBinding()]
			param (
				$Data
			)
			
			if ($Data -is [System.String])
			{
				try { [PSFramework.Serialization.ClixmlSerializer]::FromStringCompressed($Data) }
				catch { [PSFramework.Serialization.ClixmlSerializer]::FromString($Data) }
			}
			else
			{
				try { [PSFramework.Serialization.ClixmlSerializer]::FromByteCompressed($Data) }
				catch { [PSFramework.Serialization.ClixmlSerializer]::FromByte($Data) }
			}
		}
	}
	process
	{
		if ($InputObject -is [string]) { Convert-Item -Data $InputObject }
		elseif ($InputObject -is [System.Byte[]]) { Convert-Item -Data $InputObject }
		elseif ($InputObject -is [System.Byte]) { $null = $byteList.Add($InputObject) }
		else { Stop-PSFFunction -Message "Unsupported input! Provide either a string or byte-array that previously were serialized from objects in powershell" -EnableException $true }
	}
	end
	{
		if ($byteList.Count -gt 0)
		{
			Convert-Item -Data ([System.Byte[]]$byteList.ToArray())
		}
	}
}