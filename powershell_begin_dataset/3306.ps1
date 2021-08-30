
function New-PoshBotMiddlewareHook {
    
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope='Function', Target='*')]
    [cmdletbinding()]
    param(
        [parameter(mandatory)]
        [string]$Name,

        [parameter(mandatory)]
        [ValidateScript({
            if (-not (Test-Path -Path $_)) {
                throw 'Invalid script path'
            } else {
                $true
            }
        })]
        [string]$Path
    )

    [MiddlewareHook]::new($Name, $Path)
}

Export-ModuleMember -Function 'New-PoshBotMiddlewareHook'
