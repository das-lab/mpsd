function Test-PSFFunctionInterrupt
{
    
	[OutputType([System.Boolean])]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Test-PSFFunctionInterrupt')]
	Param (
		
	)
	
	$psframework_killqueue -contains (Get-PSCallStack)[1].InvocationInfo.GetHashCode()
}