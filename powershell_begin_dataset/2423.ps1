


[CmdletBinding()]
param (
	[string]$SiteCode = 'UHP',
    [ValidateScript({Test-Connection $_ -Quiet -Count 1})]
	[string]$SiteDbServer = 'CONFIGMANAGER',
	[ValidateScript({ Test-Path $_ -PathType 'Container' })]
	[string]$DestDbBackupFolderPath = '\\sanstoragea\lt_archive\30_Days\ConfigMgr',
	[ValidateScript({ Test-Path $_ -PathType 'Container' })]
	[string]$SrcReportingServicesFolderPath = "\\$SiteDbServer\f$\Sql2012Instance\MSRS11.MSSQLSERVER\Reporting Services",
	[string]$ReportingServicesDbBackupSqlFilePath = "\\$SiteDbServer\c$\ReportingServicesDbBackup.sql",
	[string]$ReportingServicesEncKeyPassword = 'my_password',
	[ValidateScript({ Test-Path $_ -PathType 'Container' })]
	[string]$SrcContentLibraryFolderPath = "\\$SiteDbServer\f$\SCCMContentLib",
	[ValidateScript({ Test-Path $_ -PathType 'Container' })]
	[string]$SrcClientInstallerFolderPath = "\\$SiteDbServer\c$\Program Files\Microsoft Configuration Manager\Client",
	[ValidateScript({ Test-Path $_ -PathType 'Leaf' })]
	[string]$SrcAfterBackupFilePath = "\\$SiteDbServer\c$\Program Files\Microsoft Configuration Manager\inboxes\smsbkup.box\afterbackup.bat",
	[string]$LogFilesFolderPath = "$DestDbBackupFolderPath\Logs",
	[switch]$CheckBackup
)

