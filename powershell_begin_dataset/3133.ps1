









function Invoke-IPv4NetworkScan
{
    [CmdletBinding(DefaultParameterSetName='CIDR')]
    Param(
        [Parameter(
            ParameterSetName='Range',
            Position=0,
            Mandatory=$true,
            HelpMessage='Start IPv4-Address like 192.168.1.10')]
        [IPAddress]$StartIPv4Address,

        [Parameter(
            ParameterSetName='Range',
            Position=1,
            Mandatory=$true,
            HelpMessage='End IPv4-Address like 192.168.1.100')]
        [IPAddress]$EndIPv4Address,
        
        [Parameter(
            ParameterSetName='CIDR',
            Position=0,
            Mandatory=$true,
            HelpMessage='IPv4-Address which is in the subnet')]
        [Parameter(
            ParameterSetName='Mask',
            Position=0,
            Mandatory=$true,
            HelpMessage='IPv4-Address which is in the subnet')]
        [IPAddress]$IPv4Address,

        [Parameter(
            ParameterSetName='CIDR',        
            Position=1,
            Mandatory=$true,
            HelpMessage='CIDR like /24 without "/"')]
        [ValidateRange(0,31)]
        [Int32]$CIDR,
    
        [Parameter(
            ParameterSetName='Mask',
            Position=1,
            Mandatory=$true,
            Helpmessage='Subnetmask like 255.255.255.0')]
        [ValidateScript({
            if($_ -match "^(254|252|248|240|224|192|128).0.0.0$|^255.(254|252|248|240|224|192|128|0).0.0$|^255.255.(254|252|248|240|224|192|128|0).0$|^255.255.255.(254|252|248|240|224|192|128|0)$")
            {
                return $true
            }
            else
            {
                throw "Enter a valid subnetmask (like 255.255.255.0)!"
            }
        })]
        [String]$Mask,

        [Parameter(
            Position=2,
            HelpMessage='Maxmium number of ICMP checks for each IPv4-Address (Default=2)')]
        [Int32]$Tries=2,

        [Parameter(
            Position=3,
            HelpMessage='Maximum number of threads at the same time (Default=256)')]
        [Int32]$Threads=256,
        
        [Parameter(
            Position=4,
            HelpMessage='Resolve DNS for each IP (Default=Enabled)')]
        [Switch]$DisableDNSResolving,

        [Parameter(
            Position=5,
            HelpMessage='Resolve MAC-Address for each IP (Default=Disabled)')]
        [Switch]$EnableMACResolving,

        [Parameter(
            Position=6,
            HelpMessage='Get extendend informations like BufferSize, ResponseTime and TTL (Default=Disabled)')]
        [Switch]$ExtendedInformations,

        [Parameter(
            Position=7,
            HelpMessage='Include inactive devices in result')]
        [Switch]$IncludeInactive,

        [Parameter(
            Position=8,
            HelpMessage='Update IEEE Standards Registration Authority from IEEE.org (https://standards.ieee.org/develop/regauth/oui/oui.csv)')]
        [Switch]$UpdateList
    )

    Begin{
        Write-Verbose -Message "Script started at $(Get-Date)"
        
        
        $IEEE_MACVendorList_WebUri = "http://standards.ieee.org/develop/regauth/oui/oui.csv"

        
        $CSV_MACVendorList_Path = "$PSScriptRoot\Resources\IEEE_Standards_Registration_Authority.csv"
        $CSV_MACVendorList_BackupPath = "$PSScriptRoot\Resources\IEEE_Standards_Registration_Authority.csv.bak"

        
        function UpdateListFromIEEE
        {     
            
            try{
                Write-Verbose -Message "Create backup of the IEEE Standards Registration Authority list..."
                
                
                if(Test-Path -Path $CSV_MACVendorList_Path -PathType Leaf)
                {
                    Rename-Item -Path $CSV_MACVendorList_Path -NewName $CSV_MACVendorList_BackupPath
                }

                Write-Verbose -Message "Updating IEEE Standards Registration Authority from IEEE.org..."

                
                Invoke-WebRequest -Uri $IEEE_MACVendorList_WebUri -OutFile $CSV_MACVendorList_Path -ErrorAction Stop

                Write-Verbose -Message "Remove backup of the IEEE Standards Registration Authority list..."

                
                if(Test-Path -Path $CSV_MACVendorList_BackupPath -PathType Leaf)
                {
                    Remove-Item -Path $CSV_MACVendorList_BackupPath
                }            
            }
            catch{            
                Write-Verbose -Message "Cleanup downloaded file and restore backup..."

                
                if(Test-Path -Path $CSV_MACVendorList_Path)
                {
                    Remove-Item -Path $CSV_MACVendorList_Path -Force
                }

                if(Test-Path -Path $CSV_MACVendorList_BackupPath -PathType Leaf)
                {
                    Rename-Item -Path $CSV_MACVendorList_BackupPath -NewName $CSV_MACVendorList_Path
                }

                $_.Exception.Message                        
            }        
        }  

        
        function AssignVendorToMAC
        {
            param(
                $Result
            )

            Begin{

            }

            Process {
                $Vendor = [String]::Empty

                
                if(-not([String]::IsNullOrEmpty($Result.MAC)))
                {
                    
                    $MAC_VendorSearch = $Job_Result.MAC.Replace("-","").Substring(0,6)
                    
                    foreach($ListEntry in $MAC_VendorList)
                    {
                        if($ListEntry.Assignment -eq $MAC_VendorSearch)
                        {
                            $Vendor = $ListEntry."Organization Name"
                            break
                        }
                    }                    
                }

                [pscustomobject] @{
                    IPv4Address = $Result.IPv4Address
                    Status = $Result.Status
                    Hostname = $Result.Hostname
                    MAC = $Result.MAC
                    Vendor = $Vendor  
                    BufferSize = $Result.BufferSize
                    ResponseTime = $Result.ResponseTime
                    TTL = $Result.TTL
                }
            }

            End {

            }
        }
    }

    Process{
        $CSV_MACVendorList_Available = Test-Path -Path $CSV_MACVendorList_Path -PathType Leaf

        
        if($UpdateList)
        {
            UpdateListFromIEEE
        }
        elseif(($EnableMACResolving) -and ($CSV_MACVendorList_Available -eq $false))
        {
            Write-Warning -Message "No CSV-File to assign vendor with MAC-Address found! Use the parameter ""-UpdateList"" to download the latest version from IEEE.org. This warning does not affect the scanning procedure."
        }   
        
        
        if($PSCmdlet.ParameterSetName -eq 'CIDR' -or $PSCmdlet.ParameterSetName -eq 'Mask')
        {
            
            if($PSCmdlet.ParameterSetName -eq 'Mask')
            {
                $CIDR = (Convert-Subnetmask -Mask $Mask).CIDR     
            }

            
            $Subnet = Get-IPv4Subnet -IPv4Address $IPv4Address -CIDR $CIDR

            
            $StartIPv4Address = $Subnet.NetworkID
            $EndIPv4Address = $Subnet.Broadcast
        }

        
        $StartIPv4Address_Int64 = (Convert-IPv4Address -IPv4Address $StartIPv4Address.ToString()).Int64
        $EndIPv4Address_Int64 = (Convert-IPv4Address -IPv4Address $EndIPv4Address.ToString()).Int64

        
        if($StartIPv4Address_Int64 -gt $EndIPv4Address_Int64)
        {
            Write-Error -Message "Invalid IP-Range... Check your input!" -Category InvalidArgument -ErrorAction Stop
        }

        
        $IPsToScan = ($EndIPv4Address_Int64 - $StartIPv4Address_Int64)
        
        Write-Verbose -Message "Scanning range from $StartIPv4Address to $EndIPv4Address ($($IPsToScan + 1) IPs)"
        Write-Verbose -Message "Running with max $Threads threads"
        Write-Verbose -Message "ICMP checks per IP is set to $Tries"

        
        $PropertiesToDisplay = @()
        $PropertiesToDisplay += "IPv4Address", "Status"

        if($DisableDNSResolving -eq $false)
        {
            $PropertiesToDisplay += "Hostname"
        }

        if($EnableMACResolving)
        {
            $PropertiesToDisplay += "MAC"
        }

        
        if($EnableMACResolving -and $CSV_MACVendorList_Available)
        {
            $AssignVendorToMAC = $true

            $PropertiesToDisplay += "Vendor"
        
            $MAC_VendorList = Import-Csv -Path $CSV_MACVendorList_Path | Select-Object -Property "Assignment", "Organization Name"
        }
        else 
        {
            $AssignVendorToMAC = $false
        }
        
        if($ExtendedInformations)
        {
            $PropertiesToDisplay += "BufferSize", "ResponseTime", "TTL"
        }

        
        [System.Management.Automation.ScriptBlock]$ScriptBlock = {
            Param(
                $IPv4Address,
                $Tries,
                $DisableDNSResolving,
                $EnableMACResolving,
                $ExtendedInformations,
                $IncludeInactive
            )
    
            
            $Status = [String]::Empty

            for($i = 0; $i -lt $Tries; i++)
            {
                try{
                    $PingObj = New-Object System.Net.NetworkInformation.Ping
                    
                    $Timeout = 1000
                    $Buffer = New-Object Byte[] 32
                    
                    $PingResult = $PingObj.Send($IPv4Address, $Timeout, $Buffer)

                    if($PingResult.Status -eq "Success")
                    {
                        $Status = "Up"
                        break 
                    }
                    else
                    {
                        $Status = "Down"
                    }
                }
                catch
                {
                    $Status = "Down"
                    break 
                }
            }
                
            
            $Hostname = [String]::Empty     

            if((-not($DisableDNSResolving)) -and ($Status -eq "Up" -or $IncludeInactive))
            {   	
                try{ 
                    $Hostname = ([System.Net.Dns]::GetHostEntry($IPv4Address).HostName)
                } 
                catch { } 
            }
        
            
            $MAC = [String]::Empty 

            if(($EnableMACResolving) -and (($Status -eq "Up") -or ($IncludeInactive)))
            {
                $Arp_Result = (arp -a ).ToUpper()
                        
                foreach($Line in $Arp_Result)
                {
                    if($Line.TrimStart().StartsWith($IPv4Address))
                    {
                        $MAC = [Regex]::Matches($Line,"([0-9A-F][0-9A-F]-){5}([0-9A-F][0-9A-F])").Value
                    }
                }

                
                if([String]::IsNullOrEmpty($MAC))
                {
                    try{              
                        $Nbtstat_Result = nbtstat -A $IPv4Address | Select-String "MAC"
                        $MAC = [Regex]::Matches($Nbtstat_Result, "([0-9A-F][0-9A-F]-){5}([0-9A-F][0-9A-F])").Value
                    }  
                    catch{ } 
                }   

            }

            
            $BufferSize = [String]::Empty 
            $ResponseTime = [String]::Empty 
            $TTL = $null

            if($ExtendedInformations -and ($Status -eq "Up"))
            {
                try{
                    $BufferSize =  $PingResult.Buffer.Length
                    $ResponseTime = $PingResult.RoundtripTime
                    $TTL = $PingResult.Options.Ttl
                }
                catch{ } 
            }	
        
            
            
            if(($Status -eq "Up") -or ($IncludeInactive))
            {
                [pscustomobject] @{
                    IPv4Address = $IPv4Address
                    Status = $Status
                    Hostname = $Hostname
                    MAC = $MAC   
                    BufferSize = $BufferSize
                    ResponseTime = $ResponseTime
                    TTL = $TTL
                }
            }
            else
            {
                $null
            }
        } 

        Write-Verbose -Message "Setting up RunspacePool..."

        
        $RunspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $Threads, $Host)
        $RunspacePool.Open()
        [System.Collections.ArrayList]$Jobs = @()

        Write-Verbose -Message "Setting up Jobs..."

        
        for ($i = $StartIPv4Address_Int64; $i -le $EndIPv4Address_Int64; $i++) 
        { 
            
            $IPv4Address = (Convert-IPv4Address -Int64 $i).IPv4Address                

            
            $ScriptParams = @{
                IPv4Address = $IPv4Address
                Tries = $Tries
                DisableDNSResolving = $DisableDNSResolving
                EnableMACResolving = $EnableMACResolving
                ExtendedInformations = $ExtendedInformations
                IncludeInactive = $IncludeInactive
            }       

            
            try {
                $Progress_Percent = (($i - $StartIPv4Address_Int64) / $IPsToScan) * 100 
            } 
            catch { 
                $Progress_Percent = 100 
            }

            Write-Progress -Activity "Setting up jobs..." -Id 1 -Status "Current IP-Address: $IPv4Address" -PercentComplete $Progress_Percent
                            
            
            $Job = [System.Management.Automation.PowerShell]::Create().AddScript($ScriptBlock).AddParameters($ScriptParams)
            $Job.RunspacePool = $RunspacePool
            
            $JobObj = [pscustomobject] @{
                RunNum = $i - $StartIPv4Address_Int64
                Pipe = $Job
                Result = $Job.BeginInvoke()
            }

            
            [void]$Jobs.Add($JobObj)
        }

        Write-Verbose -Message "Waiting for jobs to complete & starting to process results..."

        
        $Jobs_Total = $Jobs.Count

        
        Do {
            
            $Jobs_ToProcess = $Jobs | Where-Object -FilterScript {$_.Result.IsCompleted}
    
            
            if($null -eq $Jobs_ToProcess)
            {
                Write-Verbose -Message "No jobs completed, wait 500ms..."

                Start-Sleep -Milliseconds 500
                continue
            }
            
            
            $Jobs_Remaining = ($Jobs | Where-Object -FilterScript {$_.Result.IsCompleted -eq $false}).Count

            
            try {            
                $Progress_Percent = 100 - (($Jobs_Remaining / $Jobs_Total) * 100) 
            }
            catch {
                $Progress_Percent = 100
            }

            Write-Progress -Activity "Waiting for jobs to complete... ($($Threads - $($RunspacePool.GetAvailableRunspaces())) of $Threads threads running)" -Id 1 -PercentComplete $Progress_Percent -Status "$Jobs_Remaining remaining..."
        
            Write-Verbose -Message "Processing $(if($null -eq $Jobs_ToProcess.Count){"1"}else{$Jobs_ToProcess.Count}) job(s)..."

            
            foreach($Job in $Jobs_ToProcess)
            {       
                
                $Job_Result = $Job.Pipe.EndInvoke($Job.Result)
                $Job.Pipe.Dispose()

                
                $Jobs.Remove($Job)
            
                
                if($Job_Result.Status)
                {        
                    if($AssignVendorToMAC)
                    {                   
                        AssignVendorToMAC -Result $Job_Result | Select-Object -Property $PropertiesToDisplay
                    }
                    else 
                    {
                        $Job_Result | Select-Object -Property $PropertiesToDisplay
                    }                            
                }
            } 

        } While ($Jobs.Count -gt 0)

        Write-Verbose -Message "Closing RunspacePool and free resources..."

        
        $RunspacePool.Close()
        $RunspacePool.Dispose()

        Write-Verbose -Message "Script finished at $(Get-Date)"
    }

    End{
        
    }
}