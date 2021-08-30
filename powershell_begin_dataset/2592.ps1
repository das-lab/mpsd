


















Param(
	[string]$zone,
	[string]$domain,
	[string]$dc,
	[switch]$csv,
	[switch]$help
)

function dumpByteArray([System.Byte[]]$array, [int]$width = 9)
{
	
	

	$hex = ""
	$chr = ""
	$int = ""

	$i = $array.Count
	"Array contains {0} elements" -f $i
	$index = 0
	$count = 0
	while ($i-- -gt 0)
	{
		$val = $array[$index++]

		$hex += ("{0} " -f $val.ToString("x2"))

		if ([char]::IsLetterOrDigit($val) -or 
		    [char]::IsPunctuation($val)   -or 
		   ([char]$val -eq " "))
		{
			$chr += [char]$val
		}
		else
		{
			$chr += "."
		}

		$int += "{0,4:N0}" -f $val

		$count++
		if ($count -ge $width)
		{
			"$hex $chr $int"
			$hex = ""
			$chr = ""
			$int = ""
			$count = 0
		}		
	}

	if ($count -gt 0)
	{
		if ($count -lt $width)
		{
			$hex += (" " * (3 * ($width - $count)))
			$chr += (" " * (1 * ($width - $count)))
			$int += (" " * (4 * ($width - $count)))
		}

		"$hex $chr $int"
	}
}

function dwordLE([System.Byte[]]$arr, [int]$startIndex)
{
	
	
	
	
	
	

	$res = $arr[$startIndex + 3]
	$res = ($res * 256) + $arr[$startIndex + 2]
	$res = ($res * 256) + $arr[$startIndex + 1]
	$res = ($res * 256) + $arr[$startIndex + 0]

	return $res
}

function dwordBE([System.Byte[]]$arr, [int]$startIndex)
{
	
	
	
	
	
	

	$res = $arr[$startIndex]
	$res = ($res * 256) + $arr[$startIndex + 1]
	$res = ($res * 256) + $arr[$startIndex + 2]
	$res = ($res * 256) + $arr[$startIndex + 3]

	return $res
}

function wordLE([System.Byte[]]$arr, [int]$startIndex)
{
	
	
	
	
	
	

	$res = $arr[$startIndex + 1]
	$res = ($res * 256) + $arr[$startIndex]

	return $res
}

function wordBE([System.Byte[]]$arr, [int]$startIndex)
{
	
	
	
	
	
	

	$res = $arr[$startIndex]
	$res = ($res * 256) + $arr[$startIndex + 1]

	return $res
}

function decodeName([System.Byte[]]$arr, [int]$startIndex)
{
	
	
	
	
	
	
	
	
	
	
	
	
	
	

	[int]$totlen   = $arr[$startIndex]
	[int]$segments = $arr[$startIndex + 1]
	[int]$index    = $startIndex + 2

	[string]$name  = ""

	while ($segments-- -gt 0)
	{
		[int]$segmentLength = $arr[$index++]
		while ($segmentLength-- -gt 0)
		{
			$name += [char]$arr[$index++]
		}
		$name += "."
	}

	return $name
}

