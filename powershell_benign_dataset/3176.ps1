function Get-ScheduledTasks {  
    
    [cmdletbinding(
        DefaultParameterSetName='COM'
    )]
    param(
        [parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            ValueFromRemainingArguments=$false, 
            Position=0
        )]
        [Alias("host","server","computer")]
        [string[]]$ComputerName = "localhost",

        [parameter()]
        [string]$folder = "\",

        [parameter(ParameterSetName='COM')]
        [switch]$recurse,

        [parameter(ParameterSetName='COM')]
        [validatescript({
            
            if($_){
                Test-Path -PathType Container -path $_ 
            }
            else {
                $true
            }
        })]
        [string]$Path = $null,

        [parameter()]
        [string]$Exclude = $null,

        [parameter(ParameterSetName='SchTasks')]
        [switch]$CompatibilityMode
    )
    Begin{

        if(-not $CompatibilityMode){
            $sch = New-Object -ComObject Schedule.Service
        
            
            function Get-AllTaskSubFolders {
                [cmdletbinding()]
                param (
                    
                    
                    $FolderRef = $sch.getfolder("\"),

                    [switch]$recurse
                )

                
                if (-not $recurse) {
                    $FolderRef
                }
                
                else {
                    Try{
                        
                        $folders = $folderRef.getfolders(1)

                        
                        $ArrFolders = @(
                            if($folders) {
                                foreach ($fold in $folders) {
                                    $fold
                                    if($fold.getfolders(1)) {
                                        Get-AllTaskSubFolders -FolderRef $fold
                                    }
                                }
                            }
                        )
                    }
                    Catch{
                        
                        if($_.tostring() -like '*Exception calling "GetFolders" with "1" argument(s): "The request is not supported.*')
                        {
                            $folders = $null
                            Write-Warning "GetFolders failed, returning root folder only: $_"
                            Return $FolderRef
                        }
                        else{
                            Throw $_
                        }
                    }

                    
                        $Results = @($ArrFolders) + @($FolderRef)
                        $UniquePaths = $Results | select -ExpandProperty path -Unique
                        $Results | ?{$UniquePaths -contains $_.path}
                }
            } 
        }

        function Get-SchTasks {
            [cmdletbinding()]
            param([string]$computername, [string]$folder, [switch]$CompatibilityMode)
            
            
            $result = @( schtasks.exe /query /v /s $computername /fo csv |
                convertfrom-csv |
                ?{$_.taskname -ne "taskname" -and $_.taskname -match $( $folder.replace("\","\\") ) } |
                select @{ label = "ComputerName"; expression = { $computername } },
                    @{ label = "Name"; expression = { $_.TaskName } },
                    @{ label = "Action"; expression = {$_."Task To Run"} },
                    @{ label = "LastRunTime"; expression = {$_."Last Run Time"} },
                    @{ label = "NextRunTime"; expression = {$_."Next Run Time"} },
                    "Status",
                    "Author"
            )

            if($CompatibilityMode){
                
                $result    
            }
            else{
                
                
                foreach($item in $result){
                    $name = @( $item.Name -split "\\" )[-1]
                    $taskPath = $item.name
                    $item | select ComputerName, @{ label = "Name"; expression = {$name}}, @{ label = "Path"; Expression = {$taskPath}}, Enabled, Action, Arguments, UserId, LastRunTime, NextRunTime, Status, Author, RunLevel, Description, NumberOfMissedRuns
                }
            }
        } 
    }    
    Process{
        
        foreach($computer in $computername){
        
            
            $failed = $false
        
            write-verbose "Running against $computer"
            Try {
            
                
                if(-not $compatibilityMode){      

                    Try{
                        
                        $sch.Connect($computer)
                        
                        if($recurse)
                        {
                            $AllFolders = Get-AllTaskSubFolders -FolderRef $sch.GetFolder($folder) -recurse -ErrorAction stop
                        }
                        else
                        {
                            $AllFolders = Get-AllTaskSubFolders -FolderRef $sch.GetFolder($folder) -ErrorAction stop
                        }
                        Write-verbose "Looking through $($AllFolders.count) folders on $computer"
                
                        foreach($fold in $AllFolders){
                
                            
                            $tasks = $fold.GetTasks(0)
                
                            Write-Verbose "Pulling data from $($tasks.count) tasks on $computer in $($fold.name)"
                            foreach($task in $tasks){
                            
                                
                                $Author = ([regex]::split($task.xml,'<Author>|</Author>'))[1] 
                                $UserId = ([regex]::split($task.xml,'<UserId>|</UserId>'))[1] 
                                $Description =([regex]::split($task.xml,'<Description>|</Description>'))[1]
                                $Action = ([regex]::split($task.xml,'<Command>|</Command>'))[1]
                                $Arguments = ([regex]::split($task.xml,'<Arguments>|</Arguments>'))[1]
                                $RunLevel = ([regex]::split($task.xml,'<RunLevel>|</RunLevel>'))[1]
                                $LogonType = ([regex]::split($task.xml,'<LogonType>|</LogonType>'))[1]
                            
                                
                                Switch ($task.State) { 
                                    0 {$Status = "Unknown"} 
                                    1 {$Status = "Disabled"} 
                                    2 {$Status = "Queued"} 
                                    3 {$Status = "Ready"} 
                                    4 {$Status = "Running"} 
                                }

                                
                                if(-not $exclude -or $task.Path -notmatch $Exclude){
                                    $task | select @{ label = "ComputerName"; expression = { $computer } }, 
                                        Name,
                                        Path,
                                        Enabled,
                                        @{ label = "Action"; expression = {$Action} },
                                        @{ label = "Arguments"; expression = {$Arguments} },
                                        @{ label = "UserId"; expression = {$UserId} },
                                        LastRunTime,
                                        NextRunTime,
                                        @{ label = "Status"; expression = {$Status} },
                                        @{ label = "Author"; expression = {$Author} },
                                        @{ label = "RunLevel"; expression = {$RunLevel} },
                                        @{ label = "Description"; expression = {$Description} },
                                        NumberOfMissedRuns
                            
                                    
                                    if($path){
                                        $xml = $task.Xml
                                        $taskname = $task.Name
                                        $xml | Out-File $( Join-Path $path "$computer-$taskname.xml" )
                                    }
                                }
                            }
                        }
                    }
                    Catch{
                        Write-Warning "Could not pull scheduled tasks from $computer using COM object, falling back to schtasks.exe"
                        Try{
                            Get-SchTasks -computername $computer -folder $folder -ErrorAction stop
                        }
                        Catch{
                            Write-Error "Could not pull scheduled tasks from $computer using schtasks.exe:`n$_"
                            Continue
                        }
                    }             
                }

                
                else{
                
                    Try{
                        Get-SchTasks -computername $computer -folder $folder -CompatibilityMode -ErrorAction stop
                    }
                     Catch{
                        Write-Error "Could not pull scheduled tasks from $computer using schtasks.exe:`n$_"
                        Continue
                     }
                }

            }
            Catch{
                Write-Error "Error pulling Scheduled tasks from $computer`: $_"
                Continue
            }
        }
    }
}