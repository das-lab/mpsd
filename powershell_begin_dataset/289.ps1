function Register-PSFTaskEngineTask
{
	
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Register-PSFTaskEngineTask')]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Name,
		
		[string]
		$Description,
		
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.ScriptBlock]
		$ScriptBlock,
		
		[Parameter(Mandatory = $true, ParameterSetName = "Once")]
		[switch]
		$Once,
		
		[Parameter(Mandatory = $true, ParameterSetName = "Repeating")]
		[PSFTimeSpan]
		$Interval,
		
		[PSFTimeSpan]
		$Delay,
		
		[PSFramework.TaskEngine.Priority]
		$Priority = "Medium",
		
		[switch]
		$ResetTask,
		
		[switch]
		$EnableException
	)
	
	
	if ([PSFramework.TaskEngine.TaskHost]::Tasks.ContainsKey($Name.ToLower()))
	{
		$task = [PSFramework.TaskEngine.TaskHost]::Tasks[$Name.ToLower()]
		if (Test-PSFParameterBinding -ParameterName Description) { $task.Description = $Description}
		if ($task.ScriptBlock -ne $ScriptBlock) { $task.ScriptBlock = $ScriptBlock }
		if (Test-PSFParameterBinding -ParameterName Once) { $task.Once = $Once }
		if (Test-PSFParameterBinding -ParameterName Interval)
		{
			$task.Once = $false
			$task.Interval = $Interval
		}
		if (Test-PSFParameterBinding -ParameterName Delay) { $task.Delay = $Delay }
		if (Test-PSFParameterBinding -ParameterName Priority) { $task.Priority = $Priority }
		
		if ($ResetTask)
		{
			$task.Registered = Get-Date
			$task.LastExecution = New-Object System.DateTime(0)
			$task.State = 'Pending'
		}
	}
	
	
	
	else
	{
		$task = New-Object PSFramework.TaskEngine.PsfTask
		$task.Name = $Name.ToLower()
		if (Test-PSFParameterBinding -ParameterName Description) { $task.Description = $Description }
		$task.ScriptBlock = $ScriptBlock
		if (Test-PSFParameterBinding -ParameterName Once) { $task.Once = $true }
		if (Test-PSFParameterBinding -ParameterName Interval)
		{
			if ($Interval.Value.Ticks -le 0)
			{
				Stop-PSFFunction -Message "Failed to register task: $Name - Interval cannot be 0 or less" -Category InvalidArgument -EnableException $EnableException
				return
			}
			else { $task.Interval = $Interval }
		}
		if (Test-PSFParameterBinding -ParameterName Delay) { $task.Delay = $Delay }
		$task.Priority = $Priority
		$task.Registered = Get-Date
		[PSFramework.TaskEngine.TaskHost]::Tasks[$Name.ToLower()] = $task
	}
	
	
	Start-PSFRunspace -Name "psframework.taskengine"
}