function analyzeArray([System.Byte[]]$arr, [System.Object]$var)
{
	$nameArray = $var.distinguishedname.ToString().Split(",")
	$name = $nameArray[0].SubString(3)

	
	
	
	
	$rdataLen = wordLE $arr 0

	
	$rdatatype = wordLE $arr 2

	
	$updatedAtSerial = dwordLE $arr 8

	
	$ttl = dwordBE $arr 12

	

	
	$age = dwordLE $arr 20
	if ($age -ne 0)
	{
		
		
		
		$timestamp = ((get-date -year 1601 -month 1 -day 1 -hour 0 -minute 0 -second 0).AddHours($age)).ToString()
	}
	else
	{
		$timestamp = "[static]"
	}

	if ($rdatatype -eq 1)
	{
		
		$ip = "{0}.{1}.{2}.{3}" -f $arr[24], $arr[25], $arr[26], $arr[27]

		if ($csv)
		{
			$formatstring = "{0},{1},{2},{3},{4}"
		}
		else
		{
			$formatstring = "{0,-30}`t{1,-24}`t{2}`t{3}`t{4}"
		}

		$formatstring -f $name, $timestamp, $ttl, "A", $ip
	}
	elseif ($rdatatype -eq 2)
	{
		
		$nsname = decodeName $arr 24

		if ($csv)
		{
			$formatstring = "{0},{1},{2},{3},{4}"
		}
		else
		{
			$formatstring = "{0,-30}`t{1,-24}`t{2}`t{3}`t{4}"
		}

		$formatstring -f $name, $timestamp, $ttl, "NS", $nsname
	}
	elseif ($rdatatype -eq 5)
	{
		
		

		$alias = decodeName $arr 24

		if ($csv)
		{
			$formatstring = "{0},{1},{2},{3},{4}"
		}
		else
		{
			$formatstring = "{0,-30}`t{1,-24}`t{2}`t{3}`t{4}"
		}

		$formatstring -f $name, $timestamp, $ttl, "CNAME", $alias
	}
	elseif ($rdatatype -eq 6)
	{
		
		

		$nslen = $arr[44]
		$priserver = decodeName $arr 44
		$index = 46 + $nslen

		

		
		$resparty = decodeName $arr $index

		

		
		

		$serial = dwordBE $arr 24
		

		$refresh = dwordBE $arr 28
		

		$retry = dwordBE $arr 32
		

		$expires = dwordBE $arr 36
		

		$minttl = dwordBE $arr 40
		

		if ($csv)
		{
			$formatstring = "{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10}"

			$formatstring -f $name, $timestamp, $ttl, `
				"SOA", $priserver, $resparty, `
				$serial, $refresh, $retry, `
				$expires, $minttl
		}
		else
		{
			$formatstring = "{0,-30}`t{1,-24}`t{2}`t{3}"

			$formatstring -f $name, $timestamp, $ttl, "SOA"
			(" " * 32) + "Primary server: $priserver"
			(" " * 32) + "Responsible party: $resparty"
			(" " * 32) + "Serial: $serial"
			(" " * 32) + "TTL: $ttl"
			(" " * 32) + "Refresh: $refresh"
			(" " * 32) + "Retry: $retry"
			(" " * 32) + "Expires: $expires"
			(" " * 32) + "Minimum TTL (default): $minttl"
		}
	}
	elseif ($rdatatype -eq 12)
	{
		

		$ptr = decodeName $arr 24

		if ($csv)
		{
			$formatstring = "{0},{1},{2},{3},{4}"
		}
		else
		{
			$formatstring = "{0,-30}`t{1,-24}`t{2}`t{3}`t{4}"
		}

		$formatstring -f $name, $timestamp, $ttl, "PTR", $ptr
	}
	elseif ($rdatatype -eq 13)
	{
		

		[string]$cputype = ""
		[string]$ostype  = ""

		[int]$segmentLength = $arr[24]
		$index = 25

		while ($segmentLength-- -gt 0)
		{
			$cputype += [char]$arr[$index++]
		}

		$index = 24 + $arr[24] + 1
		[int]$segmentLength = $index++

		while ($segmentLength-- -gt 0)
		{
			$ostype += [char]$arr[$index++]
		}

		if ($csv)
		{
			$formatstring = "{0},{1},{2},{3},{4},{5}"
		}
		else
		{
			$formatstring = "{0,-30}`t{1,-24}`t{2}`t{3}`t{4},{5}"
		}

		$formatstring -f $name, $timestamp, $ttl, "HINFO", $cputype, $ostype
	}
	elseif ($rdatatype -eq 15)
	{
		

		$priority = wordBE $arr 24
		$mxhost   = decodeName $arr 26

		if ($csv)
		{
			$formatstring = "{0},{1},{2},{3},{4},{5}"
		}
		else
		{
			$formatstring = "{0,-30}`t{1,-24}`t{2}`t{3}`t{4}  {5}"
		}

		$formatstring -f $name, $timestamp, $ttl, "MX", $priority, $mxhost
	}
	elseif ($rdatatype -eq 16)
	{
		

		[string]$txt  = ""

		[int]$segmentLength = $arr[24]
		$index = 25

		while ($segmentLength-- -gt 0)
		{
			$txt += [char]$arr[$index++]
		}

		if ($csv)
		{
			$formatstring = "{0},{1},{2},{3},{4}"
		}
		else
		{
			$formatstring = "{0,-30}`t{1,-24}`t{2}`t{3}`t{4}"
		}

		$formatstring -f $name, $timestamp, $ttl, "TXT", $txt

	}
	elseif ($rdatatype -eq 28)
	{
		

		

		$str = ""
		for ($i = 24; $i -lt 40; $i+=2)
		{
			$seg = wordBE $arr $i
			$str += ($seg).ToString('x4')
			if ($i -ne 38) { $str += ':' }
		}

		if ($csv)
		{
			$formatstring = "{0},{1},{2},{3},{4}"
		}
		else
		{
			$formatstring = "{0,-30}`t{1,-24}`t{2}`t{3}`t{4}"
		}

		$formatstring -f $name, $timestamp, $ttl, "AAAA", $str
	}
	elseif ($rdatatype -eq 33)
	{
		

		$port   = wordBE $arr 28
		$weight = wordBE $arr 26
		$pri    = wordBE $arr 24

		$nsname = decodeName $arr 30

		if ($csv)
		{
			$formatstring = "{0},{1},{2},{3},{4},{5}"
		}
		else
		{
			$formatstring = "{0,-30}`t{1,-24}`t{2}`t{3} {4} {5}"
		}

		$formatstring -f `
			$name, $timestamp, `
			$ttl, "SRV", `
			("[" + $pri.ToString() + "][" + $weight.ToString() + "][" + $port.ToString() + "]"), `
			$nsname
	}
	else
	{
		$name
		"RDataType $rdatatype"
		$var.distinguishedname.ToString()
		dumpByteArray $arr
	}

}

