


function New-RsWebServiceProxy
{
    

    [cmdletbinding()]
    param
    (
        [string]
        $ReportServerUri = ([Microsoft.ReportingServicesTools.ConnectionHost]::ReportServerUri),
        
        [Alias('Credentials')]
        [AllowNull()]
        [System.Management.Automation.PSCredential]
        $Credential = ([Microsoft.ReportingServicesTools.ConnectionHost]::Credential),

        [ValidateSet('2005','2006','2010')]
        [string]
        $ApiVersion = '2010',

        [switch]
        $CustomAuthentication
    )
    
    
    if (-not ($PSBoundParameters.ContainsKey("ReportServerUri") -or $PSBoundParameters.ContainsKey("Credential")))
    {
        if ([Microsoft.ReportingServicesTools.ConnectionHost]::Proxy)
        {
            return ([Microsoft.ReportingServicesTools.ConnectionHost]::Proxy)
        }
        else
        {
            try
            {
                $proxy = New-RsWebServiceProxy -ReportServerUri ([Microsoft.ReportingServicesTools.ConnectionHost]::ReportServerUri) -Credential ([Microsoft.ReportingServicesTools.ConnectionHost]::Credential) -ErrorAction Stop
                [Microsoft.ReportingServicesTools.ConnectionHost]::Proxy = $proxy
                return $proxy
            }
            catch
            {
                throw (New-Object System.Exception("Failed to establish proxy connection to $([Microsoft.ReportingServicesTools.ConnectionHost]::ReportServerUri) : $($_.Exception.Message)", $_.Exception))
            }
        }
    }
    

    
    
    if ($ReportServerUri -notlike '*/') 
    {
        $ReportServerUri = $ReportServerUri + '/'
    }
    $reportServerUriObject = New-Object System.Uri($ReportServerUri)
    $soapEndpointUriObject = New-Object System.Uri($reportServerUriObject, "ReportService$ApiVersion.asmx")
    $ReportServerUri = $soapEndPointUriObject.ToString()
    
    
    try
    {
        Write-Verbose "Establishing proxy connection to $ReportServerUri..."
        if ($Credential)
        {
            $proxy = New-WebServiceProxy -Uri $ReportServerUri -Credential $Credential -ErrorAction Stop
        }
        else
        {
            $proxy = New-WebServiceProxy -Uri $ReportServerUri -UseDefaultCredential -ErrorAction Stop
        }

        if ($CustomAuthentication)
        {
            if (!$Credential) 
            {
                $Credential = Get-Credential
            }
            $NetworkCredential = $Credential.GetNetworkCredential()

            $proxy.CookieContainer = New-Object System.Net.CookieContainer
            $proxy.LogonUser($NetworkCredential.UserName, $NetworkCredential.Password, "Forms")

            Write-Verbose "Authenticated!"    
        }

        return $proxy
    }
    catch
    {
        throw (New-Object System.Exception("Failed to establish proxy connection to $ReportServerUri : $($_.Exception.Message)", $_.Exception))
    }
    
}
