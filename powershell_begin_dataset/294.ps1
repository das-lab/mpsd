function Get-PSFCallback
{

	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "")]
	[OutputType([PSFramework.FlowControl.Callback])]
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Name = '*',
		
		[switch]
		$All
	)
	
	process
	{
		foreach ($nameString in $Name)
		{
			[PSFramework.FlowControl.CallbackHost]::Get($nameString, $All.ToBool())
		}
	}
}