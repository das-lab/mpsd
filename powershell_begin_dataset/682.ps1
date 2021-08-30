


function Initialize-Rs
{
    
    
    [cmdletbinding()]
    param
    (
      
        [Alias('SqlServerInstance')]
        [string]
        $ReportServerInstance,
        
        [Alias('SqlServerVersion')]
        [Microsoft.ReportingServicesTools.SqlServerVersion]
        $ReportServerVersion,
        
        [string]
        $ComputerName,
        
        [System.Management.Automation.PSCredential]
        $Credential
    )
    
    $rsWmiObject = New-RsConfigurationSettingObjectHelper -BoundParameters $PSBoundParameters
    
    try
    {
        Write-Verbose "Initializing Report Server..."
        $result = $rsWmiObject.InitializeReportServer($rsWmiObject.InstallationID)
        Write-Verbose "Success!"
    }
    catch
    {
        throw (New-Object System.Exception("Failed to Initialize Report Server $($_.Exception.Message)", $_.Exception))
    }
    
    if ($result.HRESULT -ne 0)
    {
        throw "Failed to Initialize Report Server, ErrorCode: $($result.HRESULT)"
    }
}
