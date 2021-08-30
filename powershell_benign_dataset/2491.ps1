


[CmdletBinding()]
param (
	[Parameter(Mandatory = $True,
			ValueFromPipeline = $True,
			ValueFromPipelineByPropertyName = $True)]
	[string]$Computername,
	[Parameter(Mandatory = $False,
			ValueFromPipeline = $False,
			ValueFromPipelineByPropertyName = $False)]
	[string]$ConfigMgrSite = 'UHP',
	[Parameter(Mandatory = $False,
			ValueFromPipeline = $False,
			ValueFromPipelineByPropertyName = $False)]
			[ValidateScript({ Test-Connection $_ -Quiet -Count 1 })]
	[string]$ConfigMgrSiteServer = 'CONFIGMANAGER',
	[Parameter(Mandatory = $False,
			ValueFromPipeline = $False,
			ValueFromPipelineByPropertyName = $False)]
			[ValidateScript({ Test-Path $_ })]
	[string]$WolCmdFilePath = 'wolcmd.exe',
	[Parameter(Mandatory = $False,
			ValueFromPipeline = $False,
			ValueFromPipelineByPropertyName = $False)]
	[switch]$UsePsRemoting = $false,
	[Parameter(Mandatory = $False,
			   ValueFromPipeline = $False,
			   ValueFromPipelineByPropertyName = $False)]
	[string]$KnownGoodWolProxyHostsFilePath = "$($env:USERPROFILE)\desktop\KnownGoodWolProxies.txt"
)

