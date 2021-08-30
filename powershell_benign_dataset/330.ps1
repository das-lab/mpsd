function Resolve-PSFPath
{

	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Resolve-PSFPath')]
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[string[]]
		$Path,
		
		[string]
		$Provider,
		
		[switch]
		$SingleItem,
		
		[switch]
		$NewChild
	)
	
	process
	{
		foreach ($inputPath in $Path)
		{
			if ($inputPath -eq ".")
			{
				$inputPath = (Get-Location).Path
			}
			if ($NewChild)
			{
				$parent = Split-Path -Path $inputPath
				$child = Split-Path -Path $inputPath -Leaf
				
				try
				{
					if (-not $parent) { $parentPath = Get-Location -ErrorAction Stop }
					else { $parentPath = Resolve-Path $parent -ErrorAction Stop }
				}
				catch { Stop-PSFFunction -Message "Failed to resolve path" -ErrorRecord $_ -EnableException $true -Cmdlet $PSCmdlet }
				
				if ($SingleItem -and (($parentPath | Measure-Object).Count -gt 1))
				{
					Stop-PSFFunction -Message "Could not resolve to a single parent path!" -EnableException $true -Cmdlet $PSCmdlet
				}
				
				if ($Provider -and ($parentPath.Provider.Name -ne $Provider))
				{
					Stop-PSFFunction -Message "Resolved provider is $($parentPath.Provider.Name) when it should be $($Provider)" -EnableException $true -Cmdlet $PSCmdlet
				}
				
				foreach ($parentItem in $parentPath)
				{
					Join-Path $parentItem.ProviderPath $child
				}
			}
			else
			{
				try { $resolvedPaths = Resolve-Path $inputPath -ErrorAction Stop }
				catch { Stop-PSFFunction -Message "Failed to resolve path" -ErrorRecord $_ -EnableException $true -Cmdlet $PSCmdlet }
				
				if ($SingleItem -and (($resolvedPaths | Measure-Object).Count -gt 1))
				{
					Stop-PSFFunction -Message "Could not resolve to a single parent path!" -EnableException $true -Cmdlet $PSCmdlet
				}
				
				if ($Provider -and ($resolvedPaths.Provider.Name -ne $Provider))
				{
					Stop-PSFFunction -Message "Resolved provider is $($resolvedPaths.Provider.Name) when it should be $($Provider)" -EnableException $true -Cmdlet $PSCmdlet
				}
				
				$resolvedPaths.ProviderPath
			}
		}
	}
}