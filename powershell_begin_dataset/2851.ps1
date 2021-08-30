function Framework {
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$framework
    )

    $psake.context.Peek().config.framework = $framework

    ConfigureBuildEnvironment
}
