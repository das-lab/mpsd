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
