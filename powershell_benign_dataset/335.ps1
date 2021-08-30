function Resolve-PSFDefaultParameterValue
{

	[OutputType([System.Collections.Hashtable])]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Resolve-PSFDefaultParameterValue')]
	param (
		[Parameter(Mandatory = $true)]
		[System.Collections.Hashtable]
		$Reference,
		
		[Parameter(Mandatory = $true)]
		[string[]]
		$CommandName,
		
		[System.Collections.Hashtable]
		$Target = @{ },
		
		[string[]]
		$ParameterName = "*"
	)
	
	begin
	{
		$defaultItems = @()
		foreach ($key in $Reference.Keys)
		{
			$defaultItems += [PSCustomObject]@{
				Key	    = $key
				Value   = $Reference[$key]
				Command = $key.Split(":")[0]
				Parameter = $key.Split(":")[1]
			}
		}
	}
	process
	{
		foreach ($command in $CommandName)
		{
			foreach ($item in $defaultItems)
			{
				if ($command -notlike $item.Command) { continue }
				
				foreach ($parameter in $ParameterName)
				{
					if ($item.Parameter -like $parameter)
					{
						if ($parameter -ne "*") { $Target["$($command):$($parameter)"] = $item.Value }
						else { $Target["$($command):$($item.Parameter)"] = $item.Value }
					}
				}
			}
		}
	}
	end
	{
		$Target
	}
}