function Get-ShouldProcessTargetWmi
{
    
    [CmdletBinding()]
    Param (
        [AllowNull()]
        [object]
        $BoundParameters,
        
        [string]
        $Target
    )
    
    if ($BoundParameters["ComputerName"])
    {
        $Server = $BoundParameters["ComputerName"]
    }
    elseif ([Microsoft.ReportingServicesTools.ConnectionHost]::ComputerName)
    {
        $Server = [Microsoft.ReportingServicesTools.ConnectionHost]::ComputerName
    }
    else
    {
        $Server = $env:COMPUTERNAME
    }
    
    if ($BoundParameters["ReportServerVersion"])
    {
        $Version = $BoundParameters["ReportServerVersion"]
    }
    else
    {
        $Version = [Microsoft.ReportingServicesTools.ConnectionHost]::Version
    }    
    
    if ($BoundParameters["ReportServerInstance"])
    {
        $Instance = $BoundParameters["ReportServerInstance"]
    }
    else
    {
        $Instance = ([Microsoft.ReportingServicesTools.ConnectionHost]::Instance)
    }
    
    if ($PSBoundParameters.ContainsKey("Target"))
    {
        return "$Server ($Version) \ $Instance : $Target"
    }
    else
    {
        return "$Server ($Version) \ $Instance"
    }
}

function Get-ShouldProcessTargetWeb
{
    
    [CmdletBinding()]
    Param (
        [AllowNull()]
        [object]
        $BoundParameters,
        
        [string]
        $Target
    )
    
    if ($BoundParameters.ContainsKey("ReportServerUri"))
    {
        if ($Target)
        {
            return "$($BoundParameters["ReportServerUri"]) : $Target"
        }
        else
        {
            return $BoundParameters["ReportServerUri"]
        }
    }
    else
    {
        if ($Target)
        {
            return "$([Microsoft.ReportingServicesTools.ConnectionHost]::ReportServerUri) : $Target"
        }
        else
        {
            return [Microsoft.ReportingServicesTools.ConnectionHost]::ReportServerUri
        }
    }
}