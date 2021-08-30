


























Param(
    [Parameter(Position=0,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullorEmpty()]
    [Alias("name")]
    [string[]]$Computername=$env:computername
)

Begin
{ 
    Set-StrictMode -Version 2.0
    
    
    
    
    $ErrorActionPreference="SilentlyContinue"
    
   
   Function Get-DefaultDNSServer {
        
        $lookup=nslookup $env:computername | select-string "Server"
        
        
        $lookup.line.split(":")[1].Trim()
    }

    Function New-ReverseIP {
        Param([string]$IPAddress)
        $arr=$IPAddress.Split(".")
        $Reverse="{0}.{1}.{2}.{3}" -f $arr[3],$arr[2],$arr[1],$arr[0]
        Write-Output $Reverse
    }
} 

Process {
    Foreach ($name in $computername) 
    {
        
        $dns				= $False
        $dnsHostName		= $Null
        $IP					= $Null
        $ReverseVerify		= $False    
        $CShare				= $False
        $AdminShare			= $False
        $WMIVerify			= $False
        $WinRMVerify		= $False
        $AdapterHostname	= $Null
        $DNSDomain			= $Null
        $DHCPServer			= $Null
        $LeaseObtained		= $Null
        $LeaseExpires		= $Null

        
        $Ping = Test-Connection $name -Quiet

        
        $dns=[system.net.dns]::GetHostEntry("$name")

        if ($dns)
        {
            Write-Verbose ($dns | out-String)
            $dnshostname = $dns.hostname
            
            $IPv4 = $dns.addresslist | where {$_.AddressFamily -eq "Internetwork"}
            if (($IPv4 | Measure-Object).Count -gt 1)
            {
                
                $IP=$IPv4[0].IPAddressToString
            }
            else
            {
                $IP=$IPv4.IPAddressToString
            }
        } 
        else
        {
            Write-Verbose "No DNS record found for $name"
        }

        if ($IP)
        {
            
            Write-Verbose "Reverse lookup check"
            $RevIP = "{0}.in-addr.arpa" -f (New-ReverseIP $IP)
            Write-Verbose $revIP
            $DNSServer = Get-DefaultDNSServer
            $filter = "OwnerName = ""$RevIP"" AND RecordData=""$DNSHostName."""
            Write-Verbose "Querying $DNSServer for $filter"
            $record = Get-WmiObject -Class "MicrosoftDNS_PTRType" -Namespace "Root\MicrosoftDNS" -ComputerName $DNSServer -filter $filter
            if ($record)
            {
                Write-Verbose ($record | Out-String)
          
                if ($record.RecordData -match $dnsHostName) 
                {
                    $ReverseVerify=$True
                }
            }
            
            Write-Verbose "Getting WMI NetworkAdapterConfiguration for address $IP"
            $configs = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -filter "IPEnabled=True" -computername $name
           
            
            $adapter = $configs | where {$_.IPAddress -contains $IP}
            Write-Verbose ($adapter | Out-String)

            if ($adapter) 
            {
                $AdapterHostname	= $adapter.DNSHostname
                $DNSDomain			= $adapter.DNSDomain
                $DHCPServer			= $adapter.DHCPServer
                $LeaseObtained		= $adapter.ConvertToDateTime($adapter.dhcpleaseobtained)
                $LeaseExpires		= $adapter.ConvertToDateTime($adapter.dhcpleaseExpires)
            }
          
        } 
        
        
        if (Test-Path -Path \\$name\c$) {$CShare=$True}
        if (Test-Path -Path \\$name\admin$) {$AdminShare=$True}

        
        Write-Verbose "Validating WinMgmt Service on $name"
        $wmisvc = Get-Service -Name Winmgmt -ComputerName $name 
        if ($wmisvc.status -eq "Running") {$WMIVerify=$True}

        
        Write-Verbose "Validating WinRM Service on $name"
        $WinRMSvc = Get-Service -Name WinRM -computername $name
        if ($WinRMSvc.status -eq "Running") {$WinRMVerify=$True}
                
        
        
        Write-Verbose "Retrieving MAC address from $name"
        
        [regex]$MACPattern = "([0-9a-fA-F][0-9a-fA-F]-){5}([0-9a-fA-F][0-9a-fA-F])"
        
        $nbt = nbtstat -a $name
        
        $MACAddress = ($MACPattern.match($nbt)).Value   

        Write-Verbose "Creating object"
        
        New-Object -TypeName PSObject -Property @{
            Computername	= $name
            AdapterHostname	= $adapterHostName
            DNSHostName		= $dnsHostname
            DNSDomain		= $DNSDomain
            IPAddress		= $IP
            ReverseLookup	= $ReverseVerify
            DHCPServer		= $DHCPServer
            LeaseObtained	= $LeaseObtained
            LeaseExpires	= $LeaseExpires
            MACAddress		= $MACAddress
            AdminShare		= $AdminShare
            CShare			= $CShare
            WMI				= $WMIVerify
            Ping			= $Ping
            WinRM			= $WinRMVerify
        } 
    } 
} 

End 
{
    $ErrorActionPreference = "Continue"
    Write-Verbose "Finished."
} 

