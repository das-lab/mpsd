function Get-PSFDynamicContentObject
{

	[OutputType([PSFramework.Utility.DynamicContentObject])]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Get-PSFDynamicContentObject')]
	Param (
		[Parameter(Mandatory = $true)]
		[string[]]
		$Name
	)
	
	begin
	{
		
	}
	process
	{
		foreach ($item in $Name)
		{
			[PSFramework.Utility.DynamicContentObject]::Get($Name)
		}
	}
	end
	{
	
	}
}