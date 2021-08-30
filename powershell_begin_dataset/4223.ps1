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