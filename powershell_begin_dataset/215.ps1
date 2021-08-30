function Get-NetStat
{

    PROCESS
    {
        
        $data = netstat -n

        
        $data = $data[4..$data.count]

        
        foreach ($line in $data)
        {
            
            $line = $line -replace '^\s+', ''

            
            $line = $line -split '\s+'

            
            $properties = @{
                Protocole = $line[0]
                LocalAddressIP = ($line[1] -split ":")[0]
                LocalAddressPort = ($line[1] -split ":")[1]
                ForeignAddressIP = ($line[2] -split ":")[0]
                ForeignAddressPort = ($line[2] -split ":")[1]
                State = $line[3]
            }

            
            New-Object -TypeName PSObject -Property $properties
        }
    }
}