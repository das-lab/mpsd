function Get-PSFTaskEngineCache
{
	
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFTaskEngineCache')]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Module,
		
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Name
	)
	
	process
	{
		$cacheItem = [PSFramework.TaskEngine.TaskHost]::GetCacheItem($Module, $Name)
		if (-not $cacheItem) { return }
		
		$value = $cacheItem.GetValue()
		if ($null -ne $value) { $value }
	}
}
