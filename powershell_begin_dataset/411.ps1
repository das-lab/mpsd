function Convert-PsfMessageLevel
{
	
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[PSFramework.Message.MessageLevel]
		$OriginalLevel,
		
		[Parameter(Mandatory = $true)]
		[bool]
		$FromStopFunction,
		
		[Parameter(Mandatory = $true)]
		[AllowNull()]
		[string[]]
		$Tags,
		
		[Parameter(Mandatory = $true)]
		[string]
		$FunctionName,
		
		[Parameter(Mandatory = $true)]
		[string]
		$ModuleName
	)
	
	$number = $OriginalLevel.value__
	
	if ([PSFramework.Message.MessageHost]::NestedLevelDecrement -gt 0)
	{
		$depth = (Get-PSCallStack).Count - 3
		if ($FromStopFunction) { $depth = $depth - 1 }
		$number = $number + $depth * ([PSFramework.Message.MessageHost]::NestedLevelDecrement)
	}
	
	foreach ($modifier in [PSFramework.Message.MessageHost]::MessageLevelModifiers.Values)
	{
		if ($modifier.AppliesTo($FunctionName, $ModuleName, $Tags))
		{
			$number = $number + $modifier.Modifier
		}
	}
	
	
	if ($number -lt 1) { $number = 1 }
	if ($number -gt 9) { $number = 9 }
	return ([PSFramework.Message.MessageLevel]$number)
}