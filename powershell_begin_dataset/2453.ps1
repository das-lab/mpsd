function Write-Param
{
	
	[CmdletBinding()]
	param ()
	$caller = (Get-PSCallStack)[1]
	Write-Verbose -Message "Function: $($caller.Command) - Params used: $($caller.Arguments)"
}