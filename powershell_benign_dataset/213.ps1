function Get-ProcessForeignAddress
{

	PARAM ($ProcessName)
	$netstat = netstat -no

	$Result = $netstat[4..$netstat.count] |
	ForEach-Object {
		$current = $_.trim() -split '\s+'

		New-Object -TypeName PSobject -Property @{
			ProcessName = (Get-Process -id $current[4]).processname
			ForeignAddressIP = ($current[2] -split ":")[0] 
			ForeignAddressPort = ($current[2] -split ":")[1]
			State = $current[3]
		}
	}

	if ($ProcessName)
	{
		$result | Where-Object { $_.processname -like "$processname" }
	}
	else { $Result }
}