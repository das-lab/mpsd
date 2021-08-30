





[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null

function getwmiinfo ($svr) {
	
	gwmi -query "select * from
		Win32_ComputerSystem" -computername $svr | 
		 	select Name, Model, Manufacturer, DNSHostName, CurrentTimeZone, 
		 			Domain, NumberOfProcessors, NumberOfLogicalProcessors,
					SystemType, TotalPhysicalMemory, PrimaryOwnerName | export-csv -path .\$svr\BOX_ComputerSystem.csv -noType

	
	gwmi -query "select * from
		Win32_OperatingSystem" -computername $svr | 
		 	select Name, Version, FreePhysicalMemory, OSLanguage, OSProductSuite,
		 			OSType, ServicePackMajorVersion, ServicePackMinorVersion | export-csv -path .\$svr\BOX_OperatingSystem.csv -noType

	


	
	
	gwmi -query "select * from
		Win32_PhysicalMemory" -computername $svr | select Name, Capacity, DeviceLocator,
		Tag | export-csv -path .\$svr\BOX_PhysicalMemory.csv -noType

	
	gwmi -query "select * from Win32_LogicalDisk
		 where DriveType=3" -computername $svr | select Name, FreeSpace,
		 Size | export-csv -path .\$svr\BOX_LogicalDisk.csv -noType
		 
	
			"

}

$Adapters = Get-WmiObject -ComputerName $Target Win32_NetworkAdapterConfiguration
			$IPInfo = @()
			Foreach ($Adapter in ($Adapters | Where {$_.IPEnabled -eq $True})) 
			{
				$Details = "" | Select Description, "Physical address", "IP Address / Subnet Mask", "Default Gateway", "DHCP Enabled", DNS, WINS
				$Details.Description = "$($Adapter.Description)"
				$Details."Physical address" = "$($Adapter.MACaddress)"
				If ($Adapter.IPAddress -ne $Null) {
				$Details."IP Address / Subnet Mask" = "$($Adapter.IPAddress)/$($Adapter.IPSubnet)"
					$Details."Default Gateway" = "$($Adapter.DefaultIPGateway)"
				}
				If ($Adapter.DHCPEnabled -eq "True")	{
					$Details."DHCP Enabled" = "Yes"
				}
				Else {
					$Details."DHCP Enabled" = "No"
				}
				If ($Adapter.DNSServerSearchOrder -ne $Null)	{
					$Details.DNS =  "$($Adapter.DNSServerSearchOrder)"
				}
				$Details.WINS = "$($Adapter.WINSPrimaryServer) $($Adapter.WINSSecondaryServer)"
				$IPInfo += $Details
			}