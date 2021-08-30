function Log-NonPSGalleryRegistration


{
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [string]
        $sourceLocation,

        [Parameter()]
        [string]
        $installationPolicy,

        [Parameter()]
        [string]
        $packageManagementProvider,

        [Parameter()]
        [string]
        $publishLocation,

        [Parameter()]
        [string]
        $scriptSourceLocation,

        [Parameter()]
        [string]
        $scriptPublishLocation,

        [Parameter(Mandatory=$true)]
        [string]
        $operationName
    )

    if (-not $script:TelemetryEnabled)
    {
        return
    }

    
    $sourceLocationType = "NON_WEB_HOSTED"
    if (Test-WebUri -uri $sourceLocation)
    {
        $sourceLocationType = "WEB_HOSTED"
    }

    
    
    $sourceLocationHash = Get-Hash -locationString $sourceLocation
    $publishLocationHash = Get-Hash -locationString $publishLocation
    $scriptSourceLocationHash = Get-Hash -locationString $scriptSourceLocation
    $scriptPublishLocationHash = Get-Hash -locationString $scriptPublishLocation

    
    [Microsoft.PowerShell.Commands.PowerShellGet.Telemetry]::TraceMessageNonPSGalleryRegistration($sourceLocationType, $sourceLocationHash, $installationPolicy, $packageManagementProvider, $publishLocationHash, $scriptSourceLocationHash, $scriptPublishLocationHash, $operationName)
}