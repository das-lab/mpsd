function Get-PSFMessageLevelModifier
{

	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFMessageLevelModifier')]
	Param (
		[string]
		$Name = "*"
	)
	
	([PSFramework.Message.MessageHost]::MessageLevelModifiers.Values) | Where-Object Name -Like $Name
}