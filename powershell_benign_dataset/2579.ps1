

[CmdletBinding()]
param
	(
	[xml]$config = (Get-Content E:\Dexma\support\Sync-DBBackups-config.ps1)
	)


cls

foreach ( $Client in $config.clients.client ) {	

Write-Host "Begin $($Client.Name)." -ForegroundColor DarkGray

$BAKSourcePath = '\\' + $Client.SourceDBServer + '\e$\MSSQL10.MSSQLSERVER\MSSQL\BAK\'
$BAKDestPath = '\\' + $Client.DestDBServer + '\e$\MSSQL10.MSSQLSERVER\MSSQL\BAK\'
$ClientSrcPath = $BAKSourcePath + $Client.Name + '\'


if (!(Test-Path -Path $ClientSrcPath))
	{
	Write-Verbose -Message  "$($ClientSrcPath) not found"
	$CopyFrom = @();
	}
ELSE 
	{
	Write-Verbose -Message  "Found source directory: $($ClientSrcPath)"

	$CopyFrom = @(Get-ChildItem -path "$ClientSrcPath*.bak" )
	

	$ClientDestPath = $BAKDestPath + $Client.Name + '\'

	if (!(Test-Path -Path $ClientDestPath)) 
		{
		Write-Verbose -Message  "Creating directory $($ClientDestPath)"
		try {New-Item -ItemType directory -Path $ClientDestPath -ErrorAction Stop}
		
		catch {$_; $CopyTo = @(); Write-Host "End $($Client.Name)." -ForegroundColor DarkGray; continue;}
		}
		
	Write-Verbose -Message  "ClientDestPath: $($ClientDestPath)"
	
	$CopyTo = @(Get-ChildItem -path "$ClientDestPath*.bak")

	$Files2Copy = Compare-Object -ReferenceObject $CopyFrom -DifferenceObject $CopyTo -Property name, length -PassThru | Where-Object {$_.SideIndicator -eq "<="}

	if ($Files2Copy -ne $NULL)
		{
		Write-Verbose -Message  "Files2Copy: $($Files2Copy)"
		try
			{
			foreach ($File in $Files2Copy)
		        {
		        Write-Verbose -Message  "This will copy File $($File.FullName) to $($ClientDestPath)$($File.Name)"
				Copy-Item -Path $($File.FullName) -Destination $ClientDestPath$($File.Name) -ErrorAction Stop
		        }
			}
		catch {$_.Exception;}
		}
	else
	    {
	    Write-Verbose -Message  "No files to copy for $($Client.Name)"
	    }

	$Files2Delete = Compare-Object -ReferenceObject $CopyFrom -DifferenceObject $CopyTo -IncludeEqual -Property name, length -PassThru | Where-Object {$_.SideIndicator -eq "=>"}

	if ($Files2Delete -ne $NULL)
		{
		Write-Verbose -Message  "Files2Delete: $($Files2Delete)"
		try 
			{
			foreach ($File in $Files2Delete)
		    	{
		        Write-Verbose -Message  "This will delete File $($File.FullName)"
		        Remove-Item -Path $($File.FullName)
		        }
			}
		catch {Write-Host "Failed deleting $($File.FullName)" -ForegroundColor DarkRed; $_.Exception;}
		}
	else
	    {
	    Write-Verbose -Message  "No files to delete for $($Client.Name)"
	    }
	}
Write-Host "End $($Client.Name)." -ForegroundColor DarkGray
}