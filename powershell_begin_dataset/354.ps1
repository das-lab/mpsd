function Install-PSFLoggingProvider
{
	
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Install-PSFLoggingProvider')]
	Param (
		[Alias('Provider', 'ProviderName')]
		[string]
		$Name,
		
		[switch]
		$EnableException
	)
	
	dynamicparam
	{
		if ($Name -and ([PSFramework.Logging.ProviderHost]::Providers.ContainsKey($Name.ToLower())))
		{
			[PSFramework.Logging.ProviderHost]::Providers[$Name.ToLower()].InstallationParameters.Invoke()
		}
	}
	
	begin
	{
		
	}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }
		
		if (-not ([PSFramework.Logging.ProviderHost]::Providers.ContainsKey($Name.ToLower())))
		{
			Stop-PSFFunction -Message "Provider $Name not found!" -EnableException $EnableException -Category InvalidArgument -Target $Name -Tag 'logging', 'provider', 'install'
			return
		}
		
		$provider = [PSFramework.Logging.ProviderHost]::Providers[$Name.ToLower()]
		
		if (-not ([System.Management.Automation.ScriptBlock]::Create($provider.IsInstalledScript).Invoke()))
		{
			try { [System.Management.Automation.ScriptBlock]::Create($provider.InstallationScript).Invoke() }
			catch
			{
				Stop-PSFFunction -Message "Failed to install provider '$Name'" -EnableException $EnableException -Target $Name -ErrorRecord $_ -Tag 'logging', 'provider', 'install'
				return
			}
		}
	}
	end
	{
		if (Test-PSFFunctionInterrupt) { return }
	}
}
