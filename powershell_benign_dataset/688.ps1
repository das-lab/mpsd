



function Register-RsPowerBI
{
    

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [Parameter(Mandatory = $True)]
        [string]
        $ClientId,

        [Parameter(Mandatory = $True)]
        [string]
        $ClientSecret,
        
        [Parameter(Mandatory = $True)]
        [string]
        $AppObjectId,
        
        [Parameter(Mandatory = $True)]
        [string]
        $TenantName,
        
        [Parameter(Mandatory = $True)]
        [string]
        $TenantId,
        
        [string]
        $ResourceUrl = 'https://analysis.windows.net/powerbi/api',
        
        [string]
        $AuthUrl = 'https://login.windows.net/common/oauth2/authorize',
        
        [string]
        $TokenUrl = 'https://login.microsoftonline.com/common/oauth2/token',
        
        [Parameter(Mandatory = $True)]
        [string]
        $RedirectUrls,
        
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
    
    if ($PSCmdlet.ShouldProcess((Get-ShouldProcessTargetWmi -BoundParameters $PSBoundParameters), "Registering PowerBI for SQL Server Instance"))
    {
        $rsWmiObject = New-RsConfigurationSettingObjectHelper -BoundParameters $PSBoundParameters

        Write-Verbose "Configuring Power BI ..."
        $configureResult = $rsWmiObject.SavePowerBIInformation($ClientId,
                                                               $ClientSecret,
                                                               $AppObjectId,
                                                               $TenantName,
                                                               $TenantId,
                                                               $ResourceUrl,
                                                               $AuthUrl,
                                                               $TokenUrl,
                                                               $RedirectUrls)
        
        if ($configureResult.HRESULT -eq 0)
        {
            Write-Verbose "Configuring Power BI ... Success!"
        }
        else
        {
            throw "Failed to register PowerBI for server instance: $ReportServerInstance. Errors: $($configureResult.ExtendedErrors)"
        }
    }
}
New-Alias -Name "Register-PowerBI" -Value "Register-RsPowerBI" -Scope Global
