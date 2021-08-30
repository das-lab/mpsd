function Register-PSFLoggingProvider
{
	
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Register-PSFLoggingProvider')]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,
		
		[switch]
		$Enabled,
		
		[System.Management.Automation.ScriptBlock]
		$RegistrationEvent,
		
		[System.Management.Automation.ScriptBlock]
		$BeginEvent = { },
		
		[System.Management.Automation.ScriptBlock]
		$StartEvent = { },
		
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.ScriptBlock]
		$MessageEvent,
		
		[System.Management.Automation.ScriptBlock]
		$ErrorEvent = { },
		
		[System.Management.Automation.ScriptBlock]
		$EndEvent = { },
		
		[System.Management.Automation.ScriptBlock]
		$FinalEvent = { },
		
		[System.Management.Automation.ScriptBlock]
		$ConfigurationParameters = { },
		
		[System.Management.Automation.ScriptBlock]
		$ConfigurationScript = { },
		
		[System.Management.Automation.ScriptBlock]
		$IsInstalledScript = { $true },
		
		[System.Management.Automation.ScriptBlock]
		$InstallationScript = { },
		
		[System.Management.Automation.ScriptBlock]
		$InstallationParameters = { },
		
		[System.Management.Automation.ScriptBlock]
		$ConfigurationSettings,
		
		[switch]
		$EnableException
	)
	
	if ([PSFramework.Logging.ProviderHost]::Providers.ContainsKey($Name.ToLower()))
	{
		return
	}
	
	if ($ConfigurationSettings) { . $ConfigurationSettings }
	if (Test-PSFParameterBinding -ParameterName Enabled)
	{
		Set-PSFConfig -FullName "LoggingProvider.$Name.Enabled" -Value $Enabled.ToBool() -DisableHandler
	}
	
	$provider = New-Object PSFramework.Logging.Provider
	$provider.Name = $Name
	$provider.BeginEvent = $BeginEvent
	$provider.StartEvent = $StartEvent
	$provider.MessageEvent = $MessageEvent
	$provider.ErrorEvent = $ErrorEvent
	$provider.EndEvent = $EndEvent
	$provider.FinalEvent = $FinalEvent
	$provider.ConfigurationParameters = $ConfigurationParameters
	$provider.ConfigurationScript = $ConfigurationScript
	$provider.IsInstalledScript = $IsInstalledScript
	$provider.InstallationScript = $InstallationScript
	$provider.InstallationParameters = $InstallationParameters
	
	$provider.IncludeModules = Get-PSFConfigValue -FullName "LoggingProvider.$Name.IncludeModules" -Fallback @()
	$provider.ExcludeModules = Get-PSFConfigValue -FullName "LoggingProvider.$Name.ExcludeModules" -Fallback @()
	$provider.IncludeTags = Get-PSFConfigValue -FullName "LoggingProvider.$Name.IncludeTags" -Fallback @()
	$provider.ExcludeTags = Get-PSFConfigValue -FullName "LoggingProvider.$Name.ExcludeTags" -Fallback @()
	
	$provider.InstallationOptional = Get-PSFConfigValue -FullName "LoggingProvider.$Name.InstallOptional" -Fallback $false
	
	[PSFramework.Logging.ProviderHost]::Providers[$Name.ToLower()] = $provider
	
	try { if ($RegistrationEvent) { . $RegistrationEvent } }
	catch
	{
		$dummy = $null
		$null = [PSFramework.Logging.ProviderHost]::Providers.TryRemove($Name.ToLower(), [ref] $dummy)
		Stop-PSFFunction -Message "Failed to register logging provider '$Name' - Registration event failed." -ErrorRecord $_ -EnableException $EnableException -Tag 'logging', 'provider', 'fail', 'register'
		return
	}
	
	$shouldEnable = Get-PSFConfigValue -FullName "LoggingProvider.$Name.Enabled" -Fallback $false
	$isInstalled = [System.Management.Automation.ScriptBlock]::Create($provider.IsInstalledScript).Invoke()
	
	if (-not $isInstalled -and (Get-PSFConfigValue -FullName "LoggingProvider.$Name.AutoInstall" -Fallback $false))
	{
		try { Install-PSFLoggingProvider -Name $Name -EnableException }
		catch
		{
			if ($provider.InstallationOptional)
			{
				Write-PSFMessage -Level Warning -Message "Failed to install logging provider '$Name'" -ErrorRecord $_ -Tag 'logging', 'provider', 'fail', 'install' -EnableException $EnableException
			}
			else
			{
				Stop-PSFFunction -Message "Failed to install logging provider '$Name'" -ErrorRecord $_ -EnableException $EnableException -Tag 'logging', 'provider', 'fail', 'install'
				return
			}
		}
	}
	
	if ($shouldEnable)
	{
		if ($isInstalled) { $provider.Enabled = $true }
		else
		{
			Stop-PSFFunction -Message "Failed to enable logging provider $Name on registration! It was not recognized as installed. Consider running 'Install-PSFLoggingProvider' to properly install the prerequisites." -ErrorRecord $_ -EnableException $EnableException -Tag 'logging', 'provider', 'fail', 'install'
			return
		}
	}
}
