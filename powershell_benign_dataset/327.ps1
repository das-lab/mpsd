function Get-PSFScriptblock
{

	[OutputType([PSFramework.Utility.ScriptBlockItem], ParameterSetName = 'List')]
	[OutputType([System.Management.Automation.ScriptBlock], ParameterSetName = 'Name')]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidDefaultValueForMandatoryParameter", "")]
	[CmdletBinding(DefaultParameterSetName = 'Name')]
	param (
		[Parameter(ParameterSetName = 'List')]
		[Parameter(Mandatory = $true, ParameterSetName = 'Name', ValueFromPipeline = $true)]
		[string[]]
		$Name = '*',
		
		[Parameter(Mandatory = $true, ParameterSetName = 'List')]
		[switch]
		$List
	)
	
	begin
	{
		[System.Collections.ArrayList]$sent = @()
		$allItems = [PSFramework.Utility.UtilityHost]::ScriptBlocks.Values
	}
	process
	{
		:main foreach ($nameText in $Name)
		{
			switch ($PSCmdlet.ParameterSetName)
			{
				'Name'
				{
					if ($sent -contains $nameText) { continue main }
					$null = $sent.Add($nameText)
					[PSFramework.Utility.UtilityHost]::ScriptBlocks[$nameText].ScriptBlock
				}
				'List'
				{
					foreach ($item in $allItems)
					{
						if ($item.Name -notlike $nameText) { continue }
						if ($sent -contains $item.Name) { continue }
						$null = $sent.Add($item.Name)
						$item
					}
				}
			}
		}
	}
}