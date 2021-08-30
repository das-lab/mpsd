function Invoke-ReverseDnsLookup
{


    Param (
        [Parameter(Position = 0, Mandatory = $True,ValueFromPipeline=$True)]
        [String]
        $IpRange
    )

    BEGIN {
    
        function Parse-IPList ([String] $IpRange)
        {
        
            function IPtoInt
            {
                Param([String] $IpString)
            
                $Hexstr = ""
                $Octets = $IpString.Split(".")
                foreach ($Octet in $Octets) {
                        $Hexstr += "{0:X2}" -f [Int] $Octet
                }
                return [Convert]::ToInt64($Hexstr, 16)
            }
        
            function InttoIP
            {
                Param([Int64] $IpInt)
                $Hexstr = $IpInt.ToString("X8")
                $IpStr = ""
                for ($i=0; $i -lt 8; $i += 2) {
                        $IpStr += [Convert]::ToInt64($Hexstr.SubString($i,2), 16)
                        $IpStr += '.'
                }
                return $IpStr.TrimEnd('.')
            }
        
            $Ip = [System.Net.IPAddress]::Parse("127.0.0.1")
        
            foreach ($Str in $IpRange.Split(","))
            {
                $Item = $Str.Trim()
                $Result = ""
                $IpRegex = "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}"
            
                
                switch -regex ($Item)
                {
                    "^$IpRegex/\d{1,2}$"
                    {
                        $Result = "cidrRange"
                        break
                    }
                    "^$IpRegex-$IpRegex$"
                    {
                        $Result = "range"
                        break
                    }
                    "^$IpRegex$"
                    {
                        $Result = "single"
                        break
                    }
                    default
                    {
                        Write-Warning "Inproper input"
                        return
                    }
                }
            
                
                switch ($Result)
                {
                    "cidrRange"
                    {
                        $CidrRange = $Item.Split("/")
                        $Network = $CidrRange[0]
                        $Mask = $CidrRange[1]
                    
                        if (!([System.Net.IPAddress]::TryParse($Network, [ref] $Ip))) { Write-Warning "Invalid IP address supplied!"; return}
                        if (($Mask -lt 0) -or ($Mask -gt 30)) { Write-Warning "Invalid network mask! Acceptable values are 0-30"; return}
                    
                        $BinaryIP = [Convert]::ToString((IPtoInt $Network),2).PadLeft(32,'0')
                        
                        $Lower = $BinaryIP.Substring(0, $Mask) + "0" * ((32-$Mask)-1) + "1"
                        
                        $Upper = $BinaryIP.Substring(0, $Mask) + "1" * ((32-$Mask)-1) + "0"
                        $LowerInt = [Convert]::ToInt64($Lower, 2)
                        $UpperInt = [Convert]::ToInt64($Upper, 2)
                        for ($i = $LowerInt; $i -le $UpperInt; $i++) { InttoIP $i }
                    }
                    "range"
                    {
                        $Range = $item.Split("-")
                    
                        if ([System.Net.IPAddress]::TryParse($Range[0],[ref]$Ip)) { $Temp1 = $Ip }
                        else { Write-Warning "Invalid IP address supplied!"; return }
                    
                        if ([System.Net.IPAddress]::TryParse($Range[1],[ref]$Ip)) { $Temp2 = $Ip }
                        else { Write-Warning "Invalid IP address supplied!"; return }
                    
                        $Left = (IPtoInt $Temp1.ToString())
                        $Right = (IPtoInt $Temp2.ToString())
                    
                        if ($Right -gt $Left) {
                            for ($i = $Left; $i -le $Right; $i++) { InttoIP $i }
                        }
                        else { Write-Warning "Invalid IP range. The right portion must be greater than the left portion."; return}
                    
                        break
                    }
                    "single"
                    {
                        if ([System.Net.IPAddress]::TryParse($Item,[ref]$Ip)) { $Ip.IPAddressToString }
                        else { Write-Warning "Invalid IP address supplied!"; return }
                        break
                    }
                    default
                    {
                        Write-Warning "An error occured."
                        return
                    }
                }
            }
        
        }
    }
    
    PROCESS {
        Parse-IPList $IpRange | ForEach-Object {
            try {
                Write-Verbose "Resolving $_"
                $Temp = [System.Net.Dns]::GetHostEntry($_)
            
                $Result = @{
                    IP = $_
                    HostName = $Temp.HostName
                }
            
                New-Object PSObject -Property $Result
            } catch [System.Net.Sockets.SocketException] {}
        }
    }
}
