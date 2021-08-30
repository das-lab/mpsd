function Register-PSFParameterClassMapping
{

	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Register-PSFParameterClassMapping')]
	Param (
		[Parameter(Mandatory = $true)]
		[PSFramework.Parameter.ParameterClasses]
		$ParameterClass,
		
		[Parameter(Mandatory = $true)]
		[string]
		$TypeName,
		
		[Parameter(Mandatory = $true)]
		[string[]]
		$Properties,
		
		[switch]
		$EnableException
	)
	
	process
	{
		try
		{
			switch ($ParameterClass)
			{
				"Computer"
				{
					[PSFramework.Parameter.ComputerParameter]::SetTypePropertyMapping($TypeName.ToLower(), $Properties)
				}
				"DateTime"
				{
					[PSFramework.Parameter.DateTimeParameter]::SetTypePropertyMapping($TypeName.ToLower(), $Properties)
				}
				"TimeSpan"
				{
					[PSFramework.Parameter.TimeSpanParameter]::SetTypePropertyMapping($TypeName.ToLower(), $Properties)
				}
				"Encoding"
				{
					[PSFramework.Parameter.EncodingParameter]::SetTypePropertyMapping($TypeName.ToLower(), $Properties)
				}
				default
				{
					Stop-PSFFunction -Message "Support for the $ParameterClass parameter class has not yet been added!" -EnableException $EnableException -Tag 'fail', 'argument' -Category NotImplemented
					return
				}
			}
		}
		catch
		{
			Stop-PSFFunction -Message "Failed to update property mapping for $ParameterClass : $Typename. This is likely happening on some Linux distributions due to an underlying .NET issue and means the parameter class cannot be used." -EnableException $EnableException -Tag 'fail', '.NET' -ErrorRecord $_
			return
		}
	}
}
