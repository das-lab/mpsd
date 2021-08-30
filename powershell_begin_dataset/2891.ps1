Task default -Depends RunWhatIf

Task RunWhatIf {
    try {
        
        $global:WhatIfPreference = $true

        
        $parameters = @{p1='whatifcheck';}

        Invoke-psake .\nested\whatifpreference.ps1 -parameters $parameters
    } finally {
        $global:WhatIfPreference = $false
    }
}
