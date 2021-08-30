function Register-PSFMessageEvent
{
	
	[CmdletBinding(PositionalBinding = $false, HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Register-PSFMessageEvent')]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,
		
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.ScriptBlock]
		$ScriptBlock,
		
		[string]
		$MessageFilter,
		
		[string]
		$ModuleNameFilter,
		
		[string]
		$FunctionNameFilter,
		
		$TargetFilter,
		
		[PSFramework.Message.MessageLevel[]]
		$LevelFilter,
		
		[string[]]
		$TagFilter,
		
		[System.Guid]
		$RunspaceFilter
	)
	
	$newName = $Name.ToLower()
	$eventSubscription = New-Object PSFramework.Message.MessageEventSubscription
	$eventSubscription.Name = $newName
	$eventSubscription.ScriptBlock = $ScriptBlock
	
	if (Test-PSFParameterBinding -ParameterName MessageFilter)
	{
		$eventSubscription.MessageFilter = $MessageFilter
	}
	
	if (Test-PSFParameterBinding -ParameterName ModuleNameFilter)
	{
		$eventSubscription.ModuleNameFilter = $ModuleNameFilter
	}
	
	if (Test-PSFParameterBinding -ParameterName FunctionNameFilter)
	{
		$eventSubscription.FunctionNameFilter = $FunctionNameFilter
	}
	
	if (Test-PSFParameterBinding -ParameterName TargetFilter)
	{
		$eventSubscription.TargetFilter = $TargetFilter
	}
	
	if (Test-PSFParameterBinding -ParameterName LevelFilter)
	{
		$eventSubscription.LevelFilter = $LevelFilter
	}
	
	if (Test-PSFParameterBinding -ParameterName TagFilter)
	{
		$eventSubscription.TagFilter = $TagFilter
	}
	
	if (Test-PSFParameterBinding -ParameterName RunspaceFilter)
	{
		$eventSubscription.RunspaceFilter = $RunspaceFilter
	}
	
	[PSFramework.Message.MessageHost]::Events[$newName] = $eventSubscription
}