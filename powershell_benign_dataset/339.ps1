function Get-PSFConfig
{
	
	[OutputType([PSFramework.Configuration.Config])]
	[CmdletBinding(DefaultParameterSetName = "FullName", HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFConfig')]
	Param (
		[Parameter(ParameterSetName = "FullName", Position = 0)]
		[string]
		$FullName = "*",
		
		[Parameter(ParameterSetName = "Module", Position = 1)]
		[string]
		$Name = "*",
		
		[Parameter(ParameterSetName = "Module", Position = 0)]
		[string]
		$Module = "*",
		
		[switch]
		$Force
	)
	
	switch ($PSCmdlet.ParameterSetName)
	{
		"Module"
		{
			$Name = $Name.ToLower()
			$Module = $Module.ToLower()
			
			[PSFramework.Configuration.ConfigurationHost]::Configurations.Values | Where-Object { ($_.Name -like $Name) -and ($_.Module -like $Module) -and ((-not $_.Hidden) -or ($Force)) } | Sort-Object Module, Name
		}
		
		"FullName"
		{
			[PSFramework.Configuration.ConfigurationHost]::Configurations.Values | Where-Object { ("$($_.Module).$($_.Name)" -like $FullName) -and ((-not $_.Hidden) -or ($Force)) } | Sort-Object Module, Name
		}
	}
}
