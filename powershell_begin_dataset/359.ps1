function Import-PSFCmdlet
{

	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Import-PSFCmdlet')]
	param (
		[Parameter(Mandatory = $true)]
		[String]
		$Name,
		
		[Parameter(Mandatory = $true)]
		[Type]
		$Type,
		
		[string]
		$HelpFile,
		
		[System.Management.Automation.PSModuleInfo]
		$Module
	)
	
	begin
	{
		$scriptBlock = {
			param (
				[String]
				$Name,
				
				[Type]
				$Type,
				
				[string]
				$HelpFile
			)
			
			$sessionStateCmdletEntry = New-Object System.Management.Automation.Runspaces.SessionStateCmdletEntry(
				$Name,
				$Type,
				$HelpFile
			)
			
			
			
			$pipelineType = [PowerShell].Assembly.GetType('System.Management.Automation.Runspaces.LocalPipeline')
			$method = $pipelineType.GetMethod(
				'GetExecutionContextFromTLS',
				[System.Reflection.BindingFlags]'Static,NonPublic'
			)
			
			
			$context = $method.Invoke(
				$null,
				[System.Reflection.BindingFlags]'Static,NonPublic',
				$null,
				$null,
				(Get-Culture)
			)
			
			
			$internalType = [PowerShell].Assembly.GetType('System.Management.Automation.SessionStateInternal')
			
			
			$constructor = $internalType.GetConstructor(
				[System.Reflection.BindingFlags]'Instance,NonPublic',
				$null,
				$context.GetType(),
				$null
			)
			
			
			$sessionStateInternal = $constructor.Invoke($context)
			
			
			$method = $internalType.GetMethod(
				'AddSessionStateEntry',
				[System.Reflection.BindingFlags]'Instance,NonPublic',
				$null,
				$sessionStateCmdletEntry.GetType(),
				$null
			)
			
			$method.Invoke($sessionStateInternal, $sessionStateCmdletEntry)
		}
	}
	
	process
	{
		if (-not $Module) { $scriptBlock.Invoke($Name, $Type, $HelpFile) }
		else { $Module.Invoke($scriptBlock, @($Name, $Type, $HelpFile)) }
	}
}