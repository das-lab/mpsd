function Set-PSFTeppResult
{

	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low', HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Set-PSFTeppResult')]
	param (
		[Parameter(Mandatory = $true)]
		[PSFramework.Validation.PsfValidateSetAttribute(ScriptBlock = { [PSFramework.TabExpansion.TabExpansionHost]::Scripts.Keys } )]
		[string]
		$TabCompletion,
		
		[Parameter(Mandatory = $true)]
		[AllowEmptyCollection()]
		[string[]]
		$Value
	)
	
	process
	{
		if (Test-PSFShouldProcess -PSCmdlet $PSCmdlet -Target $TabCompletion -Action "Setting the cache")
		{
			[PSFramework.TabExpansion.TabExpansionHost]::Scripts[$TabCompletion].LastResult = $Value
			[PSFramework.TabExpansion.TabExpansionHost]::Scripts[$TabCompletion].LastExecution = ([System.DateTime]::Now)
		}
	}
}