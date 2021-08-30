function Stop-PSFFunction
{

	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding(DefaultParameterSetName = 'Message', HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Stop-PSFFunction')]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Message')]
		[string]
		$Message,
		
		[Parameter(Mandatory = $true, ParameterSetName = 'String')]
		[string]
		$String,
		
		[Parameter(ParameterSetName = 'String')]
		[object[]]
		$StringValues,
		
		[bool]
		$EnableException,
		
		[System.Management.Automation.ErrorCategory]
		$Category = ([System.Management.Automation.ErrorCategory]::NotSpecified),
		
		[Alias('InnerErrorRecord')]
		[System.Management.Automation.ErrorRecord[]]
		$ErrorRecord,
		
		[string[]]
		$Tag,
		
		[string]
		$FunctionName,
		
		[string]
		$ModuleName,
		
		[string]
		$File,
		
		[int]
		$Line,
		
		[System.Exception]
		$Exception,
		
		[switch]
		$OverrideExceptionMessage,
		
		[object]
		$Target,
		
		[switch]
		$Continue,
		
		[switch]
		$SilentlyContinue,
		
		[string]
		$ContinueLabel,
		
		[System.Management.Automation.PSCmdlet]
		$Cmdlet,
		
		[int]
		$StepsUpward = 0
	)
	
	if ($Cmdlet) { $myCmdlet = $Cmdlet }
	else { $myCmdlet = $PSCmdlet }
	
	
	$callStack = (Get-PSCallStack)[1]
	if (-not $FunctionName) { $FunctionName = $callStack.Command }
	if (-not $FunctionName) { $FunctionName = "<Unknown>" }
	if (-not $ModuleName) { $ModuleName = $callstack.InvocationInfo.MyCommand.ModuleName }
	if (-not $ModuleName) { $ModuleName = "<Unknown>" }
	if (-not $File) { $File = $callStack.Position.File }
	if (-not $Line) { $Line = $callStack.Position.StartLineNumber }
	if ((Test-PSFParameterBinding -ParameterName EnableException -Not) -and (Test-PSFFeature -Name "PSFramework.InheritEnableException" -ModuleName $ModuleName))
	{
		$EnableException = [bool]$PSCmdlet.GetVariableValue('EnableException')
	}
	
	
	
	
	if ($null -ne $Target)
	{
		$Target = Convert-PsfMessageTarget -Target $Target -FunctionName $FunctionName -ModuleName $ModuleName
	}
	
	
	
	if ($Exception)
	{
		$Exception = Convert-PsfMessageException -Exception $Exception -FunctionName $FunctionName -ModuleName $ModuleName
	}
	elseif ($ErrorRecord)
	{
		$int = 0
		while ($int -lt $ErrorRecord.Length)
		{
			$tempException = Convert-PsfMessageException -Exception $ErrorRecord[$int].Exception -FunctionName $FunctionName -ModuleName $ModuleName
			if ($tempException -ne $ErrorRecord[$int].Exception)
			{
				$ErrorRecord[$int] = New-Object System.Management.Automation.ErrorRecord($tempException, $ErrorRecord[$int].FullyQualifiedErrorId, $ErrorRecord[$int].CategoryInfo.Category, $ErrorRecord[$int].TargetObject)
			}
			
			$int++
		}
	}
	
	
	
	
	$records = @()
	
	$paramWritePSFMessage = @{
		Level				     = 'Warning'
		EnableException		     = $EnableException
		FunctionName			 = $FunctionName
		Target				     = $Target
		Tag					     = $Tag
		ModuleName			     = $ModuleName
		File					 = $File
		Line					 = $Line
	}
	if ($OverrideExceptionMessage) { $paramWritePSFMessage['OverrideExceptionMessage'] = $true }
	if ($Message) { $paramWritePSFMessage["Message"] = $Message }
	else
	{
		$paramWritePSFMessage["String"] = $String
		$paramWritePSFMessage["StringValues"] = $StringValues
	}
	
	if ($ErrorRecord -or $Exception)
	{
		if ($ErrorRecord)
		{
			foreach ($record in $ErrorRecord)
			{
				if (-not $Exception) { $newException = New-Object System.Exception($record.Exception.Message, $record.Exception) }
				else { $newException = $Exception }
				if ($record.CategoryInfo.Category) { $Category = $record.CategoryInfo.Category }
				$records += New-Object System.Management.Automation.ErrorRecord($newException, "$($ModuleName)_$FunctionName", $Category, $Target)
			}
		}
		else
		{
			$records += New-Object System.Management.Automation.ErrorRecord($Exception, "$($ModuleName)_$FunctionName", $Category, $Target)
		}
		
		
		if ($EnableException) { Write-PSFMessage -ErrorRecord $records @paramWritePSFMessage 3>$null }
		else { Write-PSFMessage -ErrorRecord $records @paramWritePSFMessage }
	}
	else
	{
		$exception = New-Object System.Exception($Message)
		$records += New-Object System.Management.Automation.ErrorRecord($Exception, "$($ModuleName)_$FunctionName", $Category, $Target)
		
		
		if ($EnableException) { Write-PSFMessage -ErrorRecord $records @paramWritePSFMessage 3>$null }
		else { Write-PSFMessage -ErrorRecord $records @paramWritePSFMessage }
	}
	
	
	
	if ($EnableException)
	{
		if ($SilentlyContinue)
		{
			foreach ($record in $records) { $myCmdlet.WriteError($record) }
			if ($ContinueLabel) { continue $ContinueLabel }
			else { continue }
		}
		
		
		$psframework_killqueue.Enqueue($callStack.InvocationInfo.GetHashCode())
		
		
		if (-not $Cmdlet) { throw $records[0] }
		else { $Cmdlet.ThrowTerminatingError($records[0]) }
	}
	
	
	
	else
	{
		
		foreach ($record in $records)
		{
			$null = Write-Error -Message $record -Category $Category -TargetObject $Target -Exception $record.Exception -ErrorId "$($ModuleName)_$FunctionName" -ErrorAction Continue 2>&1
		}
		
		if ($Continue)
		{
			if ($ContinueLabel) { continue $ContinueLabel }
			else { continue }
		}
		else
		{
			
			if ($StepsUpward -eq 0) { $psframework_killqueue.Enqueue($callStack.InvocationInfo.GetHashCode()) }
			elseif ($StepsUpward -gt 0) { $psframework_killqueue.Enqueue((Get-PSCallStack)[($StepsUpward + 1)].InvocationInfo.GetHashCode()) }
			return
		}
	}
	
}