function Log-ArtifactNotFoundInPSGallery
{
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [string[]]
        $SearchedName,

        [Parameter()]
        [string[]]
        $FoundName,

        [Parameter(Mandatory=$true)]
        [string]
        $operationName
    )

    if (-not $script:TelemetryEnabled)
    {
        return
    }

    if(-not $SearchedName)
    {
        return
    }

    $SearchedNameNoWildCards = @()

    
    foreach ($artifactName in $SearchedName)
    {
        if (-not (Test-WildcardPattern $artifactName))
        {
            $SearchedNameNoWildCards += $artifactName
        }
    }

    
    $notFoundArtifacts = @()
    foreach ($element in $SearchedNameNoWildCards)
    {
        if (-not ($FoundName -contains $element))
        {
            $notFoundArtifacts += $element
        }
    }

    
    if ($notFoundArtifacts)
    {
        [Microsoft.PowerShell.Commands.PowerShellGet.Telemetry]::TraceMessageArtifactsNotFound($notFoundArtifacts, $operationName)
    }
}