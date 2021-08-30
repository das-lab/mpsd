function Set-PSFPath
{

	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding(DefaultParameterSetName = 'Default')]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,
		
		[Parameter(Mandatory = $true)]
		[string]
		$Path,
		
		[Parameter(ParameterSetName = 'Register', Mandatory = $true)]
		[switch]
		$Register,
		
		[Parameter(ParameterSetName = 'Register')]
		[PSFramework.Configuration.ConfigScope]
		$Scope = [PSFramework.Configuration.ConfigScope]::UserDefault
	)
	
	process
	{
		Set-PSFConfig -FullName "PSFramework.Path.$Name" -Value $Path
		if ($Register) { Register-PSFConfig -FullName "PSFramework.Path.$Name" -Scope $Scope }
	}
}