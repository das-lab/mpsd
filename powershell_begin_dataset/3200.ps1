function Invoke-Parallel {
    
    [cmdletbinding(DefaultParameterSetName='ScriptBlock')]
    Param (
        [Parameter(Mandatory=$false,position=0,ParameterSetName='ScriptBlock')]
        [System.Management.Automation.ScriptBlock]$ScriptBlock,

        [Parameter(Mandatory=$false,ParameterSetName='ScriptFile')]
        [ValidateScript({Test-Path $_ -pathtype leaf})]
        $ScriptFile,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [Alias('CN','__Server','IPAddress','Server','ComputerName')]
        [PSObject]$InputObject,

        [PSObject]$Parameter,

        [switch]$ImportVariables,
        [switch]$ImportModules,
        [switch]$ImportFunctions,

        [int]$Throttle = 20,
        [int]$SleepTimer = 200,
        [int]$RunspaceTimeout = 0,
        [switch]$NoCloseOnTimeout = $false,
        [int]$MaxQueue,

        [validatescript({Test-Path (Split-Path $_ -parent)})]
        [switch] $AppendLog = $false,
        [string]$LogFile,

        [switch] $Quiet = $false
    )
    begin {
        
        
        if( -not $PSBoundParameters.ContainsKey('MaxQueue') ) {
            if($RunspaceTimeout -ne 0){ $script:MaxQueue = $Throttle }
            else{ $script:MaxQueue = $Throttle * 3 }
        }
        else {
            $script:MaxQueue = $MaxQueue
        }
        $ProgressId = Get-Random
        Write-Verbose "Throttle: '$throttle' SleepTimer '$sleepTimer' runSpaceTimeout '$runspaceTimeout' maxQueue '$maxQueue' logFile '$logFile'"

        
        if ($ImportVariables -or $ImportModules -or $ImportFunctions) {
            $StandardUserEnv = [powershell]::Create().addscript({

                
                $Modules = Get-Module | Select-Object -ExpandProperty Name
                $Snapins = Get-PSSnapin | Select-Object -ExpandProperty Name
                $Functions = Get-ChildItem function:\ | Select-Object -ExpandProperty Name

                
                
                $Variables = Get-Variable | Select-Object -ExpandProperty Name

                
                @{
                    Variables   = $Variables
                    Modules     = $Modules
                    Snapins     = $Snapins
                    Functions   = $Functions
                }
            }).invoke()[0]

            if ($ImportVariables) {
                
                Function _temp {[cmdletbinding(SupportsShouldProcess=$True)] param() }
                $VariablesToExclude = @( (Get-Command _temp | Select-Object -ExpandProperty parameters).Keys + $PSBoundParameters.Keys + $StandardUserEnv.Variables )
                Write-Verbose "Excluding variables $( ($VariablesToExclude | Sort-Object ) -join ", ")"

                
                
                
                
                $UserVariables = @( Get-Variable | Where-Object { -not ($VariablesToExclude -contains $_.Name) } )
                Write-Verbose "Found variables to import: $( ($UserVariables | Select-Object -expandproperty Name | Sort-Object ) -join ", " | Out-String).`n"
            }
            if ($ImportModules) {
                $UserModules = @( Get-Module | Where-Object {$StandardUserEnv.Modules -notcontains $_.Name -and (Test-Path $_.Path -ErrorAction SilentlyContinue)} | Select-Object -ExpandProperty Path )
                $UserSnapins = @( Get-PSSnapin | Select-Object -ExpandProperty Name | Where-Object {$StandardUserEnv.Snapins -notcontains $_ } )
            }
            if($ImportFunctions) {
                $UserFunctions = @( Get-ChildItem function:\ | Where-Object { $StandardUserEnv.Functions -notcontains $_.Name } )
            }
        }

        
            Function Get-RunspaceData {
                [cmdletbinding()]
                param( [switch]$Wait )
                
                
                Do {
                    
                    $more = $false

                    
                    if (-not $Quiet) {
                        Write-Progress -Id $ProgressId -Activity "Running Query" -Status "Starting threads"`
                            -CurrentOperation "$startedCount threads defined - $totalCount input objects - $script:completedCount input objects processed"`
                            -PercentComplete $( Try { $script:completedCount / $totalCount * 100 } Catch {0} )
                    }

                    
                    Foreach($runspace in $runspaces) {

                        
                        $currentdate = Get-Date
                        $runtime = $currentdate - $runspace.startTime
                        $runMin = [math]::Round( $runtime.totalminutes ,2 )

                        
                        $log = "" | Select-Object Date, Action, Runtime, Status, Details
                        $log.Action = "Removing:'$($runspace.object)'"
                        $log.Date = $currentdate
                        $log.Runtime = "$runMin minutes"

                        
                        If ($runspace.Runspace.isCompleted) {

                            $script:completedCount++

                            
                            if($runspace.powershell.Streams.Error.Count -gt 0) {
                                
                                $log.status = "CompletedWithErrors"
                                Write-Verbose ($log | ConvertTo-Csv -Delimiter ";" -NoTypeInformation)[1]
                                foreach($ErrorRecord in $runspace.powershell.Streams.Error) {
                                    Write-Error -ErrorRecord $ErrorRecord
                                }
                            }
                            else {
                                
                                $log.status = "Completed"
                                Write-Verbose ($log | ConvertTo-Csv -Delimiter ";" -NoTypeInformation)[1]
                            }

                            
                            $runspace.powershell.EndInvoke($runspace.Runspace)
                            $runspace.powershell.dispose()
                            $runspace.Runspace = $null
                            $runspace.powershell = $null
                        }
                        
                        ElseIf ( $runspaceTimeout -ne 0 -and $runtime.totalseconds -gt $runspaceTimeout) {
                            $script:completedCount++
                            $timedOutTasks = $true

                            
                            $log.status = "TimedOut"
                            Write-Verbose ($log | ConvertTo-Csv -Delimiter ";" -NoTypeInformation)[1]
                            Write-Error "Runspace timed out at $($runtime.totalseconds) seconds for the object:`n$($runspace.object | out-string)"

                            
                            if (!$noCloseOnTimeout) { $runspace.powershell.dispose() }
                            $runspace.Runspace = $null
                            $runspace.powershell = $null
                            $completedCount++
                        }

                        
                        ElseIf ($runspace.Runspace -ne $null ) {
                            $log = $null
                            $more = $true
                        }

                        
                        if($logFile -and $log) {
                            ($log | ConvertTo-Csv -Delimiter ";" -NoTypeInformation)[1] | out-file $LogFile -append
                        }
                    }

                    
                    $temphash = $runspaces.clone()
                    $temphash | Where-Object { $_.runspace -eq $Null } | ForEach-Object {
                        $Runspaces.remove($_)
                    }

                    
                    if($PSBoundParameters['Wait']){ Start-Sleep -milliseconds $SleepTimer }

                
                } while ($more -and $PSBoundParameters['Wait'])

            
            }
        

        

            if($PSCmdlet.ParameterSetName -eq 'ScriptFile') {
                $ScriptBlock = [scriptblock]::Create( $(Get-Content $ScriptFile | out-string) )
            }
            elseif($PSCmdlet.ParameterSetName -eq 'ScriptBlock') {
                
                [string[]]$ParamsToAdd = '$_'
                if( $PSBoundParameters.ContainsKey('Parameter') ) {
                    $ParamsToAdd += '$Parameter'
                }

                $UsingVariableData = $Null

                
                

                if($PSVersionTable.PSVersion.Major -gt 2) {
                    
                    $UsingVariables = $ScriptBlock.ast.FindAll({$args[0] -is [System.Management.Automation.Language.UsingExpressionAst]},$True)

                    If ($UsingVariables) {
                        $List = New-Object 'System.Collections.Generic.List`1[System.Management.Automation.Language.VariableExpressionAst]'
                        ForEach ($Ast in $UsingVariables) {
                            [void]$list.Add($Ast.SubExpression)
                        }

                        $UsingVar = $UsingVariables | Group-Object -Property SubExpression | ForEach-Object {$_.Group | Select-Object -First 1}

                        
                        $UsingVariableData = ForEach ($Var in $UsingVar) {
                            try {
                                $Value = Get-Variable -Name $Var.SubExpression.VariablePath.UserPath -ErrorAction Stop
                                [pscustomobject]@{
                                    Name = $Var.SubExpression.Extent.Text
                                    Value = $Value.Value
                                    NewName = ('$__using_{0}' -f $Var.SubExpression.VariablePath.UserPath)
                                    NewVarName = ('__using_{0}' -f $Var.SubExpression.VariablePath.UserPath)
                                }
                            }
                            catch {
                                Write-Error "$($Var.SubExpression.Extent.Text) is not a valid Using: variable!"
                            }
                        }
                        $ParamsToAdd += $UsingVariableData | Select-Object -ExpandProperty NewName -Unique

                        $NewParams = $UsingVariableData.NewName -join ', '
                        $Tuple = [Tuple]::Create($list, $NewParams)
                        $bindingFlags = [Reflection.BindingFlags]"Default,NonPublic,Instance"
                        $GetWithInputHandlingForInvokeCommandImpl = ($ScriptBlock.ast.gettype().GetMethod('GetWithInputHandlingForInvokeCommandImpl',$bindingFlags))

                        $StringScriptBlock = $GetWithInputHandlingForInvokeCommandImpl.Invoke($ScriptBlock.ast,@($Tuple))

                        $ScriptBlock = [scriptblock]::Create($StringScriptBlock)

                        Write-Verbose $StringScriptBlock
                    }
                }

                $ScriptBlock = $ExecutionContext.InvokeCommand.NewScriptBlock("param($($ParamsToAdd -Join ", "))`r`n" + $Scriptblock.ToString())
            }
            else {
                Throw "Must provide ScriptBlock or ScriptFile"; Break
            }

            Write-Debug "`$ScriptBlock: $($ScriptBlock | Out-String)"
            Write-Verbose "Creating runspace pool and session states"

            
            $sessionstate = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
            if($ImportVariables -and $UserVariables.count -gt 0) {
                foreach($Variable in $UserVariables) {
                    $sessionstate.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList $Variable.Name, $Variable.Value, $null) )
                }
            }
            if ($ImportModules) {
                if($UserModules.count -gt 0) {
                    foreach($ModulePath in $UserModules) {
                        $sessionstate.ImportPSModule($ModulePath)
                    }
                }
                if($UserSnapins.count -gt 0) {
                    foreach($PSSnapin in $UserSnapins) {
                        [void]$sessionstate.ImportPSSnapIn($PSSnapin, [ref]$null)
                    }
                }
            }
            if($ImportFunctions -and $UserFunctions.count -gt 0) {
                foreach ($FunctionDef in $UserFunctions) {
                    $sessionstate.Commands.Add((New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $FunctionDef.Name,$FunctionDef.ScriptBlock))
                }
            }

            
            $runspacepool = [runspacefactory]::CreateRunspacePool(1, $Throttle, $sessionstate, $Host)
            $runspacepool.Open()

            Write-Verbose "Creating empty collection to hold runspace jobs"
            $Script:runspaces = New-Object System.Collections.ArrayList

            
            $bound = $PSBoundParameters.keys -contains "InputObject"
            if(-not $bound) {
                [System.Collections.ArrayList]$allObjects = @()
            }

            
            if( $LogFile -and (-not (Test-Path $LogFile) -or $AppendLog -eq $false)){
                New-Item -ItemType file -Path $logFile -Force | Out-Null
                ("" | Select-Object -Property Date, Action, Runtime, Status, Details | ConvertTo-Csv -NoTypeInformation -Delimiter ";")[0] | Out-File $LogFile
            }

            
            $log = "" | Select-Object -Property Date, Action, Runtime, Status, Details
                $log.Date = Get-Date
                $log.Action = "Batch processing started"
                $log.Runtime = $null
                $log.Status = "Started"
                $log.Details = $null
                if($logFile) {
                    ($log | convertto-csv -Delimiter ";" -NoTypeInformation)[1] | Out-File $LogFile -Append
                }
            $timedOutTasks = $false
        
    }
    process {
        
        if($bound) {
            $allObjects = $InputObject
        }
        else {
            [void]$allObjects.add( $InputObject )
        }
    }
    end {
        
        try {
            
            $totalCount = $allObjects.count
            $script:completedCount = 0
            $startedCount = 0
            foreach($object in $allObjects) {
                
                    
                    $powershell = [powershell]::Create()

                    if ($VerbosePreference -eq 'Continue') {
                        [void]$PowerShell.AddScript({$VerbosePreference = 'Continue'})
                    }

                    [void]$PowerShell.AddScript($ScriptBlock).AddArgument($object)

                    if ($parameter) {
                        [void]$PowerShell.AddArgument($parameter)
                    }

                    
                    if ($UsingVariableData) {
                        Foreach($UsingVariable in $UsingVariableData) {
                            Write-Verbose "Adding $($UsingVariable.Name) with value: $($UsingVariable.Value)"
                            [void]$PowerShell.AddArgument($UsingVariable.Value)
                        }
                    }

                    
                    $powershell.RunspacePool = $runspacepool

                    
                    $temp = "" | Select-Object PowerShell, StartTime, object, Runspace
                    $temp.PowerShell = $powershell
                    $temp.StartTime = Get-Date
                    $temp.object = $object

                    
                    $temp.Runspace = $powershell.BeginInvoke()
                    $startedCount++

                    
                    Write-Verbose ( "Adding {0} to collection at {1}" -f $temp.object, $temp.starttime.tostring() )
                    $runspaces.Add($temp) | Out-Null

                    
                    Get-RunspaceData

                    
                    
                    $firstRun = $true
                    while ($runspaces.count -ge $Script:MaxQueue) {
                        
                        if($firstRun) {
                            Write-Verbose "$($runspaces.count) items running - exceeded $Script:MaxQueue limit."
                        }
                        $firstRun = $false

                        
                        Get-RunspaceData
                        Start-Sleep -Milliseconds $sleepTimer
                    }
                
            }
            Write-Verbose ( "Finish processing the remaining runspace jobs: {0}" -f ( @($runspaces | Where-Object {$_.Runspace -ne $Null}).Count) )

            Get-RunspaceData -wait
            if (-not $quiet) {
                Write-Progress -Id $ProgressId -Activity "Running Query" -Status "Starting threads" -Completed
            }
        }
        finally {
            
            if ( ($timedOutTasks -eq $false) -or ( ($timedOutTasks -eq $true) -and ($noCloseOnTimeout -eq $false) ) ) {
                Write-Verbose "Closing the runspace pool"
                $runspacepool.close()
            }
            
            [gc]::Collect()
        }
    }
}