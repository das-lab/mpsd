function Set-PSFLoggingProvider
{

	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Set-PSFLoggingProvider')]
	Param (
		[Alias('Provider', 'ProviderName')]
		[string]
		$Name,
		
		[bool]
		$Enabled,
		
		[string[]]
		$IncludeModules,
		
		[string[]]
		$ExcludeModules,
		
		[string[]]
		$IncludeTags,
		
		[string[]]
		$ExcludeTags,
		
		[switch]
		$EnableException
	)
	
	dynamicparam
	{
		if ($Name -and ([PSFramework.Logging.ProviderHost]::Providers.ContainsKey($Name.ToLower())))
		{
			[scriptblock]::Create(([PSFramework.Logging.ProviderHost]::Providers[$Name.ToLower()].ConfigurationParameters)).Invoke()
		}
	}
	
	begin
	{
		if (-not ([PSFramework.Logging.ProviderHost]::Providers.ContainsKey($Name.ToLower())))
		{
			Stop-PSFFunction -Message "Provider $Name not found!" -EnableException $EnableException -Category InvalidArgument -Target $Name
			return
		}
		
		[PSFramework.Logging.Provider]$provider = [PSFramework.Logging.ProviderHost]::Providers[$Name.ToLower()]
		
		if ((-not $provider.Enabled) -and (-not ([scriptblock]::Create($provider.IsInstalledScript).Invoke())) -and $Enabled)
		{
			Stop-PSFFunction -Message "Provider $Name not installed! Run 'Install-PSFLoggingProvider' first" -EnableException $EnableException -Category InvalidOperation -Target $Name
			return
		}
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		
		[System.Management.Automation.ScriptBlock]::Create($provider.ConfigurationScript).Invoke()
		
		
		if (Test-PSFParameterBinding -ParameterName "IncludeModules")
		{
			$provider.IncludeModules = $IncludeModules
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).IncludeModules" -Value $IncludeModules
		}
		if (Test-PSFParameterBinding -ParameterName "ExcludeModules")
		{
			$provider.ExcludeModules = $ExcludeModules
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).ExcludeModules" -Value $ExcludeModules
		}
		
		if (Test-PSFParameterBinding -ParameterName "IncludeTags")
		{
			$provider.IncludeTags = $IncludeTags
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).IncludeTags" -Value $IncludeTags
		}
		if (Test-PSFParameterBinding -ParameterName "ExcludeTags")
		{
			$provider.ExcludeTags = $ExcludeTags
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).ExcludeTags" -Value $ExcludeTags
		}
		
		
		if (Test-PSFParameterBinding -ParameterName "Enabled")
		{
			$provider.Enabled = $Enabled
			Set-PSFConfig -FullName "LoggingProvider.$($provider.Name).Enabled" -Value $Enabled
		}
	}
	end
	{
		if (Test-PSFFunctionInterrupt) { return }
	}
}
