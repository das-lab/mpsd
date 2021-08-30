function global:New-PSFTeppCompletionResult
{
    
	param (
		[Parameter(Position = 0, ValueFromPipelineByPropertyName = $true, Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$CompletionText,
		
		[Parameter(Position = 1, ValueFromPipelineByPropertyName = $true)]
		[string]
		$ToolTip,
		
		[Parameter(Position = 2, ValueFromPipelineByPropertyName = $true)]
		[string]
		$ListItemText,
		
		[System.Management.Automation.CompletionResultType]
		$CompletionResultType = [System.Management.Automation.CompletionResultType]::ParameterValue,
		
		[switch]
		$NoQuotes
	)
	
	process
	{
		$toolTipToUse = if ($ToolTip -eq '') { $CompletionText }
		else { $ToolTip }
		$listItemToUse = if ($ListItemText -eq '') { $CompletionText }
		else { $ListItemText }
		
		
		
		
		
		if ($CompletionResultType -eq [System.Management.Automation.CompletionResultType]::ParameterValue -and -not $NoQuotes)
		{
			
			
			
			
			
			
			$tokens = $null
			$null = [System.Management.Automation.Language.Parser]::ParseInput("echo $CompletionText", [ref]$tokens, [ref]$null)
			if ($tokens.Length -ne 3 -or ($tokens[1] -is [System.Management.Automation.Language.StringExpandableToken] -and $tokens[1].Kind -eq [System.Management.Automation.Language.TokenKind]::Generic))
			{
				$CompletionText = "'$CompletionText'"
			}
		}
		return New-Object System.Management.Automation.CompletionResult($CompletionText, $listItemToUse, $CompletionResultType, $toolTipToUse.Trim())
	}
}

(Get-Item Function:\New-PSFTeppCompletionResult).Visibility = "Private"