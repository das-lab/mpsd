function ConvertTo-PSFClixml
{

	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "")]
	[CmdletBinding()]
	param (
		[int]
		$Depth,
		
		[Parameter(ValueFromPipeline = $true)]
		$InputObject,
		
		[PSFramework.Serialization.ClixmlDataStyle]
		$Style = 'String',
		
		[switch]
		$NoCompression
	)
	
	begin
	{
		$data = @()
	}
	process
	{
		$data += $InputObject
	}
	end
	{
		try
		{
			if ($Style -like 'Byte')
			{
				if ($NoCompression)
				{
					if ($Depth) { [PSFramework.Serialization.ClixmlSerializer]::ToByte($data, $Depth) }
					else { [PSFramework.Serialization.ClixmlSerializer]::ToByte($data) }
				}
				else
				{
					if ($Depth) { [PSFramework.Serialization.ClixmlSerializer]::ToByteCompressed($data, $Depth) }
					else { [PSFramework.Serialization.ClixmlSerializer]::ToByteCompressed($data) }
				}
			}
			else
			{
				if ($NoCompression)
				{
					if ($Depth) { [PSFramework.Serialization.ClixmlSerializer]::ToString($data, $Depth) }
					else { [PSFramework.Serialization.ClixmlSerializer]::ToString($data) }
				}
				else
				{
					if ($Depth) { [PSFramework.Serialization.ClixmlSerializer]::ToStringCompressed($data, $Depth) }
					else { [PSFramework.Serialization.ClixmlSerializer]::ToStringCompressed($data) }
				}
			}
		}
		catch
		{
			Stop-PSFFunction -Message "Failed to export object" -ErrorRecord $_ -EnableException $true -Target $resolvedPath -Cmdlet $PSCmdlet
		}
	}
}