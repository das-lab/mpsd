


function Set-RsUrlReservation
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
    
    $rsWmiObject = New-RsConfigurationSettingObjectHelper -BoundParameters $PSBoundParameters
    
    try
    {
        Write-Verbose "Setting Virtual Directory for ReportServerWebService..."
        $result = $rsWmiObject.SetVirtualDirectory("ReportServerWebService",$ReportServerVirtualDirectory,(Get-Culture).Lcid)
        
        if ($result.HRESULT -ne 0)
        {
            throw "Failed Setting Virtual Directory for ReportServerWebService, Errocode: $($result.HRESULT)"
        }

        Write-Verbose "Reserving Url for ReportServerWebService..."
        $result = $rsWmiObject.ReserveURL("ReportServerWebService","http://+:$ListeningPort",(Get-Culture).Lcid)

        if ($result.HRESULT -ne 0)
        {
            throw "Failed Reserving Url for ReportServerWebService, Errocode: $($result.HRESULT)"
        }

        if($ReportServerVersion -and $ReportServerVersion -lt 13)
        {
            $reportServerWebappName = "ReportManager"
        }
        else
        {
            $reportServerWebappName = "ReportServerWebApp"
        }

        Write-Verbose "Setting Virtual Directory for $reportServerWebappName..."
        $result = $rsWmiObject.SetVirtualDirectory($reportServerWebappName,$PortalVirtualDirectory,(Get-Culture).Lcid)

        if ($result.HRESULT -ne 0)
        {
            throw "Failed Setting Virtual Directory for $reportServerWebappName, Errocode: $($result.HRESULT)"
        }

        Write-Verbose "Reserving Url for $reportServerWebappName..."
        $result = $rsWmiObject.ReserveURL($reportServerWebappName,"http://+:$ListeningPort",(Get-Culture).Lcid)

        if ($result.HRESULT -ne 0)
        {
            throw "Failed Reserving Url for $reportServerWebappName, Errocode: $($result.HRESULT)"
        }


        Write-Verbose "Success!"
    }
    catch
    {
        throw (New-Object System.Exception("Failed to reserve Urls $($_.Exception.Message)", $_.Exception))
    }   
}
