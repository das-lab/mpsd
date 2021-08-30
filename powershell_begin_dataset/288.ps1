function Disable-PSFTaskEngineTask
{
	
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Disable-PSFTaskEngineTask')]
	Param (
		[Parameter(ValueFromPipeline = $true, Mandatory = $true)]
		[PSFramework.TaskEngine.PsfTask[]]
		$Task
	)
	
	process
	{
		foreach ($item in $Task)
		{
			if ($item.Enabled)
			{
				Write-PSFMessage -Level Verbose -Message "Disabling task engine task: $($item.Name)" -Tag 'disable', 'taskengine', 'task'
				$item.Enabled = $false
			}
		}
	}
}