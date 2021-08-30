function Get-PSFLoggingProvider
{

	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFLoggingProvider')]
	Param (
		[Alias('Provider', 'ProviderName')]
		[string]
		$Name = "*"
	)
	
	begin
	{
		
	}
	process
	{
		[PSFramework.Logging.ProviderHost]::Providers.Values | Where-Object Name -Like $Name
	}
	end
	{
	
	}
}