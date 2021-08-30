


function Set-PbiRsUrlReservation
{
    
    
    [cmdletbinding()]
    param
    (
        [string]
        $ReportServerVirtualDirectory = "ReportServer",
        
        [string]
        $PortalVirtualDirectory="Reports",
        
        [Alias('SqlServerInstance')]
        [string]
        $ReportServerInstance,
        
        [Alias('SqlServerVersion')]
        [Microsoft.ReportingServicesTools.SqlServerVersion]
        $ReportServerVersion,
        
        [string]
        $ComputerName,
        
        [System.Management.Automation.PSCredential]
        $Credential,

        [int]
        $ListeningPort=80
    )
    
    $pbirsWmiObject = New-RsConfigurationSettingObjectHelper -BoundParameters $PSBoundParameters
    
    try
    {
        Set-RsUrlReservation -ReportServerVirtualDirectory $ReportServerVirtualDirectory -PortalVirtualDirectory $PortalVirtualDirectory -ReportServerInstance $ReportServerInstance -ReportServerVersion $ReportServerVersion -ComputerName $ComputerName -Credential $Credential -ListeningPort $ListeningPort

        $powerBiApp = "PowerBIWebApp"
        Write-Verbose "Reserving Url for $powerBiApp..."
        $result = $pbirsWmiObject.ReserveURL($powerBiApp,"http://+:$ListeningPort",(Get-Culture).Lcid)

        if ($result.HRESULT -ne 0)
        {
            throw "Failed Reserving Url for $powerBiApp, Errocode: $($result.HRESULT)"
        }

        $officeWebApp = "OfficeWebApp"
        Write-Verbose "Reserving Url for $officeWebApp..."
        $result = $pbirsWmiObject.ReserveURL($officeWebApp,"http://+:$ListeningPort",(Get-Culture).Lcid)
        
        if ($result.HRESULT -ne 0)
        {
            throw "Failed Reserving Url for $officeWebApp, Errocode: $($result.HRESULT)"
        }       

        Write-Verbose "Success!"
    }
    catch
    {
        throw (New-Object System.Exception("Failed to reserve Urls $($_.Exception.Message)", $_.Exception))
    }
    
    if ($result.HRESULT -ne 0)
    {
        throw "Failed to reserve Urls, Errocode: $($result.HRESULT)"
    }
}
