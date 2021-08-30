function Invoke-PSFCommand
{

	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSPossibleIncorrectUsageOfAssignmentOperator", "")]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/Invoke-PSFCommand')]
	param (
		[PSFComputer[]]
		[Alias('Session')]
		$ComputerName = $env:COMPUTERNAME,
		
		[Parameter(Mandatory = $true)]
		[scriptblock]
		$ScriptBlock,
		
		[object[]]
		$ArgumentList,
		
		[System.Management.Automation.CredentialAttribute()]
		[System.Management.Automation.PSCredential]
		$Credential,
		
		[switch]
		$HideComputerName,
		
		[int]
		$ThrottleLimit = 32
	)
	
	begin
	{
		Write-PSFMessage -Level InternalComment -Message "Bound parameters: $($PSBoundParameters.Keys -join ", ")" -Tag 'debug', 'start', 'param'
		
		
		[array]$broken = $psframework_pssessions.GetBroken()
		foreach ($sessionInfo in $broken)
		{
			Write-PSFMessage -Level Debug -Message "Removing broken session to $($sessionInfo.ComputerName)"
			Remove-PSSession -Session $sessionInfo.Session -ErrorAction Ignore
			$null = $psframework_pssessions.Remove($sessionInfo.ComputerName)
		}
		
		
		
		$paramInvokeCommand = @{
			ScriptBlock	       = $ScriptBlock
			ArgumentList	   = $ArgumentList
			HideComputerName   = $HideComputerName
			ThrottleLimit	   = $ThrottleLimit
		}
		
		$paramInvokeCommandLocal = @{
			ScriptBlock		    = $ScriptBlock
			ArgumentList	    = $ArgumentList
		}
		
	}
	process
	{
		
		$sessionsToInvoke = @()
		$managedSessions = @()
		
		foreach ($computer in $ComputerName)
		{
			if ($computer.Type -eq "PSSession") { $sessionsToInvoke += $computer.InputObject }
			elseif ($sessionObject = $computer.InputObject -as [System.Management.Automation.Runspaces.PSSession]) { $sessionsToInvoke += $sessionObject }
			else
			{
				
				if ($computer.IsLocalHost)
				{
					Write-PSFMessage -Level Verbose -Message "Executing command against localhost" -Target $computer
					Invoke-Command @paramInvokeCommandLocal
					continue
				}
				
				
				
				if ($session = $psframework_pssessions[$computer.ComputerName])
				{
					$sessionsToInvoke += $session.Session
					$managedSessions += $session
					$session.ResetTimestamp()
				}
				
				
				
				else
				{
					Write-PSFMessage -Level Verbose -Message "Establishing connection to $computer" -Target $computer
					try
					{
						if ($Credential) { $pSSession = New-PSSession -ComputerName $computer -Credential $Credential -ErrorAction Stop }
						else { $pSSession = New-PSSession -ComputerName $computer -ErrorAction Stop }
					}
					catch
					{
						Write-PSFMessage -Level Warning -Message "Failed to connect to $computer" -ErrorRecord $_ -Target $computer 3>$null
						Write-Error -ErrorRecord $_
						continue
					}
					
					$session = New-Object PSFramework.ComputerManagement.PSSessioninfo($pSSession)
					$psframework_pssessions[$session.ComputerName] = $session
					$sessionsToInvoke += $session.Session
					$managedSessions += $session
				}
				
			}
		}
		
		
		if ($sessionsToInvoke)
		{
			Write-PSFMessage -Level VeryVerbose -Message "Invoking command against $($sessionsToInvoke.ComputerName -join ', ' )"
			Invoke-Command -Session $sessionsToInvoke @paramInvokeCommand
		}
		
		
		foreach ($session in $managedSessions)
		{
			$session.ResetTimestamp()
		}
		
	}
	end
	{
		
		[array]$expired = $psframework_pssessions.GetExpired()
		foreach ($sessionInfo in $expired)
		{
			Write-PSFMessage -Level Debug -Message "Removing expired session to $($sessionInfo.ComputerName)"
			Remove-PSSession -Session $sessionInfo.Session -ErrorAction Ignore
			$null = $psframework_pssessions.Remove($sessionInfo.ComputerName)
		}
		
	}
}