function Unregister-PSFCallback
{

	[CmdletBinding(DefaultParameterSetName = 'Name')]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Name')]
		[string[]]
		$Name,
		
		[Parameter(ValueFromPipeline = $true, ParameterSetName = 'Object', Mandatory = $true)]
		[PSFramework.FlowControl.Callback[]]
		$Callback
	)
	
	process
	{
		foreach ($callbackItem in $Callback)
		{
			[PSFramework.FlowControl.CallbackHost]::Remove($callbackItem)
		}
		foreach ($nameString in $Name)
		{
			foreach ($callbackItem in ([PSFramework.FlowControl.CallbackHost]::Get($nameString, $false)))
			{
				if ($callbackItem.Name -ne $nameString) { continue }
				[PSFramework.FlowControl.CallbackHost]::Remove($callbackItem)
			}
		}
	}
}