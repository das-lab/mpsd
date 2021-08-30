function Register-PSFMessageTransform
{
	
	[CmdletBinding(PositionalBinding = $false, HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Register-PSFMessageTransform')]
	Param (
		[Parameter(Mandatory = $true, ParameterSetName = "Target")]
		[string]
		$TargetType,
		
		[Parameter(Mandatory = $true, ParameterSetName = "Exception")]
		[string]
		$ExceptionType,
		
		[Parameter(Mandatory = $true)]
		[ScriptBlock]
		$ScriptBlock,
		
		[Parameter(Mandatory = $true, ParameterSetName = "TargetFilter")]
		[string]
		$TargetTypeFilter,
		
		[Parameter(Mandatory = $true, ParameterSetName = "ExceptionFilter")]
		[string]
		$ExceptionTypeFilter,
		
		[Parameter(ParameterSetName = "TargetFilter")]
		[Parameter(ParameterSetName = "ExceptionFilter")]
		$FunctionNameFilter = "*",
		
		[Parameter(ParameterSetName = "TargetFilter")]
		[Parameter(ParameterSetName = "ExceptionFilter")]
		$ModuleNameFilter = "*"
	)
	
	process
	{
		if ($TargetType) { [PSFramework.Message.MessageHost]::TargetTransforms[$TargetType.ToLower()] = $ScriptBlock }
		if ($ExceptionType) { [PSFramework.Message.MessageHost]::ExceptionTransforms[$ExceptionType.ToLower()] = $ScriptBlock }
		
		if ($TargetTypeFilter)
		{
			$condition = New-Object PSFramework.Message.TransformCondition($TargetTypeFilter, $ModuleNameFilter, $FunctionNameFilter, $ScriptBlock, "Target")
			[PSFramework.Message.MessageHost]::TargetTransformList.Add($condition)
		}
		
		if ($ExceptionTypeFilter)
		{
			$condition = New-Object PSFramework.Message.TransformCondition($ExceptionTypeFilter, $ModuleNameFilter, $FunctionNameFilter, $ScriptBlock, "Exception")
			[PSFramework.Message.MessageHost]::ExceptionTransformList.Add($condition)
		}
	}
}