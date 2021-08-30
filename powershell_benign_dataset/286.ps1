function Get-PSFTaskEngineTask
{
	
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFTaskEngineTask')]
	Param (
		[string]
		$Name = "*"
	)
	
	[PSFramework.TaskEngine.TaskHost]::Tasks.Values | Where-Object Name -Like $Name
}