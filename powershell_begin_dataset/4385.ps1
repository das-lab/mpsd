function Get-NormalizedVersionString
{
    
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Version
    )

    [Version]$ParsedVersion = $null
    if ([System.Version]::TryParse($Version, [ref]$ParsedVersion)) {
        $Build = $ParsedVersion.Build
        if ($Build -eq -1) {
            $Build = 0
        }

        return "$($ParsedVersion.Major).$($ParsedVersion.Minor).$Build"
    }

    return $Version
}