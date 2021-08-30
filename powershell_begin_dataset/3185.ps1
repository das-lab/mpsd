function New-IPRange {

[cmdletbinding()]
param (
    [parameter( Mandatory = $true,
                Position = 0 )]
    [System.Net.IPAddress]$Start,

    [parameter( Mandatory = $true,
                Position = 1)]
    [System.Net.IPAddress]$End,

    [int[]]$Exclude = @( 0, 1, 255 )
)
    
    
    
    Write-Verbose "Parsed Start as '$Start', End as '$End'"
    
    $ip1 = $start.GetAddressBytes()
    [Array]::Reverse($ip1)
    $ip1 = ([System.Net.IPAddress]($ip1 -join '.')).Address

    $ip2 = ($end).GetAddressBytes()
    [Array]::Reverse($ip2)
    $ip2 = ([System.Net.IPAddress]($ip2 -join '.')).Address

    for ($x=$ip1; $x -le $ip2; $x++)
    {
        $ip = ([System.Net.IPAddress]$x).GetAddressBytes()
        [Array]::Reverse($ip)
        if($Exclude -notcontains $ip[3])
        {
            $ip -join '.'
        }
    }
}