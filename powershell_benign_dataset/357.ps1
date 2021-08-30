function Set-PSFTypeAlias
{

	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding(DefaultParameterSetName = 'Name', HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Set-PSFTypeAlias')]
	Param (
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Name')]
		[string]
		$AliasName,
		
		[Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'Name')]
		[string]
		$TypeName,
		
		[Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Hashtable')]
		[hashtable]
		$Mapping
	)
	
	begin
	{
		
		$TypeAcceleratorType = [psobject].Assembly.GetType("System.Management.Automation.TypeAccelerators")
	}
	process
	{
		foreach ($key in $Mapping.Keys)
		{
			$TypeAcceleratorType::Add($key, $Mapping[$key])
		}
		if ($AliasName)
		{
			$TypeAcceleratorType::Add($AliasName, $TypeName)
		}
	}
	end
	{
	
	}
}