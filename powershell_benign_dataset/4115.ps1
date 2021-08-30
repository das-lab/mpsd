
param
(
	[Parameter(Mandatory = $false)][string]$LogFile = 'ImagedSystems.log',
	[Parameter(Mandatory = $true)][string]$MonitoringHost,
	[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$EmailAddress,
	[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$SMTPServer,
	[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Sender,
	[Parameter(Mandatory = $false)]$MaxImageTime = '02:00:00',
	[Parameter(Mandatory = $false)][int]$DaysSince = 3
)

Function Get-LocalTime {
	param ($UTCTime)
	
	
	Set-Variable -Name LocalTime -Scope Local -Force
	Set-Variable -Name strCurrentTimeZone -Scope Local -Force
	Set-Variable -Name TimeZone -Scope Local -Force
	
	$strCurrentTimeZone = (Get-WmiObject win32_timezone).StandardName
	$TimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById($strCurrentTimeZone)
	$LocalTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($UTCTime, $TimeZone)
	Return $LocalTime
	
	
	Remove-Variable -Name LocalTime -Scope Local -Force
	Remove-Variable -Name strCurrentTimeZone -Scope Local -Force
	Remove-Variable -Name TimeZone -Scope Local -Force
	
}

function Get-MDTData {
	param ($MonitoringHost)
	
	
	Set-Variable -Name Data -Scope Local -Force
	Set-Variable -Name Property -Scope Local -Force
	
	$Data = Invoke-RestMethod $MonitoringHost
	
	foreach ($property in ($Data.content.properties)) {
		New-Object PSObject -Property @{
			Name = $($property.Name);
			PercentComplete = $($property.PercentComplete.’
			Warnings = $($property.Warnings.’
			Errors = $($property.Errors.’
			DeploymentStatus = $(
			Switch ($property.DeploymentStatus.’
				1 { "Active/Running" }
				2 { "Failed" }
				3 { "Successfully completed" }
				Default { "Unknown" }
			}
			);
			StartTime = $($property.StartTime.’
			EndTime = $($property.EndTime.’
		}
	}
	
	
	Remove-Variable -Name Data -Scope Local -Force
	Remove-Variable -Name Property -Scope Local -Force
}

function Get-RelativePath {
	
	Set-Variable -Name RelativePath -Scope Local -Force
	
	$RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $RelativePath
	
	
	Remove-Variable -Name RelativePath -Scope Local -Force
}

function New-Logs {
	param ($LogFile)
	
	
	Set-Variable -Name Temp -Scope Local -Force
	
	if ((Test-Path $LogFile) -eq $false) {
		$Temp = New-Item -Path $LogFile -ItemType file -Force
	}
	
	
	Remove-Variable -Name Temp -Scope Local -Force
}

function New-Report {
	param ($System)
	
	
	Set-Variable -Name Body -Scope Local -Force
	Set-Variable -Name EndTime -Scope Local -Force
	Set-Variable -Name Imaging -Scope Local -Force
	Set-Variable -Name StartTime -Scope Local -Force
	Set-Variable -Name Subject -Scope Local -Force
	
	$StartTime = $System.StartTime
	$StartTime = $StartTime -split " "
	[DateTime]$StartTime = $StartTime[1]
	$StartTime = Get-LocalTime -UTCTime $StartTime
	If ($System.EndTime -eq "") {
		$CurrentTime = Get-Date
		$Imaging = "{2:D2}:{4:D2}:{5:D2}" -f (New-TimeSpan -Start $StartTime -End $CurrentTime).psobject.Properties.Value
		$EndTime = "N/A"
	} else {
		$Imaging = "{2:D2}:{4:D2}:{5:D2}" -f (New-TimeSpan -Start $System.StartTime -End $System.EndTime).psobject.Properties.Value
		$EndTime = $System.EndTime
		$EndTime = $EndTime -split " "
		[DateTime]$EndTime = $EndTime[1]
		$EndTime = Get-LocalTime -UTCTime $EndTime
	}
	Write-Host
	Write-Host "System:"$System.Name
	Write-Host "Deployment Status:"$System.DeploymentStatus
	Write-Host "Completed:"$System.PercentComplete
	Write-Host "Imaging Time:"$Imaging
	Write-Host "Start:" $StartTime
	Write-Host "End:" $EndTime
	Write-Host "Errors:"$System.Errors
	Write-Host "Warnings:"$System.Warnings
	$Subject = "Image Status:" + [char]32 + $System.Name
	$Body = "System:" + [char]32 + $System.Name + [char]13 +`
		"Deployment Status:" + [char]32 + $System.DeploymentStatus + [char]13 +`
		"Completed:" + [char]32 + $System.PercentComplete + "%" + [char]13 +`
		"Start Time:" + [char]32 + $StartTime + [char]13 +`
		"End Time:" + [char]32 + $EndTime + [char]13 +`
		"Imaging Time:" + [char]32 + $Imaging + [char]13 +`
		"Errors:" + [char]32 + $System.Errors + [char]13 +`
		"Warnings:" + [char]32 + $System.Warnings + [char]13
	Send-MailMessage -To $EmailAddress -From $Sender -Subject $Subject -Body $Body -SmtpServer $SMTPServer
	
	
	Remove-Variable -Name Body -Scope Local -Force
	Remove-Variable -Name EndTime -Scope Local -Force
	Remove-Variable -Name Imaging -Scope Local -Force
	Remove-Variable -Name StartTime -Scope Local -Force
	Remove-Variable -Name Subject -Scope Local -Force
}

function Remove-OldSystems {
	param
	(
		[parameter(Mandatory = $true)]$Systems
	)
	
	
	Set-Variable -Name Log -Scope Local -Force
	Set-Variable -Name Logs -Scope Local -Force
	Set-Variable -Name NewLogs -Scope Local -Force
	Set-Variable -Name RelativePath -Scope Local -Force
	Set-Variable -Name System -Scope Local -Force
	
	$NewLogs = @()
	$RelativePath = Get-RelativePath
	$Logs = (Get-Content $LogFile)
	
	foreach ($Log in $Logs) {
		If (($Log -in $Systems.Name)) {
			$System = $Systems | where { $_.Name -eq $Log }
			If (($System.DeploymentStatus -eq "Successfully completed") -or ($System.DeploymentStatus -eq "Failed") -or ($System.DeploymentStatus -eq "Unknown")) {
				$NewLogs = $NewLogs + $Log
			}
		}
	}
	Out-File -FilePath $LogFile -InputObject $NewLogs -Force
	
	
	
	Remove-Variable -Name Log -Scope Local -Force
	Remove-Variable -Name Logs -Scope Local -Force
	Remove-Variable -Name NewLogs -Scope Local -Force
	Remove-Variable -Name RelativePath -Scope Local -Force
	Remove-Variable -Name System -Scope Local -Force
	
}

function Add-NewSystems {
	param
	(
		[parameter(Mandatory = $true)]$Systems
	)
	
	
	Set-Variable -Name CurrentTime -Scope Local -Force
	Set-Variable -Name Imaging -Scope Local -Force
	Set-Variable -Name Log -Scope Local -Force
	Set-Variable -Name Logs -Scope Local -Force
	Set-Variable -Name RelativePath -Scope Local -Force
	Set-Variable -Name StartTime -Scope Local -Force
	Set-Variable -Name System -Scope Local -Force
	Set-Variable -Name SystemName -Scope Local -Force
	
	$RelativePath = Get-RelativePath
	
	$Logs = (Get-Content $LogFile)
	
	foreach ($SystemName in $Systems.Name) {
		If (-not($SystemName -in $Logs)) {
			$System = $Systems | where { $_.Name -eq $SystemName }
			If (($System.DeploymentStatus -eq "Successfully completed") -or ($System.DeploymentStatus -eq "Failed") -or ($System.DeploymentStatus -eq "Unknown")) {
				New-Report -System $System
				Out-File -FilePath $LogFile -InputObject $SystemName -Append -Force
			} else {
				$StartTime = Get-LocalTime -UTCTime $System.StartTime
				$CurrentTime = Get-Date
				$Imaging = "{2:D2}:{4:D2}:{5:D2}" -f (New-TimeSpan -Start $StartTime -End $CurrentTime).psobject.Properties.Value
				If ($Imaging -ge $MaxImageTime) {
					New-Report -System $System
				}
			}
		}
	}

	
	Remove-Variable -Name CurrentTime -Scope Local -Force
	Remove-Variable -Name Imaging -Scope Local -Force
	Remove-Variable -Name Log -Scope Local -Force
	Remove-Variable -Name Logs -Scope Local -Force
	Remove-Variable -Name RelativePath -Scope Local -Force
	Remove-Variable -Name StartTime -Scope Local -Force
	Remove-Variable -Name System -Scope Local -Force
	Remove-Variable -Name SystemName -Scope Local -Force
}


Set-Variable -Name ImagedSystems -Scope Local -Force
Set-Variable -Name RelativePath -Scope Local -Force

cls
$RelativePath = Get-RelativePath
$LogFile = $RelativePath + $LogFile
$MonitoringHost = "http://" + $MonitoringHost + ":9801/MDTMonitorData/Computers"
New-Logs -LogFile $LogFile
$ImagedSystems = Get-MDTData -MonitoringHost $MonitoringHost | Select Name, DeploymentStatus, PercentComplete, Warnings, Errors, StartTime, EndTime | Sort -Property Name

Remove-OldSystems -Systems $ImagedSystems

Add-NewSystems -Systems $ImagedSystems


Remove-Variable -Name ImagedSystems -Scope Local -Force
Remove-Variable -Name RelativePath -Scope Local -Force
