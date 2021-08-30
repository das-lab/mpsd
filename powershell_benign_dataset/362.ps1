function Clear-PSFResultCache
{
	
	[CmdletBinding(ConfirmImpact = 'Low', SupportsShouldProcess = $true, HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Clear-PSFresultCache')]
	param (
		
	)
	
	if ($pscmdlet.ShouldProcess("Result cache", "Clearing the result cache"))
	{
		[PSFramework.ResultCache.ResultCache]::Clear()
	}
}