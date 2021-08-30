


[CmdletBinding(DefaultParameterSetName = 'Neither')]
param (
    [Parameter(Mandatory)]
    [datetime]$StartTimestamp,
    [Parameter(Mandatory)]
    [datetime]$EndTimestamp,
    [Parameter(ValueFromPipeline,
        ValueFromPipelineByPropertyName)]
	[string]$ComputerName = 'localhost',
	[Parameter()]
	[System.Management.Automation.Credential()]$RunAs = [System.Management.Automation.PSCredential]::Empty,
    [Parameter()]
	[string]$OutputFolderPath = ".\$Computername",
	[Parameter(ParameterSetName = 'LogFiles')]
	[string]$LogAuditFilePath = "$OutputFolderPath\LogActivity.csv",
	[Parameter(ParameterSetName = 'EventLogs')]
	[switch]$EventLogsOnly,
    [Parameter(ParameterSetName = 'LogFiles')]
    [switch]$LogFilesOnly,
    [Parameter(ParameterSetName = 'LogFiles')]
	[string[]]$ExcludeDirectory,
	[Parameter(ParameterSetName = 'LogFiles')]
	[string[]]$FileExtension = @('log', 'txt', 'wer')
)

begin {
	if (!$EventLogsOnly.IsPresent) {
		
		$LogsFolderPath = "$OutputFolderPath\logs"
		if (!(Test-Path $LogsFolderPath)) {
			mkdir $LogsFolderPath | Out-Null
		}
	}
	
	function Add-ToLog($FilePath,$LineText,$LineNumber,$MatchType) {
		$Audit = @{
			'FilePath' = $FilePath;
			'LineText' = $LineText
			'LineNumber' = $LineNumber
			'MatchType' = $MatchType
		}
		[pscustomobject]$Audit | Export-Csv -Path $LogAuditFilePath -Append -NoTypeInformation
	}
}

process {

    
    if (!$LogFilesOnly.IsPresent) {
		
		$Params = @{ 'ComputerName' = $ComputerName; 'ListLog' = '*' }
		if ($RunAs -ne [System.Management.Automation.PSCredential]::Empty) {
			$Params.Credential = $RunAs
		}
		$Logs = (Get-WinEvent @Params | Where-Object { $_.RecordCount }).LogName
		$FilterTable = @{
			'StartTime' = $StartTimestamp
			'EndTime' = $EndTimestamp
			'LogName' = $Logs
		}
		
		
		$Params = @{ 'ComputerName' = $ComputerName; 'FilterHashTable' = $FilterTable; 'ErrorAction' = 'SilentlyContinue' }
		if ($RunAs -ne [System.Management.Automation.PSCredential]::Empty) {
			$Params.Credential = $RunAs
		}
		$Events = Get-WinEvent @Params
		Write-Verbose "Found $($Events.Count) total events"
		
		
		$LogProps = @{ }
		[System.Collections.ArrayList]$MyEvents = @()
		foreach ($Event in $Events) {
			$LogProps.Time = $Event.TimeCreated
			$LogProps.Source = $Event.ProviderName
			$LogProps.EventId = $Event.Id
			if ($Event.Message) {
				$LogProps.Message = $Event.Message.Replace("`n", '|').Replace("`r", '|')
			}
			$LogProps.EventLog = $Event.LogName
			$MyEvents.Add([pscustomobject]$LogProps) | Out-Null
		}
		$MyEvents | Sort-Object Time | Export-Csv -Path "$OutputFolderPath\eventlogs.txt" -Append -NoTypeInformation -Delimiter "`t"
	}
	
	
	if (!$EventLogsOnly.IsPresent) {
        
        
		$Params = @{ 'ComputerName' = $ComputerName; 'Class' = 'Win32_Share' }
		if ($RunAs -ne [System.Management.Automation.PSCredential]::Empty) {
			$Params.Credential = $RunAs
		}
		$Shares = Get-WmiObject @Params | Where-Object { $_.Path -match '^\w{1}:\\$' }
		
		
		if ($ExcludeDirectory) {
			$AllFilesQueryParams.ExcludeDirectory = $ExcludeDirectory	
		}
		
		
		
		$DateTimeRegex = "($($StartTimestamp.Month)[\\.\-/]?$($StartTimestamp.Day)[\\.\-/]?[\\.\-/]$($StartTimestamp.Year))|($($StartTimestamp.Year)[\\.\-/]?$($StartTimestamp.Month)[\\.\-/]?[\\.\-/]?$($StartTimestamp.Day))"
		
		$AllFilesQueryParams = @{
			Recurse = $true
			Force = $true
			ErrorAction = 'SilentlyContinue'
			File = $true
		}
		$PsDrives = @()
		foreach ($Share in $Shares) {
			$DriveName = "$ComputerName - $($Share.Name)"
			Write-Verbose "Creating PS Drive '$DriveName'"
			$Params = @{ 'Name' = $DriveName; 'PSProvider' = 'FileSystem'; 'Root' = "\\$ComputerName\$($Share.Name)" }
			if ($RunAs -ne [System.Management.Automation.PSCredential]::Empty) {
				$Params.Credential = $RunAs
			}
			New-PSDrive @Params | Out-Null
			$PsDrives += "\\$ComputerName\$($Share.Name)"
		}
		$AllFilesQueryParams.Path = $PsDrives
		
		Get-ChildItem @AllFilesQueryParams | Where-Object { $_.Length -ne 0 } | ForEach-Object {
			try {
				Write-Verbose "Processing file '$($_.Name)'"
				
				
				if (($_.LastWriteTime -ge $StartTimestamp) -and ($_.LastWriteTime -le $EndTimestamp)) {
					Write-Verbose "Last write time within timeframe for file '$($_.Name)'"
					Add-ToLog -FilePath $_.FullName -MatchType 'LastWriteTime'
				}
				
				
				if ($FileExtension -contains $_.Extension.Replace('.','') -and !((Get-Content $_.FullName -Encoding Byte -TotalCount 1024) -contains 0)) {
					
					Write-Verbose "Checking log file '$($_.Name)' for date/time match in contents"
					$LineMatches = Select-String -Path $_.FullName -Pattern $DateTimeRegex
					if ($LineMatches) {
						Write-Verbose "Date/time match found in file '$($_.FullName)'"
						
						foreach ($Match in $LineMatches) {
							Add-ToLog -FilePath $_.FullName -LineNumber $Match.LineNumber -LineText $Match.Line -MatchType 'Contents'
						}
						
						
						
						$Trim = $_.FullName.Replace("\\$Computername\", '')
						$Destination = "$OutputFolderPath\$Trim"
						if (!(Test-Path $Destination)) {
							
							mkdir $Destination -ErrorAction SilentlyContinue | Out-Null
						}
						Copy-Item -Path $_.FullName -Destination $Destination -ErrorAction SilentlyContinue -Recurse
					}
				}
			} catch {
				Write-Warning $_.Exception.Message	
			}
		}
	}
}
end {
	
	foreach ($Share in $AccessibleShares) {
		Write-Verbose "Removing PS Drive '$ComputerName-$Share'"
		Remove-PSDrive "$ComputerName-$Share"
	}
}
