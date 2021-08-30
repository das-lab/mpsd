

param(
	$Environment
	)
















switch ($Environment)
	{
	PROD1 {	$Server 		= 'PAPPBO20';
			$BOService 		= 'BOE120SIAPAPPBO20';
			$BOWebService 	= 'W3SVC';
			$BODirectory 	= 'E:\Business Objects\BusinessObjects Enterprise 12.0\Data';
			$BODirOld	 	= 'E:\Business Objects\BusinessObjects Enterprise 12.0\DataOld';
		}
	PROD2 {	$Server 		= 'PAPPBO21';
			$BOService 		= 'BOE120SIAPAPPBO21';
			$BOWebService 	= 'W3SVC';
			$BODirectory 	= 'E:\Business Objects\BusinessObjects Enterprise 12.0\Data';
			$BODirOld	 	= 'E:\Business Objects\BusinessObjects Enterprise 12.0\DataOld';
		}
	IMP {	$Server 		= 'IAPPBO510';
			$BOService 		= 'BOE120SIAIAPPBO510';
			$BOWebService 	= 'W3SVC';
			$BODirectory 	= 'E:\Program Files\Business Objects\BusinessObjects Enterprise 12.0\Data';
			$BODirOld	 	= 'E:\Program Files\Business Objects\BusinessObjects Enterprise 12.0\DataOld';
		}
	}
	

Function BORemoveDataFolder
	{
	param ($Dir);
	$TargetFolder = $Dir;
	if (Test-Path $TargetFolder)
	{
		try 
		{
			Remove-Item $TargetFolder -Recurse;
		}
		catch 
		{
			Write-Host "`tTried to delete $TargetFolder and failed!";
		}
		finally 
		{
			Write-Host "`tThe '$TargetFolder' folder was deleted successfully.";
		}
	}
	Else
		{
			Write-Host "`tThe Folder $TargetFolder does not Exist!";
		}
}

Function StopBOService
	{
	try 
		{
		Stop-Service $BOService;
	}
	catch 
		{
		Write-Host "The $BOService service failed to stop!";
	}
	finally
		{
		Write-Host "`tThe $BOService service was stopped successfully.";
	}
}
	
Function StopBOWebService
	{
	try 
		{
		Stop-Service $BOWebService;
		}
	catch 
		{
		Write-Host "The $BOWebService service failed to stop!";
		}
	finally
		{
		Write-Host "`tThe $BOWebService service was stopped successfully.";
		}
}

Function SendMail
	{
	$emailFrom = $Server + "@dexma.com";
	$emailTo = "outage@dexma.com";
	$subject = $Server + " Data Folder Maintenance";
	$smtpServer = "Outbound.smtp.dexma.com";
	
	$smtp = new-object Net.Mail.SmtpClient($smtpServer);
	$smtp.Send($emailFrom, $emailTo, $subject, $body);
}


$LastDayOfMonth = (Get-Date -Year (Get-Date).Year -Month (Get-Date).Month -Day 1).AddMonths(1).AddDays(-1);
$DateDiff = New-TimeSpan $(Get-Date) $lastDayOfMonth;





if ( (Get-Date).DayOfWeek -eq 'Sunday' ) {
	
	
		Write-Host "Stopping services...";
		StopBOService;
		StopBOWebService;
	
		Write-Host "Moving folder...";
		Move-Item $BODirectory $BODirOld;
	
		Write-Host "Starting Services...";
		Write-Host "`t...$BOService...";
		Start-Service -Name $BOService;
		Write-Host "`t...$BOWebService...";
		Start-Service -Name $BOWebService;
	
		Write-Host "Removing folder..."
		BORemoveDataFolder $BODirOld;
	
		$body = "The " + '"' + "$BODirectory" + '"' + " folder has been deleted to clear the old cache files.";
		SendMail;
}
elseif ( ((Get-Date).Day -eq '1') -or (($DateDiff).days -eq '0') -or (($DateDiff).days -eq '1') ) {
	
		Write-Host "The date is within two days of the end of the month or is the first of the month.";
		Write-Host "Stopping BO service...";
		StopBOService;
	
		Write-Host "Starting BO Service...";
		Write-Host "`t...$BOService...";
		Start-Service -Name $BOService;
	
		$body = "The Server Intelligence Agent " + '"' + "$BOService" + '"' + " service has been restarted for month end reporting availability.";
		SendMail;
}
elseif ( (($DateDiff).days -ge '2') ) {
	Write-Host "The end-of-month date is greater than 2 days away and it is not Sunday.";
	$body = "No changes were made.";
	
}


Write-Host "Verifying services are started......";
Get-Service -ComputerName $Server -Name $BOService;
Get-Service -ComputerName $Server -Name $BOWebService;