function processAttribute([string]$attrName, [System.Object]$var)
{
	$array = $var.$attrName.Value


	if ($array -is [System.Byte[]])
	{

		" "
		analyzeArray $array $var
		" "
	}
	else
	{
		for ($i = 0; $i -lt $array.Count; $i++)
		{

			" "
			analyzeArray $array[$i] $var
			" "
		}
	}
}

function usage
{
"
.\dns-dump -zone  [-dc ] [-domain] [-csv] |
	   -help

dns-dump will dump, from Active Directory, a particular named zone. 
The zone named must be Active Directory integrated.

Zone contents can vary depending on domain controller (in regards
to replication and the serial number of the SOA record). By using
the -dc parameter, you can specify the desired DC to use. Otherwise,
dns-dump uses the default DC.

The -domain option can be specified if the script is to be used
against a domain that the current host isn't a part of but has read
access to.

Usually, output is formatted for display on a workstation. If you
want CSV (comma-separated-value) output, specify the -csv parameter.
Use out-file in the pipeline to save the output to a file.

Finally, to produce this helpful output, you can specify the -help
parameter.

This command is basically equivalent to (but better than) the:

	dnscmd /zoneprint 
or
	dnscmd /enumrecords  '@'

commands.

Example 1:

	.\dns-dump -zone essential.local -dc win2008-dc-3

Example 2:

	.\dns-dump -help

Example 3:

	.\dns-dump -zone essential.local -csv |
            out-file essential.txt -encoding ascii

	Note: the '-encoding ascii' is important if you want to
	work with the file within the old cmd.exe shell. Otherwise,
	you can usually leave that off.
"
}

	
	
	

	if ($help)
	{
		usage
		return
	}

	if ($args.Length -gt 0)
	{
		write-error "Invalid parameter specified"
		usage
		return
	}

	if (!$zone)
	{
		throw "must specify zone name"
		return
	}
	
	if ($domain)
	{
		$defaultNC = "DC=" + $domain.replace(".",",DC=")
	}
	else
	{
		$root = [ADSI]"LDAP://RootDSE"
		$defaultNC = $root.defaultNamingContext	
	}

	$dn = "LDAP://"
	if ($dc) { $dn += $dc + "/" }
	$dn += "DC=" + $zone + ",CN=MicrosoftDNS,CN=System," + $defaultNC

	$obj = [ADSI]$dn
	if ($obj.name)
	{
		if ($csv)
		{
			"Name,Timestamp,TTL,RecordType,Param1,Param2"
		}

		
		

		foreach ($record in $obj.psbase.Children)
		{
			
			if ($record.dnsRecord)   { processAttribute "dNSRecord"   $record }
		}
	}
	else
	{
		write-error "Can't open $dn"
	}

	$obj = $null
