function Register-PSFCallback
{

	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$Name,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$ModuleName,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[string]
		$CommandName,
		
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
		[scriptblock]
		$ScriptBlock,
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[ValidateSet('CurrentRunspace', 'Process')]
		[string]
		$Scope = 'CurrentRunspace',
		
		[Parameter(ValueFromPipelineByPropertyName = $true)]
		[switch]
		$BreakAffinity
	)
	
	process
	{
		$callback = New-Object PSFramework.Flowcontrol.Callback -Property @{
			Name		  = $Name
			ModuleName    = $ModuleName
			CommandName   = $CommandName
			BreakAffinity = $BreakAffinity
			ScriptBlock   = $ScriptBlock
		}
		if ($Scope -eq 'CurrentRunspace') { $callback.Runspace = [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId }
		[PSFramework.FlowControl.CallbackHost]::Add($callback)
	}
}