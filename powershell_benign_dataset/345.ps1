function Register-PSFConfigValidation
{
	
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Register-PSFConfigValidation')]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,
		
		[Parameter(Mandatory = $true)]
		[ScriptBlock]
		$ScriptBlock
	)
	
	[PSFramework.Configuration.ConfigurationHost]::Validation[$Name.ToLower()] = $ScriptBlock
}