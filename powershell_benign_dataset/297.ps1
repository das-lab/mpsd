function Test-PSFParameterBinding
{
    
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Test-PSFParameterBinding')]
	Param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string[]]
		$ParameterName,
		
		[Alias('Reverse')]
		[switch]
		$Not,
		
		[switch]
		$And,
		
		[ValidateSet('Any', 'Explicit', 'PipeScript')]
		[string]
		$Mode = 'Any',
		
		[object]
		$BoundParameters = (Get-PSCallStack)[0].InvocationInfo.BoundParameters
	)
	
	if ($And)
	{
		$test = $true
	}
	else
	{
		$test = $false
	}
	$pipeScriptForbidden = $Mode -eq "Explicit"
	$explicitForbidden = $Mode -eq "PipeScript"
	
	foreach ($name in $ParameterName)
	{
		$isPipeScript = ($BoundParameters.$name.PSObject.TypeNames -eq 'System.Management.Automation.CmdletParameterBinderController+DelayedScriptBlockArgument') -as [bool]
		if ($And)
		{
			if (-not $BoundParameters.ContainsKey($name))
			{
				$test = $false
				continue
			}
			if ($isPipeScript -and $pipeScriptForbidden) { $test = $false }
			if (-not $isPipeScript -and $explicitForbidden) { $test = $false }
			
		}
		else
		{
			if ($BoundParameters.ContainsKey($name))
			{
				if ($isPipeScript -and -not $pipeScriptForbidden) { $test = $true }
				if (-not $isPipeScript -and -not $explicitForbidden) { $test = $true }
			}
		}
	}
	
	return ((-not $Not) -eq $test)
}
if (-not (Test-Path Alias:Was-Bound)) { Set-Alias -Value Test-PSFParameterBinding -Name Was-Bound -Scope Global }