function Export-PSFClixml
{

	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Export-PSFClixml')]
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string]
		$Path,
		
		[int]
		$Depth,
		
		[Parameter(ValueFromPipeline = $true)]
		$InputObject,
		
		[PSFramework.Serialization.ClixmlDataStyle]
		$Style = 'Byte',
		
		[switch]
		$NoCompression,
		
		[switch]
		$PassThru,
		
		[PSFEncoding]
		$Encoding = (Get-PSFConfigValue -FullName 'PSFramework.Text.Encoding.DefaultWrite')
	)
	
	begin
	{
		Write-PSFMessage -Level InternalComment -Message "Bound parameters: $($PSBoundParameters.Keys -join ", ")" -Tag 'debug', 'start', 'param'
		
		try { $resolvedPath = Resolve-PSFPath -Path $Path -Provider FileSystem -SingleItem -NewChild }
		catch { Stop-PSFFunction -Message "Could not resolve outputpath: $Path" -EnableException $true -Cmdlet $PSCmdlet -ErrorRecord $_ }
		[System.Collections.ArrayList]$data = @()
	}
	process
	{
		$null = $data.Add($InputObject)
		if ($PassThru) { $InputObject }
	}
	end
	{
		try
		{
			Write-PSFMessage -Level Verbose -Message "Writing data to '$resolvedPath'"
			if ($Style -like 'Byte')
			{
				if ($NoCompression)
				{
					if ($Depth) { [System.IO.File]::WriteAllBytes($resolvedPath, ([PSFramework.Serialization.ClixmlSerializer]::ToByte($data.ToArray(), $Depth))) }
					else { [System.IO.File]::WriteAllBytes($resolvedPath, ([PSFramework.Serialization.ClixmlSerializer]::ToByte($data.ToArray()))) }
				}
				else
				{
					if ($Depth) { [System.IO.File]::WriteAllBytes($resolvedPath, ([PSFramework.Serialization.ClixmlSerializer]::ToByteCompressed($data.ToArray(), $Depth))) }
					else { [System.IO.File]::WriteAllBytes($resolvedPath, ([PSFramework.Serialization.ClixmlSerializer]::ToByteCompressed($data.ToArray()))) }
				}
			}
			else
			{
				if ($NoCompression)
				{
					if ($Depth) { [System.IO.File]::WriteAllText($resolvedPath, ([PSFramework.Serialization.ClixmlSerializer]::ToString($data.ToArray(), $Depth)), $Encoding) }
					else { [System.IO.File]::WriteAllText($resolvedPath, ([PSFramework.Serialization.ClixmlSerializer]::ToString($data.ToArray())), $Encoding) }
				}
				else
				{
					if ($Depth) { [System.IO.File]::WriteAllText($resolvedPath, ([PSFramework.Serialization.ClixmlSerializer]::ToStringCompressed($data.ToArray(), $Depth)), $Encoding) }
					else { [System.IO.File]::WriteAllText($resolvedPath, ([PSFramework.Serialization.ClixmlSerializer]::ToStringCompressed($data.ToArray())), $Encoding) }
				}
			}
		}
		catch
		{
			Stop-PSFFunction -Message "Failed to export object" -ErrorRecord $_ -EnableException $true -Target $resolvedPath -Cmdlet $PSCmdlet
		}
	}
}