function Test-ItemPrereleaseVersionRequirements

{
    [CmdletBinding()]
    param(

        [ValidateNotNullOrEmpty()]
        [string]
        $Version,

        [string]
        $RequiredVersion,

        [string]
        $MinimumVersion,

        [string]
        $MaximumVersion
    )

    $result = ValidateAndGet-VersionPrereleaseStrings -Version $Version -CallerPSCmdlet $PSCmdlet
    if (-not $result)
    {
        
        
        return
    }
    $psgetitemVersion = $result["Version"]
    $psgetitemPrerelease = $result["Prerelease"]
    $psgetitemFullVersion = $result["FullVersion"]

    if($RequiredVersion)
    {
        $reqResult = ValidateAndGet-VersionPrereleaseStrings -Version $RequiredVersion -CallerPSCmdlet $PSCmdlet
        if (-not $reqResult)
        {
            
            
            return
        }
        $reqFullVersion = $reqResult["FullVersion"]

        return ($reqFullVersion -eq $psgetitemFullVersion)
    }
    else
    {
        $minimumBoundMet = $false
        if ($MinimumVersion)
        {
            $minResult = ValidateAndGet-VersionPrereleaseStrings -Version $MinimumVersion -CallerPSCmdlet $PSCmdlet
            if (-not $minResult)
            {
                
                
                return
            }
            $minVersion = $minResult["Version"]
            $minPrerelease = $minResult["Prerelease"]

            
            if (-not (Compare-PrereleaseVersions -FirstItemVersion $psgetitemVersion `
                                                 -FirstItemPrerelease $psgetitemPrerelease `
                                                 -SecondItemVersion $minVersion `
                                                 -SecondItemPrerelease $minPrerelease ))
            {
                $minimumBoundMet = $true
            }
        }
        else
        {
            $minimumBoundMet = $true
        }

        $maximumBoundMet = $false
        if ($MaximumVersion)
        {
            $maxResult = ValidateAndGet-VersionPrereleaseStrings -Version $MaximumVersion -CallerPSCmdlet $PSCmdlet
            if (-not $maxResult)
            {
                
                
                return
            }
            $maxVersion = $maxResult["Version"]
            $maxPrerelease = $maxResult["Prerelease"]

            
            if (-not (Compare-PrereleaseVersions -FirstItemVersion $maxVersion `
                                                 -FirstItemPrerelease $maxPrerelease `
                                                 -SecondItemVersion $psgetitemVersion `
                                                 -SecondItemPrerelease $psgetitemPrerelease ))
            {
                $maximumBoundMet = $true
            }
        }
        else
        {
            $maximumBoundMet = $true
        }

        return ($minimumBoundMet -and $maximumBoundMet)
    }
}