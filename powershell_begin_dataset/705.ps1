


function New-RsConfigurationSettingObject
{
    

    [cmdletbinding()]
    param
    (
        [Alias('SqlServerInstance')]
        [string]
        $ReportServerInstance = ([Microsoft.ReportingServicesTools.ConnectionHost]::Instance),
        
        [Alias('SqlServerVersion')]
        [Microsoft.ReportingServicesTools.SqlServerVersion]
        $ReportServerVersion = ([Microsoft.ReportingServicesTools.ConnectionHost]::Version),
        
        [string]
        $ComputerName = ([Microsoft.ReportingServicesTools.ConnectionHost]::ComputerName),
        
        [System.Management.Automation.PSCredential]
        $Credential = ([Microsoft.ReportingServicesTools.ConnectionHost]::Credential),
        
        [Alias('MinimumSqlServerVersion')]
        [Microsoft.ReportingServicesTools.SqlServerVersion]
        $MinimumReportServerVersion
    )
    
    if (($MinimumReportServerVersion) -and ($MinimumReportServerVersion -gt $ReportServerVersion))
    {
        throw (New-Object System.Management.Automation.PSArgumentException("Trying to connect to $ComputerName \ $ReportServerInstance, but it is only $ReportServerVersion when at least $MinimumReportServerVersion is required!"))
    }
    
    $getWmiObjectParameters = @{
        ErrorAction = "Stop"
        Namespace = "root\Microsoft\SqlServer\ReportServer\RS_$ReportServerInstance\v$($ReportServerVersion.Value__)\Admin"
        Class = "MSReportServer_ConfigurationSetting"
    }
    
    if ($ComputerName)
    {
        $getWmiObjectParameters["ComputerName"] = $ComputerName
    }
    if ($Credential)
    {
        $getWmiObjectParameters["Credential"] = $Credential
    }
    
    $wmiObjects = Get-WmiObject @getWmiObjectParameters
    return $wmiObjects | Where-Object { $_.InstanceName -eq $ReportServerInstance }
}
