function Get-UserSession {
 
    [cmdletbinding()]
    Param(
        [Parameter(
            Position = 0,
            ValueFromPipeline = $True)]
        [string[]]$computername = "localhost",

        [switch]$parseIdleTime,

        [validaterange(0,120)]$timeout = 15
    )             

    ForEach($computer in $computername) {
        
        

            
                Do{
                    $tempFile = [System.IO.Path]::GetTempFileName()
                    start-sleep -Milliseconds 300
                }
                Until(test-path $tempfile)

            
                $startTime = Get-Date
                $p = Start-Process -FilePath C:\windows\system32\cmd.exe -ArgumentList "/c query user /server:$computer > $tempfile" -WindowStyle hidden -passthru

            
            
                $stopprocessing = $false
                do{
                    
                    
                    $hasExited = $p.HasExited
                
                    
                    Try { $proc = get-process -id $p.id -ErrorAction stop }
                    Catch { $proc = $null }

                    
                    start-sleep -seconds .5

                    
                    if( ( (Get-Date) - $startTime ).totalseconds -gt $timeout -and -not $hasExited -and $proc){
                        $p.kill()
                        $stopprocessing = $true
                        remove-item $tempfile -force
                        Write-Error "$computer`: Query.exe took longer than $timeout seconds to execute"
                    }
                }
                until($hasexited -or $stopProcessing -or -not $proc)
                if($stopprocessing){ Continue }

                
                $sessions = get-content $tempfile
                remove-item $tempfile -force
        
        
        if($sessions){

            1..($sessions.count -1) | % {
            
                
                $temp = "" | Select ComputerName, Username, SessionName, Id, State, IdleTime, LogonTime
                $temp.ComputerName = $computer

                
                
                

                if($sessions[$_].length -gt 5){
                    
                    if($sessions[$_].length -le 82){
                           
                        $temp.Username = $sessions[$_].Substring(1,22).trim()
                        $temp.SessionName = $sessions[$_].Substring(23,19).trim()
                        $temp.Id = $sessions[$_].Substring(42,4).trim()
                        $temp.State = $sessions[$_].Substring(46,8).trim()
                        $temp.IdleTime = $sessions[$_].Substring(54,11).trim()
                        $logonTimeLength = $sessions[$_].length - 65
                        try{
                            $temp.LogonTime = get-date $sessions[$_].Substring(65,$logonTimeLength).trim()
                        }
                        catch{
                            $temp.LogonTime = $sessions[$_].Substring(65,$logonTimeLength).trim() | out-null
                        }

                    }
                    
                    else{                                       
                        $array = $sessions[$_] -replace "\s+", " " -split " "
                        $temp.Username = $array[1]
                
                        
                        if($array.count -lt 9){
                            $temp.SessionName = ""
                            $temp.Id = $array[2]
                            $temp.State = $array[3]
                            $temp.IdleTime = $array[4]
                            $temp.LogonTime = get-date $($array[5] + " " + $array[6] + " " + $array[7])
                        }
                        else{
                            $temp.SessionName = $array[2]
                            $temp.Id = $array[3]
                            $temp.State = $array[4]
                            $temp.IdleTime = $array[5]
                            $temp.LogonTime = get-date $($array[6] + " " + $array[7] + " " + $array[8])
                        }
                    }

                    
                    if($parseIdleTime){
                        $string = $temp.idletime
                
                        
                        function convert-shortIdle {
                            param($string)
                            if($string -match "\:"){
                                [timespan]$string
                            }
                            else{
                                New-TimeSpan -minutes $string
                            }
                        }
                
                        
                        if($string -match "\+"){
                            $days = new-timespan -days ($string -split "\+")[0]
                            $hourMin = convert-shortIdle ($string -split "\+")[1]
                            $temp.idletime = $days + $hourMin
                        }
                        
                        elseif($string -like "." -or $string -like "none"){
                            $temp.idletime = [timespan]"0:00"
                        }
                        
                        else{
                            $temp.idletime = convert-shortIdle $string
                        }
                    }
                
                    
                    $temp
                }
            }
        }            
        else{ Write-warning "$computer`: No sessions found" }
    }
}