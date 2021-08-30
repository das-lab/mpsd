









function Convert-IPv4Address
{
    [CmdletBinding(DefaultParameterSetName='IPv4Address')]
    param(
        [Parameter(
            ParameterSetName='IPv4Address',
            Position=0,
            Mandatory=$true,
            HelpMessage='IPv4-Address as string like "192.168.1.1"')]
        [IPAddress]$IPv4Address,

        [Parameter(
                ParameterSetName='Int64',
                Position=0,
                Mandatory=$true,
                HelpMessage='IPv4-Address as Int64 like 2886755428')]
        [long]$Int64
    ) 

    Begin {

    }

    Process {
        switch($PSCmdlet.ParameterSetName)
        {
            
            "IPv4Address" {
                $Octets = $IPv4Address.ToString().Split(".")
                $Int64 = [long]([long]$Octets[0]*16777216 + [long]$Octets[1]*65536 + [long]$Octets[2]*256 + [long]$Octets[3]) 
            }
    
            
            "Int64" {            
                $IPv4Address = (([System.Math]::Truncate($Int64/16777216)).ToString() + "." + ([System.Math]::Truncate(($Int64%16777216)/65536)).ToString() + "." + ([System.Math]::Truncate(($Int64%65536)/256)).ToString() + "." + ([System.Math]::Truncate($Int64%256)).ToString())
            }      
        }

        [pscustomobject] @{    
            IPv4Address = $IPv4Address
            Int64 = $Int64
        }        	
    }

    End {

    }      
}