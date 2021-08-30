function Invoke-Sniffer
{


param( [String]$LocalIP = "NotSpecified", [String]$ScanIP="all", [String]$Protocol = "all", `
		[String]$Port="all", [Int]$Seconds = 0, [switch]$ResolveHosts, [switch]$Help, [String]$OutputFile, $MaxSize)


if( $Help )
{
	Write-Output "usage: $($MyInvocation.MYCommand) [-OutputFile <String>] [-LocalIP <String>] [-ScanIP <String>] [-Protocol <String>] [-Port <String>] [-Seconds <Int32>] [-ResolveHosts]"
	exit -1
}


if (!$OutputFile){
    if (!(Test-Path -Path C:\Temp)) 
    {
        New-Item C:\Temp -type directory
    }
    $OutputFile = "C:\Temp\Dump.txt"
}

if (!$MaxSize)
{
    $MaxSize = 100MB
}

$starttime = Get-Date
$byteIn = New-Object Byte[] 4			
$byteOut = New-Object Byte[] 4			
$byteData = New-Object Byte[] 4096		

$byteIn[0] = 1  						
$byteIn[1-3] = 0
$byteOut[0-3] = 0


$TCPFIN = [Byte]0x01
$TCPSYN = [Byte]0x02
$TCPRST = [Byte]0x04
$TCPPSH = [Byte]0x08
$TCPACK = [Byte]0x10
$TCPURG = [Byte]0x20



Function NetworkToHostUInt16( $address )
{
	[Array]::Reverse( $address )
	return [BitConverter]::ToUInt16( $address, 0 )
}


Function NetworkToHostUInt32( $address )
{
	[Array]::Reverse( $address )
	return [BitConverter]::ToUInt32( $address, 0 )
}


Function ByteToString( $address )
{
	$AsciiEncoding = New-Object System.Text.ASCIIEncoding
	return $AsciiEncoding.GetString( $address )
}



$hosts = @{} 							
Function resolve( $IPAddress )
{
	if( $data = $hosts."$($IPAddress.IPAddressToString)" )
	{
		if( $IPAddress.IPAddressToString -eq $data )
		{
			return [System.Net.IPAddress]$IPAddress
		}
		else
		{
			return $data
		}
	}
	else
	{	
		$null,$null,$null,$data = nslookup $IPAddress.IPAddressToString 2>$null
		$data = $data -match "Name:"
		if( $data -match "Name:" )
		{
			$data = $data[0] -replace "Name:\s+",""
			$hosts."$($IPAddress.IPAddressToString)" = "$data"
			return $data
		}
		else
		{
			$hosts."$($IPAddress.IPAddressToString)" = "$($IPAddress.IPAddressToString)"
			return $IPAddress
		}
	}
}



$servicesFilePath = "$env:windir\System32\drivers\etc\services"            

$serviceFile = [IO.File]::ReadAllText("$env:windir\System32\drivers\etc\services") -split

([Environment]::NewLine) -notlike "


Function getService( $port )
{
	$protocols = foreach( $line in $serviceFile )
	{            
		
		if( -not $line )	{ continue }

		
		$serviceName, $portAndProtocol, $aliasesAndComments = $line.Split(' ', [StringSplitOptions]'RemoveEmptyEntries')
		
		$portNumber, $protocolName = $portAndProtocol.Split("/")            

		if( $portNumber -eq $port )
		{
			return $serviceName
		}
	}
}



if( $LocalIP -eq "NotSpecified" )
{
	route print 0* |
	%{ 
		if( $_ -match "\s{2,}0\.0\.0\.0" )
		{ 
			$null,$null,$null,$LocalIP,$null = [regex]::replace($_.trimstart(" "),"\s{2,}",",").split(",")
		}
	}
}
Write-Output "Local IP: $LocalIP" | Out-File $outputfile -Append
Write-Output "ProcessID: $PID" | Out-File $outputfile -Append
Write-Output "" | Out-File $outputfile -Append



$Socket = New-Object System.Net.Sockets.Socket( [Net.Sockets.AddressFamily]::InterNetwork, [Net.Sockets.SocketType]::Raw, [Net.Sockets.ProtocolType]::IP )

$Socket.SetSocketOption( "IP", "HeaderIncluded", $true )

$Socket.ReceiveBufferSize = 1024000

$Endpoint = New-Object System.Net.IPEndpoint( [Net.IPAddress]"$LocalIP", 0 )
$Socket.Bind( $Endpoint )

[void]$Socket.IOControl( [Net.Sockets.IOControlCode]::ReceiveAll, $byteIn, $byteOut )

Write-Output "Press ESC to stop the packet sniffer ..." | Out-File $outputfile -Append
Write-Output "" | Out-File $outputfile -Append
$escKey = 27
$running = $true



$packets = @()							
while( $running )
{
	
	if( $host.ui.RawUi.KeyAvailable )
	{
		$key = $host.ui.RawUI.ReadKey( "NoEcho,IncludeKeyUp,IncludeKeyDown" )
		
		if( $key.VirtualKeyCode -eq $ESCkey )
		{
			$running = $false
		}
	}
	
	if( $Seconds -ne 0 -and ($([DateTime]::Now) -gt $starttime.addseconds($Seconds)) )
	{
		exit
	}
	
	if( -not $Socket.Available )
	{
		start-sleep -milliseconds 300
		continue
	}
	
	
	$rData = $Socket.Receive( $byteData, 0, $byteData.length, [Net.Sockets.SocketFlags]::None )
	
	$MemoryStream = New-Object System.IO.MemoryStream( $byteData, 0, $rData )
	$BinaryReader = New-Object System.IO.BinaryReader( $MemoryStream )

	
	$VerHL = $BinaryReader.ReadByte( )
	
	$TOS= $BinaryReader.ReadByte( )
	
	$Length = NetworkToHostUInt16 $BinaryReader.ReadBytes( 2 )
	
	$Ident = NetworkToHostUInt16 $BinaryReader.ReadBytes( 2 )
	
	$FlagsOff = NetworkToHostUInt16 $BinaryReader.ReadBytes( 2 )
	
	$TTL = $BinaryReader.ReadByte( )
	
	$ProtocolNumber = $BinaryReader.ReadByte( )
	
	$Checksum = [Net.IPAddress]::NetworkToHostOrder( $BinaryReader.ReadInt16() )
	
	$SourceIP = $BinaryReader.ReadUInt32( )
	$SourceIP = [System.Net.IPAddress]$SourceIP
	
	$DestinationIP = $BinaryReader.ReadUInt32( )
	$DestinationIP = [System.Net.IPAddress]$DestinationIP

	
	$ipVersion = [int]"0x$(('{0:X}' -f $VerHL)[0])"
	
	$HeaderLength = [int]"0x$(('{0:X}' -f $VerHL)[1])" * 4

	
	if($HeaderLength -gt 20)
	{
		[void]$BinaryReader.ReadBytes( $HeaderLength - 20 )  
	}
	
	$Data = ""
	$TCPFlagsString = @()  				
	$TCPWindow = ""
	$SequenceNumber = ""
	
	switch( $ProtocolNumber )
	{
		1 {  
			$ProtocolDesc = "ICMP"
			$sourcePort = [uint16]0
			$destPort = [uint16]0
			$ICMPType = $BinaryReader.ReadByte()
			$ICMPCode = $BinaryReader.ReadByte()
			switch( $ICMPType )
			{
				0	{	$ICMPTypeDesc = "Echo reply"; break }
				3	{	$ICMPTypeDesc = "Destination unreachable"
						switch( $ICMPCode )
						{
							0	{	$ICMPCodeDesc = "Network not reachable"; break }
							1	{	$ICMPCodeDesc = "Host not reachable"; break }
							2	{	$ICMPCodeDesc = "Protocol not reachable"; break }
							3	{	$ICMPCodeDesc = "Port not reachable"; break }
							4	{	$ICMPCodeDesc = "Fragmentation needed"; break }
							5	{	$ICMPCodeDesc = "Route not possible"; break }
							13	{	$ICMPCodeDesc = "Administratively not possible"; break }
							default	{	$ICMPCodeDesc = "Other ($_)" }
						}
						break
				}
				4	{	$ICMPTypeDesc = "Source quench"; break }
				5	{	$ICMPTypeDesc = "Redirect"; break }
				8	{	$ICMPTypeDesc = "Echo request"; break }
				9	{	$ICMPTypeDesc = "Router advertisement"; break }
				10	{	$ICMPTypeDesc = "Router solicitation"; break }
				11	{	$ICMPTypeDesc = "Time exceeded"
						switch( $ICMPCode )
						{
							0	{	$ICMPCodeDesc = "TTL exceeded"; break }
							1	{	$ICMPCodeDesc = "While fragmenting exceeded"; break }
							default	{	$ICMPCodeDesc = "Other ($_)" }
						}
						break
				}
				12	{	$ICMPTypeDesc = "Parameter problem"; break }
				13	{	$ICMPTypeDesc = "Timestamp"; break }
				14	{	$ICMPTypeDesc = "Timestamp reply"; break }
				15	{	$ICMPTypeDesc = "Information request"; break }
				16	{	$ICMPTypeDesc = "Information reply"; break }
				17	{	$ICMPTypeDesc = "Address mask request"; break }
				18	{	$ICMPTypeDesc = "Address mask reply"; break }
				30	{	$ICMPTypeDesc = "Traceroute"; break }
				31	{	$ICMPTypeDesc = "Datagram conversion error"; break }
				32	{	$ICMPTypeDesc = "Mobile host redirect"; break }
				33	{	$ICMPTypeDesc = "Where-are-you"; break }
				34	{	$ICMPTypeDesc = "I-am-here"; break }
				35	{	$ICMPTypeDesc = "Mobile registration request"; break }
				36	{	$ICMPTypeDesc = "Mobile registration reply"; break }
				37	{	$ICMPTypeDesc = "Domain name request"; break }
				38	{	$ICMPTypeDesc = "Domain name reply"; break }
				39	{	$ICMPTypeDesc = "SKIP"; break }
				40	{	$ICMPTypeDesc = "Photuris"; break }
				41	{	$ICMPTypeDesc = "Experimental mobility protocol"; break }
				default	{	$ICMPTypeDesc = "Other ($_)" }
			}
			$ICMPChecksum = [System.Net.IPAddress]::NetworkToHostOrder($BinaryReader.ReadInt16())
			$Data = ByteToString $BinaryReader.ReadBytes($Length - ($HeaderLength - 32))
			break
			}
		2 {  
			$ProtocolDesc = "IGMP"
			$sourcePort = [uint16]0
			$destPort = [uint16]0
			$IGMPType = $BinaryReader.ReadByte()
			$IGMPMaxRespTime = $BinaryReader.ReadByte()
			$IGMPChecksum = [System.Net.IPAddress]::NetworkToHostOrder($BinaryReader.ReadInt16())
			$Data = ByteToString $BinaryReader.ReadBytes($Length - ($HeaderLength - 32))
			break
			}
		6 {  
			$ProtocolDesc = "TCP"
			$sourcePort = NetworkToHostUInt16 $BinaryReader.ReadBytes(2)
			$destPort = NetworkToHostUInt16 $BinaryReader.ReadBytes(2)
			$serviceDesc = getService( $destPort )
			$SequenceNumber = NetworkToHostUInt32 $BinaryReader.ReadBytes(4)
			$AckNumber = NetworkToHostUInt32 $BinaryReader.ReadBytes(4)
			$TCPHeaderLength = [int]"0x$(('{0:X}' -f $BinaryReader.ReadByte())[0])" * 4
			$TCPFlags = $BinaryReader.ReadByte()
			switch( $TCPFlags )
			{
				{ $_ -band $TCPFIN }	{ $TCPFlagsString += "<FIN>" }
				{ $_ -band $TCPSYN }	{ $TCPFlagsString += "<SYN>" }
				{ $_ -band $TCPRST }	{ $TCPFlagsString += "<RST>" }
				{ $_ -band $TCPPSH }	{ $TCPFlagsString += "<PSH>" }
				{ $_ -band $TCPACK }	{ $TCPFlagsString += "<ACK>" }
				{ $_ -band $TCPURG }	{ $TCPFlagsString += "<URG>" }
			}
			$TCPWindow = NetworkToHostUInt16 $BinaryReader.ReadBytes(2)
			$TCPChecksum = [System.Net.IPAddress]::NetworkToHostOrder($BinaryReader.ReadInt16())
			$TCPUrgentPointer = NetworkToHostUInt16 $BinaryReader.ReadBytes(2)
			if( $TCPHeaderLength -gt 20 )  
			{
				[void]$BinaryReader.ReadBytes($TCPHeaderLength - 20)
			}
			
			if ($TCPFlags -band $TCPSYN)
			{
				$ISN = $SequenceNumber
				
				[void]$BinaryReader.ReadBytes(1)
			}
			$Data = ByteToString $BinaryReader.ReadBytes($Length - ($HeaderLength + $TCPHeaderLength))
			break
			}
		17 {  
			$ProtocolDesc = "UDP"
			$sourcePort = NetworkToHostUInt16 $BinaryReader.ReadBytes(2)
			$destPort = NetworkToHostUInt16 $BinaryReader.ReadBytes(2)
			$serviceDesc = getService( $destPort )
			$UDPLength = NetworkToHostUInt16 $BinaryReader.ReadBytes(2)
			[void]$BinaryReader.ReadBytes(2)
			
			$Data = ByteToString $BinaryReader.ReadBytes(($UDPLength - 2) * 4)
			break
			}
		default {
			$ProtocolDesc = "Other ($_)"
			$sourcePort = 0
			$destPort = 0
			}
	}
	
	$BinaryReader.Close( )
	$memorystream.Close( )
	$Data = $Data.toCharArray( 0, $Data.length )

	
	if( $ResolveHosts )
	{
		
		$DestinationHostName = resolve( $DestinationIP )
		
		$SourceHostName = resolve( $SourceIP )
	}

	if( ($Protocol -eq "all") -or ($Protocol -eq $ProtocolDesc) )
	{
		if( ($Port -eq "all") -or ($Port -eq $sourcePort) -or ($Port -eq $destPort) )
		{
			if( ($ScanIP -eq "all") -or ($ScanIP -eq $SourceIp) -or ($ScanIP -eq $DestinationIP) )
			
			{
                if ((get-item $outputfile).length -gt $MaxSize)
                {
                    $running = $false
                }
				Write-Output "Time:`t`t$(get-date)" | Out-File $outputfile -Append
				Write-Output "Version:`t$ipVersion`t`t`tProtocol:`t$ProtocolNumber = $ProtocolDesc" | Out-File $outputfile -Append
				Write-Output "Destination:`t$DestinationIP`t`tSource:`t`t$SourceIP" | Out-File $outputfile -Append
				if( $ResolveHosts )
				{
					Write-Output "DestinationHostName`t$DestinationHostName`tSourceHostName`t$SourceHostName" | Out-File $outputfile -Append
				}
				Write-Output "DestPort:`t$destPort`t`t`tSourcePort:`t$sourcePort" | Out-File $outputfile -Append
				switch( $ProtocolDesc )
				{
					"ICMP"	{
							Write-Output "Type:`t`t$ICMPType`t`t`tDescription:`t$ICMPTypeDesc" | Out-File $outputfile -Append
							Write-Output "Code:`t`t$ICMPCode`t`t`tDescription:`t$ICMPCodeDesc" | Out-File $outputfile -Append
							break
						}
					"IGMP"	{
							Write-Output "Type:`t`t$IGMPType`t`t`tMaxRespTime:`t$($IGMPMaxRespTime*100)ms" | Out-File $outputfile -Append
							break
						}
					"TCP"	{
							Write-Output "Sequence:`t$SequenceNumber`t`tAckNumber:`t$AckNumber" | Out-File $outputfile -Append
							Write-Output "Window:`t`t$TCPWindow`t`t`tFlags:`t`t$TCPFlagsString" | Out-File $outputfile -Append
							Write-Output "Service:`t$serviceDesc" | Out-File $outputfile -Append
							break
						}
					"UDP"	{
							Write-Output "Service:`t$serviceDesc" | Out-File $outputfile -Append
							break
						}
				}
				for( $index = 0; $index -lt $Data.length; $index++ )
				{
					
					if( $Data[$index] -lt 33 -or $Data[$index] -gt 126 )
					{
						$Data[$index] = '.'
					}
				}
				$OFS=""	
				Write-Output "Data: $Data" | Out-File $outputfile -Append
                "Data: $Data" |select-string -Pattern "username="
				Write-Output "----------------------------------------------------------------------" | Out-File $outputfile -Append


			}
		}
	}
}

}