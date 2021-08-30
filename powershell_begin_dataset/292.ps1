function Test-PSFTaskEngineTask
{
	
	[OutputType([System.Boolean])]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Test-PSFTaskEngineTask')]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name
	)
	
	if (-not ([PSFramework.TaskEngine.TaskHost]::Tasks.ContainsKey($Name.ToLower())))
	{
		return $false
	}
	
	$task = [PSFramework.TaskEngine.TaskHost]::Tasks[$Name.ToLower()]
	$task.LastExecution -gt $task.Registered
}