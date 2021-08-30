function Remove-PSFMessageLevelModifier
{
	
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Remove-PSFMessageLevelModifier')]
	Param (
		[Parameter(ValueFromPipeline = $true)]
		[string[]]
		$Name,
		
		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Message.MessageLevelModifier[]]
		$Modifier,
		
		[switch]
		$EnableException
	)
	
	process
	{
		foreach ($item in $Name)
		{
			if ($item -eq "PSFramework.Message.MessageLevelModifier") { continue }
			
			if ([PSFramework.Message.MessageHost]::MessageLevelModifiers.ContainsKey($item.ToLower()))
			{
				$dummy = $null
				$null = [PSFramework.Message.MessageHost]::MessageLevelModifiers.TryRemove($item.ToLower(), [ref] $dummy)
			}
			else
			{
				Stop-PSFFunction -Message "No message level modifier of name $item found!" -EnableException $EnableException -Category InvalidArgument -Tag 'fail','input','level','message' -Continue
			}
		}
		foreach ($item in $Modifier)
		{
			if ([PSFramework.Message.MessageHost]::MessageLevelModifiers.ContainsKey($item.Name))
			{
				$dummy = $null
				$null = [PSFramework.Message.MessageHost]::MessageLevelModifiers.TryRemove($item.Name, [ref]$dummy)
			}
			else
			{
				Stop-PSFFunction -Message "No message level modifier of name $($item.Name) found!" -EnableException $EnableException -Category InvalidArgument -Tag 'fail', 'input', 'level', 'message' -Continue
			}
		}
	}
}