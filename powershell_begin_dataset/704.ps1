


function Connect-RsReportServer
{
    
    
    [CmdletBinding()]
    param
    (
        [AllowEmptyString()]
        [AllowNull()]
        [string]
        $ComputerName,
        
        [Alias('SqlServerInstance')]
        [string]
        $ReportServerInstance,
        
        [Alias('SqlServerVersion')]
        [Microsoft.ReportingServicesTools.SqlServerVersion]
        $ReportServerVersion,
        
        [AllowEmptyString()]
        [AllowNull()]
        [PSCredential]
        $Credential,
        
        [Alias('Uri')]
        [string]
        $ReportServerUri,

        [string]
        $ReportPortalUri,
        
        [switch]
        $RegisterProxy,

        [Alias('ApiVersion')]
        [ValidateSet('2005','2006','2010')]
        [string]
        $SoapEndpointApiVersion = '2010',

        [switch]
        $CustomAuthentication
    )
    
    if ($PSBoundParameters.ContainsKey("ComputerName"))
    {
        [Microsoft.ReportingServicesTools.ConnectionHost]::ComputerName = $ComputerName
    }
    if ($PSBoundParameters.ContainsKey("ReportServerInstance"))
    {
        [Microsoft.ReportingServicesTools.ConnectionHost]::Instance = $ReportServerInstance
    }
    if ($PSBoundParameters.ContainsKey("ReportServerVersion"))
    {
        [Microsoft.ReportingServicesTools.ConnectionHost]::Version = $ReportServerVersion
    }
    if ($PSBoundParameters.ContainsKey("Credential"))
    {
        [Microsoft.ReportingServicesTools.ConnectionHost]::Credential = $Credential
    }
    
    if ($PSBoundParameters.ContainsKey("ReportServerUri"))
    {
        [Microsoft.ReportingServicesTools.ConnectionHost]::ReportServerUri = $ReportServerUri
        try
        {
            $proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
            [Microsoft.ReportingServicesTools.ConnectionHost]::Proxy = $proxy
        }
        catch
        {
            throw (New-Object System.Exception("Failed to establish proxy connection to $ReportServerUri : $($_.Exception.Message)", $_.Exception))
        }
    }

    if ($PSBoundParameters.ContainsKey("ReportPortalUri")) 
    {
        [Microsoft.ReportingServicesTools.ConnectionHost]::ReportPortalUri = $ReportPortalUri
    }
}
