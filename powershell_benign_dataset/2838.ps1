function LoadConfiguration {
    
    param(
        [string]$configdir = (Split-Path -Path $PSScriptRoot -Parent)
    )

    $configFilePath  = Join-Path -Path $configdir -ChildPath $script:psakeConfigFile
    $defaultConfigFilePath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath $script:psakeConfigFile

    if (Test-Path -LiteralPath $configFilePath -PathType Leaf) {
        $configFileToLoad = $configFilePath
    } elseIf (Test-Path -LiteralPath $defaultConfigFilePath -PathType Leaf) {
        $configFileToLoad = $defaultConfigFilePath
    } else {
        throw 'Cannot find psake-config.ps1'
    }

    try {
        [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssigments', '')]
        $config = GetCurrentConfigurationOrDefault
        . $configFileToLoad
    } catch {
        throw 'Error Loading Configuration from {0}: {1}' -f $configFileToLoad, $_
    }
}
