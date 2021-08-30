function Get-PSFMessage
{
	
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFMessage')]
	param (
		[string]
		$FunctionName = "*",
		
		[string]
		$ModuleName = "*",
		
		[AllowNull()]
		$Target,
		
		[string[]]
		$Tag,
		
		[int]
		$Last,
		
		[int]
		$Skip = 0,
		
		[guid]
		$Runspace,
		
		[PSFramework.Message.MessageLevel[]]
		$Level,
		
		[switch]
		$Errors
	)
	
	process
	{
		if ($Errors) { $messages = [PSFramework.Message.LogHost]::GetErrors() | Where-Object { ($_.FunctionName -like $FunctionName) -and ($_.ModuleName -like $ModuleName) } }
		else { $messages = [PSFramework.Message.LogHost]::GetLog() | Where-Object { ($_.FunctionName -like $FunctionName) -and ($_.ModuleName -like $ModuleName) } }
		
		if (Test-PSFParameterBinding -ParameterName Target)
		{
			$messages = $messages | Where-Object TargetObject -EQ $Target
		}
		
		if (Test-PSFParameterBinding -ParameterName Tag)
		{
			$messages = $messages | Where-Object { $_.Tags | Where-Object { $_ -in $Tag } }
		}
		
		if (Test-PSFParameterBinding -ParameterName Runspace)
		{
			$messages = $messages | Where-Object Runspace -EQ $Runspace
		}
		
		if (Test-PSFParameterBinding -ParameterName Last)
		{
			$history = Get-History | Where-Object CommandLine -NotLike "Get-PSFMessage*" | Select-Object -Last $Last -Skip $Skip
			if ($history)
			{
				$start = $history[0].StartExecutionTime
				$end = $history[-1].EndExecutionTime
				
				$messages = $messages | Where-Object {
					($_.Timestamp -ge $start) -and ($_.Timestamp -le $end) -and ($_.Runspace -eq ([System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId))
				}
			}
		}
		
		if (Test-PSFParameterBinding -ParameterName Level)
		{
			$messages = $messages | Where-Object Level -In $Level
		}
		
		return $messages
	}
}