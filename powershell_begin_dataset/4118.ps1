
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()]
	[string]$Collection,
	[ValidateNotNullOrEmpty()]
	[string]$SQLServer,
	[ValidateNotNullOrEmpty()]
	[string]$SQLDatabase,
	[ValidateNotNullOrEmpty()]
	[string]$DeploymentName,
	[ValidateNotNullOrEmpty()]
	[int]$MaxDays
)

function Initialize-Reboot {

	
	[CmdletBinding()]
	param
	(
		$Object
	)
	
	If ((Test-Connection -ComputerName $Object.Name -Quiet) -eq $true) {
		
		If ((New-TimeSpan -Start ([Management.ManagementDateTimeConverter]::ToDateTime((Get-WmiObject -Class win32_operatingsystem -ComputerName $Object.Name).LastBootUpTime))).Days -gt $MaxDays) {
			
			$Advertisement = Get-WmiObject -Namespace "root\ccm\policy\machine\actualconfig" -Class "CCM_SoftwareDistribution" -ComputerName $Object.Name | Where-Object {$_.PKG_Name -eq $DeploymentName} | Select-Object -Property PKG_PackageID, ADV_AdvertisementID
			
			If ($Advertisement -ne $null) {
				
				$ScheduleID = Get-WmiObject -Namespace "root\ccm\scheduler" -Class "CCM_Scheduler_History" -ComputerName $Object.Name | Where-Object {
					$_.ScheduleID -like "*$($Advertisement.PKG_PackageID)*"
				} | Select-Object -ExpandProperty ScheduleID
				
				$Policy = Get-WmiObject -Namespace "root\ccm\policy\machine\actualconfig" -Class "CCM_SoftwareDistribution" -ComputerName $Object.Name | Where-Object {
					$_.PKG_Name -eq $DeploymentName
				}
				
				If ($Policy.ADV_MandatoryAssignments -eq $false) {
					$Policy.ADV_MandatoryAssignments = $true
					$Policy.Put() | Out-Null
				}
				
				Invoke-WmiMethod -Namespace "root\ccm" -Class "SMS_Client" -Name "TriggerSchedule" -ArgumentList $ScheduleID -ComputerName $Object.Name
				
				Start-Sleep -Seconds 1
				
				$Policy = Get-WmiObject -Namespace "root\ccm\policy\machine\actualconfig" -Class "CCM_SoftwareDistribution" -ComputerName $Object.Name | Where-Object {
					$_.PKG_Name -eq $DeploymentName
				}
				
				If ($Policy.ADV_MandatoryAssignments -eq $true) {
					$Policy.ADV_MandatoryAssignments = $false
					$Policy.Put() | Out-Null
				}
			}
		}
	} else {
		Return $null
	}
	Return $object
}


$TableName = 'dbo.' + ((Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDatabase -Query ('SELECT ResultTableName FROM dbo.v_Collections WHERE CollectionName = ' + [char]39 + $Collection + [char]39)).ResultTableName)

$Query = 'SELECT Name, LastBootUpTime0, ClientState FROM dbo.v_GS_OPERATING_SYSTEM INNER JOIN' + [char]32 + $TableName + [char]32 + 'ON dbo.v_GS_OPERATING_SYSTEM.ResourceID =' + [char]32 + $TableName + '.MachineID WHERE ((((DATEDIFF(DAY,LastBootUpTime0,GETDATE())) >' + [char]32 + $MaxDays + ') OR ClientState <> 0) AND LastBootUpTime0 IS NOT NULL)'

$List = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDatabase -Query $Query

$Report = @()

If ($List -ne '') {
	
	$List | ForEach-Object {
		If ($_.ClientState -ne 0) {
			$PendingReboot = $true
		} else {
			$PendingReboot = $false
		}
		If ((Test-Connection -ComputerName $_.Name -Count 1 -Quiet) -eq $true) {
			$Online = $true
		} else {
			$Online = $false
		}
		
		$object = New-Object -TypeName System.Management.Automation.PSObject
		$object | Add-Member -MemberType NoteProperty -Name Name -Value $_.Name
		$object | Add-Member -MemberType NoteProperty -Name LastBootUpTime -Value $_.LastBootUpTime0
		$object | Add-Member -MemberType NoteProperty -Name PendingReboot -Value $PendingReboot
		$object | Add-Member -MemberType NoteProperty -Name Online -Value $Online
		If ($object.Online -eq $true) {
			$obj = Initialize-Reboot -Object $object
		}
		
		If ($obj -ne $null) {
			$Report += $obj
		}
	}
	If ($Report -eq $null) {
		
		Write-Host "Null"
		Exit 1
	} else {
		Write-Output $Report | Sort-Object LastBootUpTime, Name
	}
} else {
	
	Write-Host "Null"
	Exit 1
}
