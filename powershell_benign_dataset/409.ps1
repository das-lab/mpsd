function Convert-PsfMessageTarget
{
	
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		$Target,
		
		[Parameter(Mandatory = $true)]
		[string]
		$FunctionName,
		
		[Parameter(Mandatory = $true)]
		[string]
		$ModuleName
	)
	
	if ($null -eq $Target) { return }
	
	$typeName = $Target.GetType().FullName.ToLower()
	
	if ([PSFramework.Message.MessageHost]::TargetTransforms.ContainsKey($typeName))
	{
		$scriptBlock = [PSFramework.Message.MessageHost]::TargetTransforms[$typeName]
		try
		{
			$tempTarget = $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create($scriptBlock.ToString())), $null, $Target)
			return $tempTarget
		}
		catch
		{
			[PSFramework.Message.MessageHost]::WriteTransformError($_, $FunctionName, $ModuleName, $Target, "Target", ([System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId))
			return $Target
		}
	}
	
	if ($transform = [PSFramework.Message.MessageHost]::TargetTransformlist.Get($typeName, $ModuleName, $FunctionName))
	{
		try
		{
			$tempTarget = $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create($transform.ScriptBlock.ToString())), $null, $Target)
			return $tempTarget
		}
		catch
		{
			[PSFramework.Message.MessageHost]::WriteTransformError($_, $FunctionName, $ModuleName, $Target, "Target", ([System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId))
			return $Target
		}
	}
	
	return $Target
}