begin {
	Set-StrictMode -Version Latest
	try {
		
		
		
		function New-ReportingServicesBackupSqlFile($TodayDbDestFolderPath) {
			Add-Content -Value "declare @path1 varchar(100);
			declare @path2 varchar(100);
			SET @path1 = '$TodayDbDestFolderPath\ReportsBackup\ReportServer.bak';
			SET @path2 = '$TodayDbDestFolderPath\ReportsBackup\ReportServerTempDB.bak';
			
			USE ReportServer;
			BACKUP DATABASE REPORTSERVER TO DISK = @path1;
			BACKUP DATABASE REPORTSERVERTEMPDB TO DISK = @path2;
			DBCC SHRINKFILE(ReportServer_log);
			USE ReportServerTempDb;
			DBCC SHRINKFILE(ReportServerTempDB_log);" -Path $ReportingServicesDbBackupSqlFilePath
		}
		
		function Convert-ToLocalFilePath($UncFilePath) {
			$Split = $UncFilePath.Split('\')
			$FileDrive = $Split[3].TrimEnd('$')
			$Filename = $Split[-1]
			$FolderPath = $Split[4..($Split.Length - 2)]
			if ($Split.count -eq 5) {
				"$FileDrive`:\$Filename"
			} else {
				"$FileDrive`:\$FolderPath\$Filename"
			}
		}
		
		Function Get-LocalTime($UTCTime) {
			$strCurrentTimeZone = (Get-WmiObject win32_timezone).StandardName
			$TZ = [System.TimeZoneInfo]::FindSystemTimeZoneById($strCurrentTimeZone)
			$LocalTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($UTCTime, $TZ)
			$LocalTime
		}
		
		if (!(Test-Path $LogFilesFolderPath)) {
			New-Item -Path $LogFilesFolderPath -Type Directory | Out-Null
		}
		$script:MyDate = Get-Date -Format 'MM-dd-yyyy'
		$script:LogFilePath = "$LogFilesFolderPath\$MyDate.log"
		
		
		
		
		function Write-Log($Message) {
			$MyDateTime = Get-Date -Format 'MM-dd-yyyy H:mm:ss'
			Add-Content -Path $script:LogFilePath -Value "$MyDateTime - $Message"
		}
		
		$DefaultBackupFolderPath = "$DestDbBackupFolderPath\$SiteCode" + 'Backup'
		if (!(Test-Path $DefaultBackupFolderPath)) {
			throw "Default backup folder path $DefaultBackupFolderPath does not exist"
		}
		
		if ($CheckBackup.IsPresent) {
			
			
			
			
			
			$BackupFolderLastWriteDate = (Get-ItemProperty $DefaultBackupFolderPath).Lastwritetime.Date
			
			$SuccessMessageId = 5035
			$OneHourAgo = (Get-Date).AddHours(-1)
			Write-Log "One hour ago detected as $OneHourAgo"
			
			$WmiParams = @{
				'ComputerName' = $SiteDbServer;
				'Namespace' = "root\sms\site_$SiteCode";
				'Class' = 'SMS_StatusMessage';
				'Filter' = "Component = 'SMS_SITE_BACKUP' AND MessageId = '$SuccessMessageId'"
			}
			$LastSuccessfulBackup = (Get-WmiObject @WmiParams | sort time -Descending | select -first 1 @{ n = 'DateTime'; e = { $_.ConvertToDateTime($_.Time) } }).DateTime
			$LastSuccessfulBackup = Get-LocalTime $LastSuccessfulBackup
			Write-Log "Last successful backup detected on $LastSuccessfulBackup"
			$IsBackupSuccessful = $LastSuccessfulBackup -gt $OneHourAgo
			
			if (($BackupFolderLastWriteDate -ne (get-date).date) -or !$IsBackupSuccessful) {
				throw 'The backup was not successful. Post-backup procedures not necessary'
			}
		}
		
		$CommonCopyFolderParams = @{
			'Recurse' = $true;
			'Force' = $true;
		}
		
	} catch {
		Write-Log "ERROR: $($_.Exception.Message)"
		exit (10)
	}
}

process {
	try {
		
		
		$Today = (Get-Date).DayOfWeek
		$TodayDbDestFolderPath = "$DestDbBackupFolderPath\$Today"
		if ((Test-Path $TodayDbDestFolderPath -PathType 'Container')) {
			Remove-Item $TodayDbDestFolderPath -Force -Recurse
			Write-Log "Removed $TodayDbDestFolderPath..."
		}
		
		
		Rename-Item $DefaultBackupFolderPath $Today
		
		New-Item -Path "$TodayDbDestFolderPath\ReportsBackup" -ItemType Directory | Out-Null
		
		
		
		
		if (Test-Path $ReportingServicesDbBackupSqlFilePath) {
			Remove-Item $ReportingServicesDbBackupSqlFilePath -Force
		}
		New-ReportingServicesBackupSqlFile $TodayDbDestFolderPath
		Write-Log "Created new SQL file in $TodayDbDestFolderPath..."
		
		
		
		
		Write-Log "Backing up SSRS Databases..."
		$LocalPath = Convert-ToLocalFilePath $ReportingServicesDbBackupSqlFilePath
		$result = Invoke-Command -ComputerName $SiteDbServer -ScriptBlock { sqlcmd -i $using:LocalPath }
		if ($result[-1] -match 'DBCC execution completed') {
			Write-Log 'Successfully backed up SSRS databases'
		} else {
			Write-Log 'WARNING: Failed to backup SSRS databases'
		}
		
		
		
		Write-Log "Exporting SSRS encryption keys..."
		$ExportFilePath = "\\$SiteDbServer\c$\rsdbkey.snk"
		$LocalPath = Convert-ToLocalFilePath $ExportFilePath
		$result = Invoke-Command -ComputerName $SiteDbServer -ScriptBlock { echo y | rskeymgmt -e -f $using:LocalPath -p $using:ReportingServicesEncKeyPassword }
		if ($result[-1] -ne 'The command completed successfully') {
			Write-Log 'WARNING: SSRS keys were not exported!'
		} else {
			Copy-Item $ExportFilePath $TodayDbDestFolderPath -Force
			Write-Log 'Successfully exported and backed up encryption keys.'
		}		
		
		
		Write-Log "Backing up $SrcReportingServicesFolderPath..."
		Copy-Item @CommonCopyFolderParams -Path $SrcReportingServicesFolderPath -Destination "$TodayDbDestFolderPath\ReportsBackup"
		Write-Log "Successfully backed up the $SrcReportingServicesFolderPath folder.."
				
		
		Write-Log "Backing up $SrcContentLibraryFolderPath..."
		Copy-Item @CommonCopyFolderParams -Path $SrcContentLibraryFolderPath -Destination $TodayDbDestFolderPath
		Write-Log "Successfully backed up the $SrcContentLibraryFolderPath folder.."
		
		
		Write-Log "Backing up $SrcClientInstallerFolderPath..."
		Copy-Item @CommonCopyFolderParams -Path $SrcClientInstallerFolderPath -Destination $TodayDbDestFolderPath
		Write-Log "Successfully backed up the $SrcClientInstallerFolderPath folder.."
		
		
		
		
		
		
		
		
		
		Write-Log "Backing up $SrcAfterBackupFilePath.."
		Copy-Item @CommonCopyFolderParams -Path $SrcAfterBackupFilePath -Destination $TodayDbDestFolderPath
		Write-Log "Successfully backed up the $SrcAfterBackupFilePath file..."
		
	} catch {
		Write-Log "ERROR: $($_.Exception.Message)"
	}
}

end {
	Write-Log 'Emailing results of backup...'
	
	$Params = @{
		'From' =  'ConfigMgr Backup <abertram@domain.org>';
		'To' = 'Adam Bertram <adbertram@gmail.com>';
		'Subject' = 'ConfigMgr Backup';
		'Attachment' =  $script:LogFilePath;
		'SmtpServer' = 'smtp.domain.com'
	}
	
	Send-MailMessage @Params -Body 'ConfigMgr Backup Email'
}