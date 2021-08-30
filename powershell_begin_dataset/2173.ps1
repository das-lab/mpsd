
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Position=0, Mandatory=$true, HelpMessage="Specify Primary Site server")]
    [ValidateScript({Test-Connection -ComputerName $_ -Count 2})]
    [string]$SiteServer = "$($env:COMPUTERNAME)",
    [parameter(Position=1, HelpMessage="Specify a specific application name")]
    [parameter(ParameterSetName="SingleApp")]
    [string]$ApplicationName,
    [parameter(Position=2,Mandatory=$true, HelpMessage="Specify the Post Install Behavior setting")]
    [parameter(ParameterSetName="SingleApp")]
    [parameter(ParameterSetName="MultipleApps")]
    [ValidateSet(
    "BasedOnExitCode",
    "NoAction",
    "ForceLogOff",
    "ForceReboot",
    "ProgramReboot"
    )]
    [string]$PostInstallBehavior,
    [parameter(Position=2, HelpMessage="Make changes to all applications")]
    [parameter(ParameterSetName="MultipleApps")]
    [switch]$Recurse
)
Begin {
    
    try {
        Write-Verbose "Determining SiteCode for Site Server: '$($SiteServer)'"
        $SiteCodeObjects = Get-WmiObject -Namespace "root\SMS" -Class SMS_ProviderLocation -ComputerName $SiteServer
        foreach ($SiteCodeObject in $SiteCodeObjects) {
            if ($SiteCodeObject.ProviderForLocalSite -eq $true) {
                $SiteCode = $SiteCodeObject.SiteCode
                Write-Debug "SiteCode: $($SiteCode)"
            }
        }
    }
    catch [Exception] {
        Throw "Unable to determine SiteCode"
    }
    
    try {
        [System.Reflection.Assembly]::LoadFrom((Join-Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName "Microsoft.ConfigurationManagement.ApplicationManagement.dll")) | Out-Null
        [System.Reflection.Assembly]::LoadFrom((Join-Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName "Microsoft.ConfigurationManagement.ApplicationManagement.Extender.dll")) | Out-Null
        [System.Reflection.Assembly]::LoadFrom((Join-Path (Get-Item $env:SMS_ADMIN_UI_PATH).Parent.FullName "Microsoft.ConfigurationManagement.ApplicationManagement.MsiInstaller.dll")) | Out-Null
    }
    catch [Exception] {
        Throw "Unable to load assemblies"
    }
    
    try {
        if ($PSBoundParameters["Recurse"].IsPresent) {
            Write-Verbose "Recurse mode selected, retrieving all application objects from WMI"
            $Applications = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_ApplicationLatest -ComputerName $SiteServer
        }
        else {
            Write-Verbose "Specific application specified, retrieving object from WMI"
            $Applications = Get-WmiObject -Namespace "root\SMS\site_$($SiteCode)" -Class SMS_ApplicationLatest -ComputerName $SiteServer -Filter "LocalizedDisplayName like '$($ApplicationName)'"
        }
    }
    catch [Exception] {
        Throw "Unable to get applications"
    }
}
Process {
    
    try {
        $Applications | ForEach-Object {
            $Application = [wmi]$_.__PATH
            Write-Verbose "Deserializing SDMPackageXML property for application: '$($Application.LocalizedDisplayName)'"
            $ApplicationXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($Application.SDMPackageXML,$True)
            foreach ($DeploymentType in $ApplicationXML.DeploymentTypes) {
                if (($DeploymentType.Installer.Technology -like "MSI") -or ($DeploymentType.Installer.Technology -like "Script")) {
                    if (-not($DeploymentType.Installer.PostInstallBehavior -like "$($PostInstallBehavior)")) {
                        Write-Verbose "Set PostInstallBehavior setting to: '$($PostInstallBehavior)'"
                        if ($PSCmdlet.ShouldProcess("Application: $($Application.LocalizedDisplayName)", "PostInstallBehavior: $($PostInstallBehavior)")) {
                            $DeploymentType.Installer.PostInstallBehavior = "$($PostInstallBehavior)"
                                Write-Verbose "Serializing XML back to String"
                                $UpdatedXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeToString($ApplicationXML, $True)
                                $Application.SDMPackageXML = $UpdatedXML
                                Write-Verbose "Saving changes to WMI object"
                                $Application.Put() | Out-Null
                        }
                    }
                    else {
                        Write-Verbose "PostInstallBehavior is already set to '$($PostInstallBehavior)'"
                    }
                }
                else {
                    Write-Verbose "Unsupported DeploymentType technology detected: '$($DeploymentType.Installer.Technology)'"
                }
            }
        }
    }
    catch [Exception] {
        Throw "Unable to set PostInstallBehavior"
    }
}