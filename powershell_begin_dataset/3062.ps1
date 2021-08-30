function Set-TestInconclusive {
    
    [CmdletBinding()]
    param (
        [string] $Message
    )

    if (!$script:HasAlreadyWarnedAboutDeprecation) {
        Write-Warning 'DEPRECATED: Set-TestInconclusive was deprecated and will be removed in the future. Please update your scripts to use `Set-ItResult -Inconclusive -Because $Message`.'
        $script:HasAlreadyWarnedAboutDeprecation = $true
    }

    Set-ItResult -Inconclusive -Because $Message
}
