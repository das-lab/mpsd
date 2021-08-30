function Convert-PsfMessageException
{
	
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		$Exception,
		
		[Parameter(Mandatory = $true)]
		[string]
		$FunctionName,
		
		[Parameter(Mandatory = $true)]
		[string]
		$ModuleName
	)
	
	if ($null -eq $Exception) { return }
	
	$typeName = $Exception.GetType().FullName.ToLower()
	
	if ([PSFramework.Message.MessageHost]::ExceptionTransforms.ContainsKey($typeName))
	{
		$scriptBlock = [PSFramework.Message.MessageHost]::ExceptionTransforms[$typeName]
		try
		{
			$tempException = $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create($scriptBlock.ToString())), $null, $Exception)
			return $tempException
		}
		catch
		{
			[PSFramework.Message.MessageHost]::WriteTransformError($_, $FunctionName, $ModuleName, $Exception, "Exception", ([System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId))
			return $Exception
		}
	}
	
	if ($transform = [PSFramework.Message.MessageHost]::ExceptionTransformList.Get($typeName, $ModuleName, $FunctionName))
	{
		try
		{
			$tempException = $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create($transform.ScriptBlock.ToString())), $null, $Exception)
			return $tempException
		}
		catch
		{
			[PSFramework.Message.MessageHost]::WriteTransformError($_, $FunctionName, $ModuleName, $Exception, "Target", ([System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId))
			return $Exception
		}
	}
	
	return $Exception
}