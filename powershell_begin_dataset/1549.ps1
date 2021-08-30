function Test-Port{  
   
[cmdletbinding(  
    DefaultParameterSetName = '',  
    ConfirmImpact = 'low'  
)]  
    Param(  
        [Parameter(  
            Mandatory = $True,  
            Position = 0,  
            ParameterSetName = '',  
            ValueFromPipeline = $True)]  
            [array]$computer,  
        [Parameter(  
            Position = 1,  
            Mandatory = $True,  
            ParameterSetName = '')]  
            [array]$port,  
        [Parameter(  
            Mandatory = $False,  
            ParameterSetName = '')]  
            [int]$TCPtimeout=1000,  
        [Parameter(  
            Mandatory = $False,  
            ParameterSetName = '')]  
            [int]$UDPtimeout=1000,             
        [Parameter(  
            Mandatory = $False,  
            ParameterSetName = '')]  
            [switch]$TCP,  
        [Parameter(  
            Mandatory = $False,  
            ParameterSetName = '')]  
            [switch]$UDP                                    
        )  
    Begin {  
        If (!$tcp -AND !$udp) {$tcp = $True}  
        
        
        $ErrorActionPreference = "SilentlyContinue"  
        $report = @()  
    }  
    Process {     
        ForEach ($c in $computer) {  
            ForEach ($p in $port) {  
                If ($tcp) {    
                    
                    $temp = "" | Select Server, Port, TypePort, Open, Notes  
                    
                    $tcpobject = new-Object system.Net.Sockets.TcpClient  
                    
                    $connect = $tcpobject.BeginConnect($c,$p,$null,$null)  
                    
                    $wait = $connect.AsyncWaitHandle.WaitOne($TCPtimeout,$false)  
                    
                    If(!$wait) {  
                        
                        $tcpobject.Close()  
                        Write-Verbose "Connection Timeout"  
                        
                        $temp.Server = $c  
                        $temp.Port = $p  
                        $temp.TypePort = "TCP"  
                        $temp.Open = $False 
                        $temp.Notes = "Connection to Port Timed Out"  
                    } Else {  
                        $error.Clear()  
                        $tcpobject.EndConnect($connect) | out-Null  
                        
                        If($error[0]){  
                            
                            [string]$string = ($error[0].exception).message  
                            $message = (($string.split(":")[1]).replace('"',"")).TrimStart()  
                            $failed = $true  
                        }  
                        
                        $tcpobject.Close()  
                        
                        If($failed){  
                            
                            $temp.Server = $c  
                            $temp.Port = $p  
                            $temp.TypePort = "TCP"  
                            $temp.Open = $False 
                            $temp.Notes = "$message"  
                        } Else{  
                            
                            $temp.Server = $c  
                            $temp.Port = $p  
                            $temp.TypePort = "TCP"  
                            $temp.Open = $True   
                            $temp.Notes = ""  
                        }  
                    }     
                    
                    $failed = $Null      
                    
                    $report += $temp  
                }      
                If ($udp) {  
                    
                    $temp = "" | Select Server, Port, TypePort, Open, Notes                                     
                    
                    $udpobject = new-Object system.Net.Sockets.Udpclient
                    
                    $udpobject.client.ReceiveTimeout = $UDPTimeout 
                    
                    Write-Verbose "Making UDP connection to remote server" 
                    $udpobject.Connect("$c",$p) 
                    
                    Write-Verbose "Sending message to remote host" 
                    $a = new-object system.text.asciiencoding 
                    $byte = $a.GetBytes("$(Get-Date)") 
                    [void]$udpobject.Send($byte,$byte.length) 
                    
                    Write-Verbose "Creating remote endpoint" 
                    $remoteendpoint = New-Object system.net.ipendpoint([system.net.ipaddress]::Any,0) 
                    Try { 
                        
                        Write-Verbose "Waiting for message return" 
                        $receivebytes = $udpobject.Receive([ref]$remoteendpoint) 
                        [string]$returndata = $a.GetString($receivebytes)
                        If ($returndata) {
                           Write-Verbose "Connection Successful"  
                            
                            $temp.Server = $c  
                            $temp.Port = $p  
                            $temp.TypePort = "UDP"  
                            $temp.Open = $True 
                            $temp.Notes = $returndata   
                            $udpobject.close()   
                        }                       
                    } Catch { 
                        If ($Error[0].ToString() -match "\bRespond after a period of time\b") { 
                            
                            $udpobject.Close()  
                            
                            If (Test-Connection -comp $c -count 1 -quiet) { 
                                Write-Verbose "Connection Open"  
                                
                                $temp.Server = $c  
                                $temp.Port = $p  
                                $temp.TypePort = "UDP"  
                                $temp.Open = $True 
                                $temp.Notes = "" 
                            } Else { 
                                 
                                Write-Verbose "Host maybe unavailable"  
                                
                                $temp.Server = $c  
                                $temp.Port = $p  
                                $temp.TypePort = "UDP"  
                                $temp.Open = $False 
                                $temp.Notes = "Unable to verify if port is open or if host is unavailable."                                 
                            }                         
                        } ElseIf ($Error[0].ToString() -match "forcibly closed by the remote host" ) { 
                            
                            $udpobject.Close()  
                            Write-Verbose "Connection Timeout"  
                            
                            $temp.Server = $c  
                            $temp.Port = $p  
                            $temp.TypePort = "UDP"  
                            $temp.Open = $False 
                            $temp.Notes = "Connection to Port Timed Out"                         
                        } Else {                      
                            $udpobject.close() 
                        } 
                    }     
                    
                    $report += $temp  
                }                                  
            }  
        }                  
    }  
    End {  
        
        $report 
    }
}