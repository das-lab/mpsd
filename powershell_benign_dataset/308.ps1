function Register-PSFTeppScriptblock
{
    
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Register-PSFTeppScriptblock')]
	Param (
		[Parameter(Mandatory = $true)]
		[System.Management.Automation.ScriptBlock]
		$ScriptBlock,
		
		[Parameter(Mandatory = $true)]
		[string]
		$Name,
		
		[PSFramework.TabExpansion.TeppScriptMode]
		$Mode = "Auto",
		
		[PSFramework.Parameter.TimeSpanParameter]
		$CacheDuration = 0
	)
	
	process
	{
		$scp = New-Object PSFramework.TabExpansion.ScriptContainer
		$scp.Name = $Name.ToLower()
		$scp.LastDuration = New-TimeSpan -Seconds -1
		$scp.LastResultsValidity = $CacheDuration
		
		if ($Mode -like "Auto")
		{
			$ast = [System.Management.Automation.Language.Parser]::ParseInput($ScriptBlock, [ref]$null, [ref]$null)
			$simple = $null -eq $ast.ParamBlock
		}
		elseif ($Mode -like "Simple") { $simple = $true }
		else { $simple = $false }
		
		if ($simple)
		{
			$scr = [scriptblock]::Create(@'
	param (
		$commandName,
		
		$parameterName,
		
		$wordToComplete,
		
		$commandAst,
		
		$fakeBoundParameter
	)

	$start = Get-Date
	$scriptContainer = [PSFramework.TabExpansion.TabExpansionHost]::Scripts["<name>"]
	if ($scriptContainer.ShouldExecute)
	{
		$scriptContainer.LastExecution = $start
			
		$innerScript = $scriptContainer.InnerScriptBlock
		[PSFramework.Utility.UtilityHost]::ImportScriptBlock($innerScript)
		
		try { $items = $innerScript.Invoke() | Write-Output }
		catch { $null = $scriptContainer.ErrorRecords.Enqueue($_) }
			
		foreach ($item in ($items | Where-Object { "$_" -like "$wordToComplete*"} | Sort-Object))
		{
			New-PSFTeppCompletionResult -CompletionText $item -ToolTip $item
		}

		$scriptContainer.LastDuration = (Get-Date) - $start
		if ($items) { $scriptContainer.LastResult = $items }
	}
	else
	{
		foreach ($item in ($scriptContainer.LastResult | Where-Object { "$_" -like "$wordToComplete*"} | Sort-Object))
		{
			New-PSFTeppCompletionResult -CompletionText $item -ToolTip $item
		}
	}
'@.Replace("<name>", $Name))
			$scp.ScriptBlock = $scr
			$scp.InnerScriptBlock = $ScriptBlock
		}
		else
		{
			$scp.ScriptBlock = $ScriptBlock
		}
		[PSFramework.TabExpansion.TabExpansionHost]::Scripts[$Name] = $scp
	}
}
