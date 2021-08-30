function Get-PSakeScriptTasks {
    
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseSingularNouns', '')]
    [CmdletBinding()]
    param(
        [string]$buildFile
    )

    if (-not $buildFile) {
        $buildFile = $psake.config_default.buildFileName
    }

    try {
        ExecuteInBuildFileScope $buildFile $MyInvocation.MyCommand.Module {
            param($currentContext, $module)
            return GetTasksFromContext $currentContext
        }
    } finally {
        CleanupEnvironment
    }
}
