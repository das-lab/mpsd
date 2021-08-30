$scriptBlock = {
	$script:___ScriptName = 'psframework.taskengine'
	
	try
	{
		
		while ($true)
		{
			
			if ([PSFramework.Runspace.RunspaceHost]::Runspaces[$___ScriptName.ToLower()].State -notlike "Running")
			{
				break
			}
			
			$task = $null
			$tasksDone = @()
			while ($task = [PSFramework.TaskEngine.TaskHost]::GetNextTask($tasksDone))
			{
				$task.State = 'Running'
				try
				{
					[PSFramework.Utility.UtilityHost]::ImportScriptBlock($task.ScriptBlock)
					$task.ScriptBlock.Invoke()
					$task.State = 'Pending'
				}
				catch
				{
					$task.State = 'Error'
					$task.LastError = $_
					Write-PSFMessage -EnableException $false -Level Warning -Message "[Maintenance] Task '$($task.Name)' failed to execute" -ErrorRecord $_ -FunctionName "task:TaskEngine" -Target $task -ModuleName PSFramework
				}
				$task.LastExecution = Get-Date
				if (-not $task.Pending -and ($task.Status -eq "Pending")) { $task.Status = 'Completed' }
				$tasksDone += $task.Name
			}
			
			
			if (-not ([PSFramework.TaskEngine.TaskHost]::HasPendingTasks)) { break }
			
			Start-Sleep -Seconds 5
		}
		
	}
	catch {  }
	finally
	{
		[PSFramework.Runspace.RunspaceHost]::Runspaces[$___ScriptName.ToLower()].SignalStopped()
	}
}

Register-PSFRunspace -ScriptBlock $scriptBlock -Name 'psframework.taskengine' -NoMessage