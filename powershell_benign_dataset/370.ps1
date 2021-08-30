function Get-PSFLocalizedString
{

	[OutputType([PSFramework.Localization.LocalStrings], ParameterSetName = 'Default')]
	[OutputType([System.String], ParameterSetName = 'Name')]
	[CmdletBinding(DefaultParameterSetName = 'Default')]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Name')]
		[Parameter(Mandatory = $true, ParameterSetName = 'Default')]
		[string]
		$Module,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Name')]
		[string]
		$Name
	)
	
	process
	{
		switch ($PSCmdlet.ParameterSetName)
		{
			'Default' { New-Object PSFramework.Localization.LocalStrings($Module) }
			'Name' { (New-Object PSFramework.Localization.LocalStrings($Module)).$Name }
		}
	}
}