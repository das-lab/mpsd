









function Get-ARPCache
{
    [CmdletBinding()]
    param(

    )

    Begin{
            
    }

    Process{
        
        $RegexIPv4Address = "(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
        $RegexMACAddress = "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})|([0-9A-Fa-f]{2}){6}"

        
        $Arp_Result = arp -a

        foreach($line in $Arp_Result)
        {
            
            if($line -like "*---*")
            {            
                Write-Verbose -Message "Interface $line"

                $InterfaceIPv4 = [regex]::Matches($line, $RegexIPv4Address).Value

                Write-Verbose -Message "$InterfaceIPv4"            
            }
            elseif($line -match $RegexMACAddress)
            {            
                foreach($split in $line.Split(" "))
                {
                    if($split -match $RegexIPv4Address)
                    {
                        $IPv4Address = $split
                    }
                    elseif ($split -match $RegexMACAddress) 
                    {
                        $MACAddress = $split.ToUpper()    
                    }
                    elseif(-not([String]::IsNullOrEmpty($split)))
                    {
                        $Type = $split
                    }
                }

                [pscustomobject] @{
                    Interface = $InterfaceIPv4
                    IPv4Address = $IPv4Address
                    MACAddress = $MACAddress
                    Type = $Type
                }
            }
        }
    }

    End{

    }
}