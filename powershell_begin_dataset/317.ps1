function New-PSFMessageLevelModifier
{
	
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/New-PSFMessageLevelModifier')]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,
		
		[Parameter(Mandatory = $true)]
		[int]
		$Modifier,
		
		[string]
		$IncludeFunctionName,
		
		[string]
		$ExcludeFunctionName,
		
		[string]
		$IncludeModuleName,
		
		[string]
		$ExcludeModuleName,
		
		[string[]]
		$IncludeTags,
		
		[string[]]
		$ExcludeTags,
		
		[switch]
		$EnableException
	)
	
	if (Test-PSFParameterBinding -ParameterName IncludeFunctionName, ExcludeFunctionName, IncludeModuleName, ExcludeModuleName, IncludeTags, ExcludeTags -Not)
	{
		Stop-PSFFunction -Message "Must specify at least one condition in order to apply message level modifier!" -EnableException $EnableException -Category InvalidArgument -Tag 'fail', 'argument', 'message', 'level'
		return
	}
	
	$levelModifier = New-Object PSFramework.Message.MessageLevelModifier
	$levelModifier.Name = $Name.ToLower()
	$levelModifier.Modifier = $Modifier
	
	if (Test-PSFParameterBinding -ParameterName IncludeFunctionName)
	{
		$levelModifier.IncludeFunctionName = $IncludeFunctionName
	}
	
	if (Test-PSFParameterBinding -ParameterName ExcludeFunctionName)
	{
		$levelModifier.ExcludeFunctionName = $ExcludeFunctionName
	}
	
	if (Test-PSFParameterBinding -ParameterName IncludeModuleName)
	{
		$levelModifier.IncludeModuleName = $IncludeModuleName
	}
	
	if (Test-PSFParameterBinding -ParameterName ExcludeModuleName)
	{
		$levelModifier.ExcludeModuleName = $ExcludeModuleName
	}
	
	if (Test-PSFParameterBinding -ParameterName IncludeTags)
	{
		$levelModifier.IncludeTags = $IncludeTags
	}
	
	if (Test-PSFParameterBinding -ParameterName ExcludeTags)
	{
		$levelModifier.ExcludeTags = $ExcludeTags
	}
	
	[PSFramework.Message.MessageHost]::MessageLevelModifiers[$levelModifier.Name] = $levelModifier
	
	$levelModifier
}
