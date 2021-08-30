function Set-PSFDynamicContentObject
{

	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[OutputType([PSFramework.Utility.DynamicContentObject])]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Set-PSFDynamicContentObject')]
	Param (
		[string[]]
		$Name,
		
		[Parameter(ValueFromPipeline = $true)]
		[PSFramework.Utility.DynamicContentObject[]]
		$Object,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Value')]
		[AllowNull()]
		$Value = $null,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Queue')]
		[switch]
		$Queue,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Stack')]
		[switch]
		$Stack,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'List')]
		[switch]
		$List,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'Dictionary')]
		[switch]
		$Dictionary,
		
		[switch]
		$PassThru,
		
		[switch]
		$Reset
	)
	
	process
	{
		foreach ($item in $Name)
		{
			if ($Queue) { [PSFramework.Utility.DynamicContentObject]::Set($item, $Value, 'Queue') }
			elseif ($Stack) { [PSFramework.Utility.DynamicContentObject]::Set($item, $Value, 'Stack') }
			elseif ($List) { [PSFramework.Utility.DynamicContentObject]::Set($item, $Value, 'List') }
			elseif ($Dictionary) { [PSFramework.Utility.DynamicContentObject]::Set($item, $Value, 'Dictionary') }
			else { [PSFramework.Utility.DynamicContentObject]::Set($item, $Value, 'Common') }
			
			if ($PassThru) { [PSFramework.Utility.DynamicContentObject]::Get($item) }
		}
		
		foreach ($item in $Object)
		{
			$item.Value = $Value
			if ($Queue) { $item.ConcurrentQueue($Reset) }
			if ($Stack) { $item.ConcurrentStack($Reset) }
			if ($List) { $item.ConcurrentList($Reset) }
			if ($Dictionary) { $item.ConcurrentDictionary($Reset) }
			
			if ($PassThru) { $item }
		}
	}
}