
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