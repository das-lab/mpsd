function Compare-PrereleaseVersions
{
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        $FirstItemVersion,

        [string]
        $FirstItemPrerelease,

        [ValidateNotNullOrEmpty()]
        [string]
        $SecondItemVersion,

        [string]
        $SecondItemPrerelease
    )

    

    [version]$itemOneVersion = $null
    
    if (-not ( [System.Version]::TryParse($FirstItemVersion.Trim(), [ref]$itemOneVersion) ))
    {
        $message = $LocalizedData.InvalidVersion -f ($FirstItemVersion)
        Write-Error -Message $message -ErrorId "InvalidVersion" -Category InvalidArgument
        return
    }

    [Version]$itemTwoVersion = $null
    
    if (-not ( [System.Version]::TryParse($SecondItemVersion.Trim(), [ref]$itemTwoVersion) ))
    {
        $message = $LocalizedData.InvalidVersion -f ($SecondItemVersion)
        Write-Error -Message $message -ErrorId "InvalidVersion" -Category InvalidArgument
        return
    }

    return (($itemOneVersion -lt $itemTwoVersion) -or `
            (($itemOneVersion -eq $itemTwoVersion) -and `
             (($FirstItemPrerelease -and -not $SecondItemPrerelease) -or `
              ($FirstItemPrerelease -lt $SecondItemPrerelease))))
}