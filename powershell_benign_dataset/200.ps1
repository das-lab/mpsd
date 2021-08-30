function New-ScriptMessage
{


	[CmdletBinding()]
	[OutputType([string])]
	param
	(
		[String]$Message,
		[String]$Block,
		[String]$DateFormat = 'yyyy\/MM\/dd HH:mm:ss:ff',
		$FunctionScope = "1"
	)

	PROCESS
	{
		$DateFormat = Get-Date -Format $DateFormat
		$MyCommand = (Get-Variable -Scope $FunctionScope -Name MyInvocation -ValueOnly).MyCommand.Name
		IF ($MyCommand)
		{
			$String = "[$DateFormat][$MyCommand]"
		} 
		ELSE
		{
			$String = "[$DateFormat]"
		} 

		IF ($PSBoundParameters['Block'])
		{
			$String += "[$Block]"
		}
		Write-Output "$String $Message"
	} 
}
