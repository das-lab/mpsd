function Invoke-psake {
    
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $false)]
        [string]$buildFile,

        [Parameter(Position = 1, Mandatory = $false)]
        [string[]]$taskList = @(),

        [Parameter(Position = 2, Mandatory = $false)]
        [string]$framework,

        [Parameter(Position = 3, Mandatory = $false)]
        [switch]$docs = $false,

        [Parameter(Position = 4, Mandatory = $false)]
        [hashtable]$parameters = @{},

        [Parameter(Position = 5, Mandatory = $false)]
        [hashtable]$properties = @{},

        [Parameter(Position = 6, Mandatory = $false)]
        [alias("init")]
        [scriptblock]$initialization = {},

        [Parameter(Position = 7, Mandatory = $false)]
        [switch]$nologo,

        [Parameter(Position = 8, Mandatory = $false)]
        [switch]$detailedDocs,

        [Parameter(Position = 9, Mandatory = $false)]
        [switch]$notr 
    )

    try {
        if (-not $nologo) {
            "psake version {0}$($script:nl)Copyright (c) 2010-2018 James Kovacs & Contributors$($script:nl)" -f $psake.version
        }
        if (!$buildFile) {
           $buildFile = Get-DefaultBuildFile
        }
        elseif (!(Test-Path $buildFile -PathType Leaf) -and ($null -ne (Get-DefaultBuildFile -UseDefaultIfNoneExist $false))) {
            
            
            $taskList = $buildFile.Split(', ')
            $buildFile = Get-DefaultBuildFile
        }

        $psake.error_message = $null

        ExecuteInBuildFileScope $buildFile $MyInvocation.MyCommand.Module {
            param($currentContext, $module)

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            if ($docs -or $detailedDocs) {
                WriteDocumentation($detailedDocs)
                return
            }

            try {
                foreach ($key in $parameters.keys) {
                    if (test-path "variable:\$key") {
                        set-item -path "variable:\$key" -value $parameters.$key -WhatIf:$false -Confirm:$false | out-null
                    } else {
                        new-item -path "variable:\$key" -value $parameters.$key -WhatIf:$false -Confirm:$false | out-null
                    }
                }
            } catch {
                WriteColoredOutput "Parameter '$key' is null" -foregroundcolor Red
                throw
            }

            
            while ($currentContext.properties.Count -gt 0) {
                $propertyBlock = $currentContext.properties.Pop()
                . $propertyBlock
            }

            foreach ($key in $properties.keys) {
                if (test-path "variable:\$key") {
                    set-item -path "variable:\$key" -value $properties.$key -WhatIf:$false -Confirm:$false | out-null
                }
            }

            
            
            . $module $initialization

            & $currentContext.buildSetupScriptBlock

            
            try {
                if ($taskList) {
                    foreach ($task in $taskList) {
                        invoke-task $task
                    }
                } elseif ($currentContext.tasks.default) {
                    invoke-task default
                } else {
                    throw $msgs.error_no_default_task
                }
            }
            finally {
                & $currentContext.buildTearDownScriptBlock
            }

            $successMsg = $msgs.psake_success -f $buildFile
            WriteColoredOutput ("$($script:nl)${successMsg}$($script:nl)") -foregroundcolor Green

            $stopwatch.Stop()
            if (-not $notr) {
                WriteTaskTimeSummary $stopwatch.Elapsed
            }
        }

        $psake.build_success = $true

    } catch {
        $psake.build_success = $false
        $psake.error_message = FormatErrorMessage $_

        
        
        $inNestedScope = ($psake.context.count -gt 1)
        if ( $inNestedScope ) {
            throw $_
        } else {
            if (!$psake.run_by_psake_build_tester) {
                WriteColoredOutput $psake.error_message -foregroundcolor Red
            }
        }
    } finally {
        CleanupEnvironment
    }
}
