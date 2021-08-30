function Set-PSFScriptblock
{

	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, Mandatory = $true)]
		[string]
		$Name,
		
		[Parameter(Position = 1, Mandatory = $true)]
		[System.Management.Automation.ScriptBlock]
		$Scriptblock
	)
	process
	{
		if ([PSFramework.Utility.UtilityHost]::ScriptBlocks.ContainsKey($Name))
		{
			[PSFramework.Utility.UtilityHost]::ScriptBlocks[$Name].Scriptblock = $Scriptblock
		}
		else
		{
			[PSFramework.Utility.UtilityHost]::ScriptBlocks[$Name] = New-Object PSFramework.Utility.ScriptBlockItem($Name, $Scriptblock)
		}
	}
}