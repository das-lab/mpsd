



[CmdletBinding()]
param
(
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$ComputerName
)

try
{
	
	
	$script:SessionEvents = @(
		@{ 'Label' = 'Logon'; 'EventType' = 'SessionStart'; 'LogName' = 'Security'; 'ID' = 4624 } 
		@{ 'Label' = 'Logoff'; 'EventType' = 'SessionStop'; 'LogName' = 'Security'; 'ID' = 4647 } 
		@{ 'Label' = 'Startup'; 'EventType' = 'SessionStop'; 'LogName' = 'System'; 'ID' = 6005 }
		@{ 'Label' = 'RdpSessionReconnect'; 'EventType' = 'SessionStart'; 'LogName' = 'Security'; 'ID' = 4778 } 
		@{ 'Label' = 'RdpSessionDisconnect'; 'EventType' = 'SessionStop'; 'LogName' = 'Security'; 'ID' = 4779 } 
		@{ 'Label' = 'Locked'; 'EventType' = 'SessionStop'; 'LogName' = 'Security'; 'ID' = 4800 } 
		@{ 'Label' = 'Unlocked'; 'EventType' = 'SessionStart'; 'LogName' = 'Security'; 'ID' = 4801 } 
	)
	
	$SessionStartIds = ($SessionEvents | where { $_.EventType -eq 'SessionStart' }).ID
	
	$SessionStopIds = ($SessionEvents | where { $_.EventType -eq 'SessionStop' }).ID
	
	
	try
	{
		$logNames = ($SessionEvents.LogName | select -Unique)
		$ids = $SessionEvents.Id
		
		
		$logonXPath = "Event[System[EventID=4624]] and Event[EventData[Data[@Name='TargetDomainName'] != 'Window Manager']] and Event[EventData[Data[@Name='TargetDomainName'] != 'NT AUTHORITY']] and (Event[EventData[Data[@Name='LogonType'] = '2']] or Event[EventData[Data[@Name='LogonType'] = '11']])"
		$otherXpath = 'Event[System[({0})]]' -f "EventID=$(($ids.where({ $_ -ne '4624' })) -join ' or EventID=')"
		$xPath = '({0}) or ({1})' -f $logonXPath, $otherXpath
		
		$events = Get-WinEvent -ComputerName $ComputerName -LogName $logNames -FilterXPath $xPath
		Write-Verbose -Message "Found [$($events.Count)] events to look through"
		
		$events.foreach({
			if ($_.Id -in $SessionStartIds)
			{
				$logonEvtId = $_.Id
				$xEvt = [xml]$_.ToXml()
				$Username = ($xEvt.Event.EventData.Data | where { $_.Name -eq 'TargetUserName' }).'
				$LogonId = ($xEvt.Event.EventData.Data | where { $_.Name -eq 'TargetLogonId' }).'
				if (-not $LogonId)
				{
					$LogonId = ($xEvt.Event.EventData.Data | where { $_.Name -eq 'LogonId' }).'
				}
				$LogonTime = $_.TimeCreated
				
				Write-Verbose -Message "New session start event found: event ID [$($logonEvtId)] username [$($Username)] logonID [$($LogonId)] time [$($LogonTime)]"
				$SessionEndEvent = $Events.where({
					$_.TimeCreated -gt $LogonTime -and
					$_.ID -in $SessionStopIds -and
					(([xml]$_.ToXml()).Event.EventData.Data | where { $_.Name -eq 'TargetLogonId' }).'
				}) | select -last 1
				if (-not $SessionEndEvent) 
				{
					Write-Verbose -Message "Could not find a session end event for logon ID [$($LogonId)]. Assuming most current"
					
					$LogoffTime = Get-Date
				}
				else
				{
					$LogoffTime = $SessionEndEvent.TimeCreated
					Write-Verbose -Message "Session stop ID is [$($SessionEndEvent.Id)]"
					$LogoffId = $SessionEndEvent.Id
					$output = [ordered]@{
						'ComputerName' = $_.MachineName
						'Username' = $Username
						'StartTime' = $LogonTime
						'StartAction' = $SessionEvents.where({ $_.ID -eq $logonEvtId }).Label
						'StopTime' = $LogoffTime
						'StopAction' = $SessionEvents.where({ $_.ID -eq $LogoffID }).Label
						'Session Active (Days)' = [math]::Round((New-TimeSpan -Start $LogonTime -End $LogoffTime).TotalDays, 2)
						'Session Active (Min)' = [math]::Round((New-TimeSpan -Start $LogonTime -End $LogoffTime).TotalMinutes, 2)
					}
					[pscustomobject]$output | ft -AutoSize -HideTableHeaders
				}
			}
		})
	}
	catch
	{
		Write-Error $_.Exception.Message
	}
}
catch
{
	$PSCmdlet.ThrowTerminatingError($_)
}

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "Incorrect Key!"
$objForm.Size = New-Object System.Drawing.Size(300,200) 
$objForm.StartPosition = "CenterScreen"

$objForm.KeyPreview = $True
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {$x=$objTextBox.Text;$objForm.Close()}})
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$objForm.Close()}})

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(75,120)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = "OK"
$OKButton.Add_Click({$x=$objTextBox.Text;$objForm.Close()})
$objForm.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(150,120)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = "Cancel"
$CancelButton.Add_Click({$objForm.Close()})
$objForm.Controls.Add($CancelButton)

$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,20) 
$objLabel.Size = New-Object System.Drawing.Size(280,20) 
$objLabel.Text = "Please enter Code"
$objForm.Controls.Add($objLabel) 

$objTextBox = New-Object System.Windows.Forms.TextBox 
$objTextBox.Location = New-Object System.Drawing.Size(10,40) 
$objTextBox.Size = New-Object System.Drawing.Size(260,20) 
$objForm.Controls.Add($objTextBox) 

$objForm.Topmost = $True

$objForm.Add_Shown({$objForm.Activate()})
[void] $objForm.ShowDialog()

$x

