
[CmdletBinding()]
param (
	[Parameter(Mandatory)]
	[ValidateScript({ Test-Path -Path $_ -PathType 'Leaf' })]
	[string]$FilePath,
	[Parameter()]
	[string]$Arguments,
	[switch]$Force
)

begin {
	$ErrorActionPreference = 'Stop'
	Set-StrictMode -Version Latest
	
	function New-OnBootScheduledTask {
		
		[CmdletBinding()]
		param (
			[Parameter(Mandatory)]
			[string]$Name,
			[Parameter(Mandatory)]
			[ValidateScript({Test-Path -Path $_ -PathType 'Leaf' })]
			[string]$FilePath,
			[Parameter()]
			[string]$Description,
			[Parameter()]
			[string]$Arguments
		)
		process {
			try {
				
				$Service = new-object -ComObject ("Schedule.Service")
				
				
				$Service.Connect()
				$RootFolder = $Service.GetFolder("\")
				
				$TaskDefinition = $Service.NewTask(0)
				$TaskDefinition.RegistrationInfo.Description = $Description
				$TaskDefinition.Settings.Enabled = $true
				$TaskDefinition.Settings.AllowDemandStart = $true
				$TaskDefinition.Settings.DeleteExpiredTaskAfter = 'PT0S'
				
				$Triggers = $TaskDefinition.Triggers
				
				$Trigger = $Triggers.Create(8) 
				$Trigger.Enabled = $true
				
				$TaskEndTime = [datetime]::Now.AddMinutes(30)
				$Trigger.EndBoundary = $TaskEndTime.ToString("yyyy-MM-dd'T'HH:mm:ss")
				
				
				$Action = $TaskDefinition.Actions.Create(0)
				$Action.Path = $FilePath
				$action.Arguments = $Arguments
				
				
				$RootFolder.RegisterTaskDefinition($Name, $TaskDefinition, 6, "System", $null, 5) | Out-Null
			} catch {
				Write-Error $_.Exception.Message
			}
		}
	}
	
	function Test-PendingReboot {
		
		[CmdletBinding()]
		param ()
		process {
			
			try {
				$OperatingSystem = Get-WmiObject -Class Win32_OperatingSystem -Property BuildNumber, CSName
				
				
				If ($OperatingSystem.BuildNumber -ge 6001) {
					$PendingReboot = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing' -Name 'RebootPending' -ErrorAction SilentlyContinue
					if ($PendingReboot) {
						Write-Verbose -Message 'Reboot pending detected in the Component Based Servicing registry key'
						return $true
					}
				}
				
				
				$PendingReboot = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -Name 'RebootRequired' -ErrorAction SilentlyContinue
				if ($PendingReboot) {
					Write-Verbose -Message 'WUAU has a reboot pending'
					return $true
				}
				
				
				$PendingReboot = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue
				if ($PendingReboot -and $PendingReboot.PendingFileRenameOperations) {
					Write-Verbose -Message 'Reboot pending in the PendingFileRenameOperations registry value'
					return $true
				}
			} catch {
				Write-Error $_.Exception.Message
			}
		}
	}
	
	function Request-Restart {
		
		$Title = 'Restart Computer'
		$Message = "The computer is pending a reboot. Shall I reboot now and start the script when it comes back up?"
		$Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Restart the computer now"
		$No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Delay the restart until a later time"
		$Options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No)
		$Result = $Host.ui.PromptForChoice($Title, $Message, $Options, 0)
		switch ($Result) {
			0 { $true }
			1 { $false }
		}
	}
}

process {
	try {
		Write-Verbose -Message 'Checking to see if there are any pending reboot operations'
		if (Test-PendingReboot) { 
			Write-Verbose -Message 'Found a pending reboot operation'
			
			$Params = @{
				'Name' = 'TemporaryBootAction';
				'FilePath' = $FilePath
			}
			if ($Arguments) {
				$Params.Arguments = $Arguments	
			}
			Write-Verbose -Message 'Creating a new on-boot scheduled task'
			New-OnBootScheduledTask @Params
			Write-Verbose 'Created on-boot scheduled task'
			if ($Force.IsPresent) { 
				Write-Verbose -Message 'The force parameter was chosen.  Restarting computer now'
				Restart-Computer -Force
			} elseif (Request-Restart) { 
				Restart-Computer -Force 
			} else { 
				Write-Verbose 'User cancelled the reboot operation but continuing to run script'
				& $FilePath $Arguments
			}
		} else { 
			Write-Verbose -Message 'No reboot operations pending.  Running executable'
			& $FilePath $Arguments
		}
	} catch {
		Write-Error $_.Exception.Message
	}
}