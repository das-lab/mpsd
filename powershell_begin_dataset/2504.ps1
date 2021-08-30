


[CmdletBinding()]
param()


cls

[array]$Clients = @();
[array]$Clients = Invoke-SQLCMD -ServerInstance XUTILSQL2 -Database DexmaSites -Query "SELECT DISTINCT dv.dv_value AS DocServer
      , [ce].[DatabaseName]
      , [ce].[DatabaseServer]
FROM    [DexmaSites].dbo.[clients] AS c
		JOIN dexmaSites.dbo.client_data_xref cdx
		ON cdx.[cl_id] = c.[cl_id]
        JOIN dexmaSites.dbo.data_values dv
        ON cdx.dv_id = dv.dv_id
        JOIN dexmaSites.dbo.ClientEnvironment AS ce
        ON ce.[ClientID] = cdx.[cl_id]
WHERE   dv.di_id = 96
        AND [ce].[EnvironmentID] = 13
ORDER BY [ce].[DatabaseName]"

foreach ( $Client in $Clients ) {

Write-Host "Beginning $($Client.DatabaseName)" -ForegroundColor DarkGray

	if (($Client.DocServer -eq "PADoc5") -or ($Client.DocServer -eq "PDocDirect10"))
		{
		Write-Verbose -Message "$($Client.DatabaseName) on $($Client.DocServer) has not been migrated to the new datacenter.";
		}
	else
		{
	Write-Verbose -Message "Beginning $($Client.DatabaseName)";
		
		[array]$CopyFrom = @();
		
		if (Test-Path -Path "\\PDocDirect10\$($Client.DatabaseName)")
			{
			Write-Verbose -Message "`t\\PDocDirect10\$($Client.DatabaseName) found, enumerating files(source).";
			$CopyFrom += @(Get-ChildItem -path "\\PDocDirect10\$($Client.DatabaseName)\Billing\*" ) 
			}
		if (Test-Path -Path "\\PADoc5\$($Client.DatabaseName)")
			{
			Write-Verbose -Message "`t\\PADoc5\$($Client.DatabaseName) folder found, enumerating files(source).";
			$CopyFrom += @(Get-ChildItem -path "\\PADoc5\$($Client.DatabaseName)\Billing\*");
			}
		
		$DestPath = "\\" + $Client.DocServer + "\" + $Client.DatabaseName + "\Billing";
		[array]$CopyTo = @();
		
		if (!(Test-Path -Path $DestPath))
			{
				Write-Verbose -Message "`t$($DestPath) not found!  Creating directory...";
				New-Item -ItemType directory -Path $DestPath;
				if (!(Test-Path -Path $DestPath))
					{
						Write-Verbose -Message "Failed creating $($DestPath)...";
						continue;
					}
				else
					{
					Write-Verbose -Message "`t$($DestPath) created, enumerating files(dest).";
					$CopyTo += @(Get-ChildItem -path "$DestPath\*");
					}
			}
		else
			{
			Write-Verbose -Message "`t$($DestPath) found, enumerating files(dest).";
			$CopyTo += @(Get-ChildItem -path "$DestPath\*");
			}
		
		Write-Verbose -Message "`tComparing directory contents...";
		
		$Files2Copy = Compare-Object -ReferenceObject $CopyFrom -DifferenceObject $CopyTo -Property name, length -PassThru | Where-Object {$_.SideIndicator -eq "<="};

		if ($Files2Copy -ne $NULL)
			{
			foreach ($File in $Files2Copy)
		        {
		        Write-Verbose -Message "`tThis will copy File $($File.FullName) to $DestPath\$($File.Name)";
		        Copy-Item -Path $($File.FullName) -Destination $DestPath\$($File.Name) 
		        }
			}
		else
		    {
		    Write-Verbose -Message "`tNo files to copy for $($Client.DatabaseName)!";
		    }

		if ($Client.DocServer -eq "PDoc1")
			{
				$DropPath = "\\PDoc2\Relateprod\PrimeAlliance\" + $Client.DatabaseName + "\Billing";
			}
		else
			{
				$DropPath = "\\PDoc1\Relateprod\PrimeAlliance\" + $Client.DatabaseName + "\Billing";
			}
		if (Test-Path -Path $DropPath)
			{
				Write-Verbose -Message "`tDropping the $($DropPath) folder!";
				Remove-Item -Recurse -Path $DropPath 
			}
		else
		{
			Write-Verbose -Message "`tNo files to delete for $($Client.DatabaseName)!";
		}
	Write-Verbose -Message "End $($Client.DatabaseName)";
		}
		
Write-Host "End $($Client.DatabaseName)" -ForegroundColor DarkGray
}