begin {
	
	function ConvertTo-DecimalIP {
	  
		
		[CmdLetBinding()]
		param (
			[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
			[Net.IPAddress]$IPAddress
		)
		
		process {
			$i = 3; $DecimalIP = 0;
			$IPAddress.GetAddressBytes() | ForEach-Object { $DecimalIP += $_ * [Math]::Pow(256, $i); $i-- }
			
			return [UInt32]$DecimalIP
		}
	}
	
	function ConvertTo-DottedDecimalIP {
	  
		
		[CmdLetBinding()]
		param (
			[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
			[String]$IPAddress
		)
		
		process {
			Switch -RegEx ($IPAddress) {
				"([01]{8}.){3}[01]{8}" {
					return [String]::Join('.', $($IPAddress.Split('.') | ForEach-Object { [Convert]::ToUInt32($_, 2) }))
				}
				"\d" {
					$IPAddress = [UInt32]$IPAddress
					$DottedIP = $(For ($i = 3; $i -gt -1; $i--) {
						$Remainder = $IPAddress % [Math]::Pow(256, $i)
						($IPAddress - $Remainder) / [Math]::Pow(256, $i)
						$IPAddress = $Remainder
					})
					
					return [String]::Join('.', $DottedIP)
				}
				default {
					Write-Error "Cannot convert this format"
				}
			}
		}
	}
	
	function Get-NetworkAddress {
	  	
		
		[CmdLetBinding()]
		param (
			[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
			[Net.IPAddress]$IPAddress,
			
			[Parameter(Mandatory = $true, Position = 1)]
			[Alias("Mask")]
			[Net.IPAddress]$SubnetMask
		)
		
		process {
			[pscustomobject]@{ 'NetworkAddress' = (ConvertTo-DottedDecimalIP ((ConvertTo-DecimalIP $IPAddress) -band (ConvertTo-DecimalIP $SubnetMask))) }
		}
	}
	
	function ConvertTo-Mask {
	  
		
		[CmdLetBinding()]
		param (
			[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
			[Alias("Length")]
			[ValidateRange(0, 32)]
			$MaskLength
		)
		
		Process {
			return ConvertTo-DottedDecimalIP ([Convert]::ToUInt32($(("1" * $MaskLength).PadRight(32, "0")), 2))
		}
	}
	
	function Get-NetworkRange([String]$IP, [String]$Mask) {
		if ($IP.Contains("/")) {
			$Temp = $IP.Split("/")
			$IP = $Temp[0]
			$Mask = $Temp[1]
		}
		
		if (!$Mask.Contains(".")) {
			$Mask = ConvertTo-Mask $Mask
		}
		
		$DecimalIP = ConvertTo-DecimalIP $IP
		$DecimalMask = ConvertTo-DecimalIP $Mask
		
		$Network = $DecimalIP -band $DecimalMask
		$Broadcast = $DecimalIP -bor ((-bnot $DecimalMask) -band [UInt32]::MaxValue)
		
		for ($i = $($Network + 1); $i -lt $Broadcast; $i++) {
			ConvertTo-DottedDecimalIP $i
		}
	}
	
	function Get-OfflineComputerNetworkInformation ($Computername) {
		$WmiQuery = "SELECT DISTINCT * 
		FROM SMS_R_System AS sys 
		JOIN SMS_G_System_NETWORK_ADAPTER_CONFIGURATION AS net ON net.ResourceID = sys.ResourceID 
		WHERE sys.Name = '$ComputerName' AND
		net.IPAddress IS NOT NULL"
		
		$WmiParams = @{
			'ComputerName' = $ConfigMgrSiteServer
			'Namespace' = "root\sms\site_$ConfigMgrSite"
			'Query' = $WmiQuery
		}
		
		
		Write-Verbose "Querying site server '$ConfigMgrSiteServer' with query '$WmiQuery'"
		try {
			$Output = @{ }
			$NetworkInfo = Get-WmiObject @WmiParams
			if (!$NetworkInfo) {
				throw "Computer '$Computername' could not be found in the SCCM database"
			} else {
				$NetworkInfo | foreach {
					$Output.IPAddress = [string]([regex]'\b(?:\d{1,3}\.){3}\d{1,3}\b').Matches($_.net.IPAddress)
					$Output.SubnetMask = [string]([regex]'\b(?:\d{1,3}\.){3}\d{1,3}\b').Matches($_.net.IPSubnet)
					$Output.MACAddress = [string](($_.net.MACAddress.replace(":", "")).replace("-", "")).replace(".", "")
				}
			}
			[pscustomobject]$Output
		} catch {
			Write-Error $_.Exception.Message
		}
	}
	
	function Get-LocalIpNetwork {
		Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled = 'True'" | where { $_.IPAddress -and $_.IPSubnet } | foreach {
			[pscustomobject]@{ 'LocalIPNetwork' = (Get-NetworkAddress -IPAddress $_.IPAddress[0] -SubnetMask $_.IPSubnet[0]) }
		}
	}
	
	function Test-Ping {
		param ($ComputerName)
		try {
			$oPing = new-object system.net.networkinformation.ping;
			if (($oPing.Send($ComputerName, 200).Status -eq 'TimedOut')) {
				$false
			} else {
				$true
			}
		} catch [System.Exception] {
			$false
		}
	}
	
	function Test-Wmi ($IpAddress) {
		try {
			$Result = ([WMICLASS]"\\$IpAddress\Root\CIMV2:Win32_Process").create("hostname")
			if ($Result.ReturnValue -eq 0) {
				$true
			} else {
				$false	
			}
		} catch {
			$false
		}
	}
	
	function Validate-IsValidHost ($IpAddress) {
		try {
			Write-Verbose "Testing $IpAddress Ping"
			if (Test-Ping -ComputerName $IpAddress) {
				Write-Verbose "Testing $IpAddress Ping - Success"
				
				
				Write-Verbose "Testing $IpAddress SMB share file copy and removal"
				
				$TestFilePath = "$($env:SystemDrive)\testcopy.txt"
				Add-Content -Path $TestFilePath -Value '' -Force
				Copy-Item -Path $TestFilePath -Destination "\\$IpAddress\c$" -Force
				Remove-Item -Path "\\$IpAddress\c$\testcopy.txt" -Force
				
				Write-Verbose "Testing $IpAddress SMB share file copy and removal - Success"
				Write-Verbose "Testing $IpAddress remote WMI process creation"
				if (Test-Wmi -IpAddress $IpAddress) {
					Write-Verbose "Testing $IpAddress remote WMI process creation - Success"
					Write-Verbose "All tests passed. $IpAddress is a good WOL proxy"
					$true
				} else {
					throw 'Remote process could not be created with WMI'
				}
			} else {
				throw 'Host is offline'
			}
		} catch {
			Write-Warning "Test failed with error '$($_.Exception.Message)' for $IpAddress"
			$false
		}
	}
	
	function Get-WolProxy ($IpAddress, $SubnetMask) {
		
		
		$IpNetwork = Get-NetworkAddress -IPAddress $IpAddress -SubnetMask $SubnetMask
		$KnownGoodWolProxy = Get-KnownGoodWolProxy -IpNetwork $IpNetwork.NetworkAddress
		if ($KnownGoodWolProxy) {
			return $KnownGoodWolProxy
		} else {
			$HostIps = Get-NetworkRange -IP $IpAddress -Mask $SubnetMask
			foreach ($Ip in $HostIps) {
				Write-Verbose "Checking $Ip if good candidate for WOL proxy..."
				
				if (Validate-IsValidHost -IpAddress $Ip) {
					Write-Verbose "WOL Proxy found: $Ip"
					
					
					New-KnownGoodWolProxy -HostProxy @{ 'IpAddress' = $Ip; 'SubnetMask' = $SubnetMask }
					
					return $Ip
				} else {
					Write-Verbose "IP address '$Ip' will not work as a WOL proxy"	
				}
			}
			$false
		}
	}
	
	
	function New-KnownGoodWolProxy ([hashtable]$HostProxy) {
		if (!(Get-KnownGoodWolProxy $HostProxy.IpAddress)) {
			Write-Verbose "The '$($HostProxy.IpAddress)' host is not yet in the known good WOL proxy host file."
			
			$IpNetwork = Get-NetworkAddress -IPAddress $HostProxy.IpAddress -SubnetMask $HostProxy.SubnetMask
			Write-Verbose "Adding IP Address: $($HostProxy.IpAddress) IP Network: $IpNetwork SubnetMask: $($HostProxy.SubnetMask) to known good WOL proxy host file"
			[pscustomobject]@{
				'IpAddress' = $HostProxy.IpAddress;
				'IpNetwork' = $IpNetwork.NetworkAddress;
				'SubnetMask' = $HostProxy.SubnetMask
			} | Export-Csv -Path $KnownGoodWolProxyHostsFilePath -Append -NoTypeInformation
		}
		
	}
	
	function Remove-KnownGoodWolProxy ($IpAddress) {
		$NewCsvContents = Import-Csv -Path $KnownGoodWolProxyHostsFilePath | where { $_.IpAddress -ne $IpAddress }
		
		$NewCsvContents | Export-Csv -Path $KnownGoodWolProxyHostsFilePath -NoTypeInformation
	}
	
	
	function Get-KnownGoodWolProxy ([string]$IpNetwork) {
		if (!(Test-Path $KnownGoodWolProxyHostsFilePath)) {
			Write-Verbose "Known good WOL proxy host file at '$KnownGoodWolProxyHostsFilePath' does not exist"
			$false
		} else {
			$Hosts = Import-Csv -Path $KnownGoodWolProxyHostsFilePath | where { $_.IpNetwork -eq $IpNetwork }
			if (!$Hosts) {
				Write-Verbose "No known good WOL proxy hosts found in IP network '$IpNetwork'"
				$false
			} else {
				$HostsOnNet = $Hosts | where { $_.IpNetwork -eq $IpNetwork }
				if ($HostsOnNet) {
					Write-Verbose "$(($HostsOnNet | measure -Sum -ea silentlycontinue).Count) (unknown accessibility) known good WOL proxy hosts found on IP network '$IpNetwork'"
					Write-Verbose 'Checking previously known good WOL proxy hosts if still usable'
					$AccessibleHost = $HostsOnNet | where { Validate-IsValidHost $_.IpAddress } | select -First 1 -ExpandProperty IpAddress
					if ($AccessibleHost) {
						Write-Verbose "Found hostname '$AccessibleHost' still to be a good WOL proxy host"
						$AccessibleHost
					} else {
						Remove-KnownGoodWolProxy -IpAddress $_.IpAddress
					}
				} else {
					Write-Verbose "No accessible, known good WOL proxy hosts on the '$IpNetwork' found"
				}
			}
		}
	}
	
	function Send-WolPacketLocally ($MacAddress, $IpNetwork, $SubnetMask) {
		& $WolCmdFilePath $MacAddress $IPNetwork $SubnetMask $WolUdpPort 2>&1> $null
	}
	
	function Invoke-WolProxy ($IpAddress, $OfflineMacAddress, $OfflineIpNetwork, $OfflineSubnetMask) {
		
		
		Write-Verbose "Copying $WolCmdFilePath to \\$IpAddress\c`$..."
		Copy-Item $WolCmdFilePath "\\$IpAddress\c$" -Force
		
		$WolCmdString = "C:\$($WolCmdFilePath | Split-Path -Leaf) $OfflineMacAddress $OfflineIPNetwork $OfflineSubnetMask $WolUdpPort"
		Write-Verbose "Initiating the string `"$WolCmdString`"..."
		Write-Verbose "Connecting to $IpAddress and attempting WOL proxy function via WMI RPC method..."
		$Result = ([WMICLASS]"\\$IpAddress\Root\CIMV2:Win32_Process").create($WolCmdString)
		if ($Result) {
			Write-Verbose "Waiting for process ID $($Result.ProcessID) on IP $IpAddress..."
			while (Get-Process -Id $Result.ProcessID -ComputerName $IpAddress -ErrorAction 'SilentlyContinue') {
				sleep 1
			}
			Write-Verbose "Process ID $($Result.ProcessID) has exited"
		} else {
			Write-Warning "Failed to initiate WMI process creation on '$IpAddress'.  Exit code was '$($NewProcess.ReturnValue)'"
		}
		
		
		Write-Verbose 'Cleaning up file remnants on WOL proxy computer...'
		if (Test-Path "\\$IpAddress\c`$\$($WolCmdFilePath | Split-Path -Leaf)") {
			Remove-Item -Path "\\$IpAddress\c`$\$($WolCmdFilePath | Split-Path -Leaf)" -Force
		}
	}
	
	if (Test-Connection -ComputerName $Computername -Quiet -Count 1) {
		Write-Verbose -Message "The computer $Computername is already online"
		return
	}
	
	
	$LocalIPAddressNetworks = Get-LocalIpNetwork
	Write-Verbose "Found $($LocalIPAddressNetworks.Count) local IP networks"
	
	
	$WolUdpPort = 9
	
	$OfflineComputerNetwork = Get-OfflineComputerNetworkInformation $Computername
	
}
process {
	try {
		
		foreach ($Network in $OfflineComputerNetwork) {
			Write-Verbose "Processing IP address $($Network.IPAddress)..."
			Write-Verbose "Checking the remote network to see if it's on any local IP network..."
			$RemoteIpNetwork = Get-NetworkAddress -IPAddress $Network.IpAddress -SubnetMask $Network.SubnetMask
			if ($LocalIPNetworks.LocalIPNetwork -contains $RemoteIpNetwork.NetworkAddress) {
				Write-Verbose 'IP found to be on local subnet. No WOL proxy needed. Sending WOL directly to the intended machine...'
				Send-WolPacketLocally -MacAddress $Network.MacAddress -IpNetwork $RemoteIpNetwork.NetworkAddress -SubnetMask $Network.SubnetMask
			} else {
				Write-Verbose 'IP not found to be on local subnet. Getting WOL proxy computer...'
				$WolProxy = Get-WolProxy -IpAddress $Network.IPAddress -SubnetMask $Network.SubnetMask
				if (!$WolProxy) {
					Write-Warning "Unable to find a WOL proxy for '$Computername'"
				} else {
					Invoke-WolProxy -OfflineIpNetwork $RemoteIpNetwork.NetworkAddress -OfflineMacAddress $Network.MacAddress -OfflineSubnetMask $Network.SubnetMask -IpAddress $WolProxy
				}
			}
		}
	} catch {
		Write-Error $_.Exception.Message
	}
}