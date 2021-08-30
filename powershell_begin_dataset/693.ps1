function New-RsWebServiceProxyHelper
{
    
    [CmdletBinding()]
    Param (
        [AllowNull()]
        [object]
        $BoundParameters
    )
    
    if ($BoundParameters["Proxy"])
    {
        return $BoundParameters["Proxy"]
    }
    
    $goodKeys = @("ReportServerUri", "Credential", "ApiVersion", "CustomAuthentication")
    $NewRsWebServiceProxyParam = @{ }
    
    foreach ($key in $BoundParameters.Keys)
    {
        if ($goodKeys -contains $key)
        {
            $NewRsWebServiceProxyParam[$key] = $BoundParameters[$key]
        }
    }
    
    New-RsWebServiceProxy @NewRsWebServiceProxyParam
}

function New-RsRestSessionHelper
{
    

    [CmdletBinding()]
    Param (
        [AllowNull()]
        [object]
        $BoundParameters
    )

    if ($BoundParameters["WebSession"])
    {
        return $BoundParameters["WebSession"]
    }

    $goodKeys = @("ReportPortalUri", "RestApiVersion", "Credential")
    $NewRsRestSessionParams = @{ }

    foreach ($key in $BoundParameters.Keys)
    {
        if ($goodKeys -contains $key)
        {
            $NewRsRestSessionParams[$key] = $BoundParameters[$key]
        }
    }

    New-RsRestSession @NewRsRestSessionParams
}

function Get-RsPortalUriHelper
{
    

    [CmdletBinding()]
    Param (
        [AllowNull()]
        [Microsoft.PowerShell.Commands.WebRequestSession]
        $WebSession
    )

    if ($WebSession -ne $null)
    {
        $reportPortalUri = $WebSession.Headers['X-RSTOOLS-PORTALURI']
        if (![String]::IsNullOrEmpty($reportPortalUri))
        {
            if ($reportPortalUri -notlike '*/') 
            {
                $reportPortalUri = $reportPortalUri + '/'
            }
            return $reportPortalUri
        }
    }

    throw "Invalid WebSession specified! Please specify a valid WebSession or run New-RsRestSession to create a new one."
}

function New-RsConfigurationSettingObjectHelper
{
    
    [CmdletBinding()]
    Param (
        [AllowNull()]
        [object]
        $BoundParameters
    )
    
    $goodKeys = @("SqlServerInstance", "ReportServerInstance", "SqlServerVersion", "ReportServerVersion", "ComputerName", "Credential", "MinimumSqlServerVersion", "MinimumReportServerVersion")
    $NewRsConfigurationSettingObjectParam = @{ }
    
    foreach ($key in $BoundParameters.Keys)
    {
        if ($goodKeys -contains $key)
        {
            $NewRsConfigurationSettingObjectParam[$key] = $BoundParameters[$key]
        }
    }
    
    New-RsConfigurationSettingObject @NewRsConfigurationSettingObjectParam
}
