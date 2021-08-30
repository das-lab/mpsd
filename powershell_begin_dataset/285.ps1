function Set-PSFTaskEngineCache
{

	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Set-PSFTaskEngineCache')]
	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Module,
		
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Name,
		
		[AllowNull()]
		[object]
		$Value,
		
		[PSFTimespan]
		$Lifetime,
		
		[System.Management.Automation.ScriptBlock]
		$Collector,
		
		[object]
		$CollectorArgument
	)
	
	if ([PSFramework.TaskEngine.TaskHost]::TestCacheItem($Module, $Name))
	{
		$cacheItem = [PSFramework.TaskEngine.TaskHost]::GetCacheItem($Module, $Name)
	}
	else { $cacheItem = [PSFramework.TaskEngine.TaskHost]::NewCacheItem($Module, $Name) }
	if (Test-PSFParameterBinding -ParameterName Value) { $cacheItem.Value = $Value }
	if (Test-PSFParameterBinding -ParameterName Lifetime) { $cacheItem.Expiration = $Lifetime }
	if (Test-PSFParameterBinding -ParameterName Collector) { $cacheItem.Collector = $Collector }
	if (Test-PSFParameterBinding -ParameterName CollectorArgument) { $cacheItem.CollectorArgument = $CollectorArgument }
}