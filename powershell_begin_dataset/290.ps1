function Enable-PSFTaskEngineTask
{
	
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Enable-PSFTaskEngineTask')]
	Param (
		[Parameter(ValueFromPipeline = $true, Mandatory = $true)]
		[PSFramework.TaskEngine.PsfTask[]]
		$Task
	)
	
	begin
	{
		$didSomething = $false
	}
	process
	{
		foreach ($item in $Task)
		{
			if (-not $item.Enabled)
			{
				Write-PSFMessage -Level Verbose -Message "Enabling task engine task: $($item.Name)" -Tag 'enable','taskengine','task'
				$item.Enabled = $true
				$didSomething = $true
			}
		}
	}
	end
	{
		
		if ($didSomething) { Start-PSFRunspace -Name 'psframework.taskengine' }
	}
}