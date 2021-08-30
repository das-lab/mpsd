function Validate-ModuleCommandAlreadyAvailable
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [PSModuleInfo]
        $CurrentModuleInfo,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $InstallLocation,

        [Parameter()]
        [Switch]
        $AllowClobber,

        [Parameter()]
        [Switch]
        $IsUpdateOperation
    )

    
    
    
    
    
    if($CurrentModuleInfo.ExportedCommands.Keys.Count -and
       -not $AllowClobber -and
       -not $IsUpdateOperation)
    {
        
        if(Test-ModuleSxSVersionSupport)
        {
            $InstallLocation = Microsoft.PowerShell.Management\Split-Path -Path $InstallLocation
        }

        $InstalledModuleInfo = Test-ModuleInstalled -Name $CurrentModuleInfo.Name
        if(-not $InstalledModuleInfo -or -not $InstalledModuleInfo.ModuleBase.StartsWith($InstallLocation, [System.StringComparison]::OrdinalIgnoreCase))
        {
            
            $CommandNames = $CurrentModuleInfo.ExportedCommands.Values.Name

            
            $CommandNameHash = @{}
            $CommandNames | % { $CommandNameHash[$_] = 1 }
            
            $AvailableCommands = Microsoft.PowerShell.Core\Get-Command  `
                                                                      -ErrorAction Ignore `
                                                                      -WarningAction SilentlyContinue |
                                    Microsoft.PowerShell.Core\Where-Object { ($CommandNameHash.ContainsKey($_.Name)) -and
                                                                             ($_.ModuleName -ne $script:PSModuleProviderName) -and
                                                                             ($_.ModuleName -ne 'PSModule') -and
                                                                             ($_.ModuleName -ne $CurrentModuleInfo.Name) }
            if($AvailableCommands)
            {
                $AvailableCommandsList = ($AvailableCommands.Name | Microsoft.PowerShell.Utility\Select-Object -Unique -ErrorAction Ignore) -join ","
                $message = $LocalizedData.ModuleCommandAlreadyAvailable -f ($AvailableCommandsList, $CurrentModuleInfo.Name)
                ThrowError -ExceptionName 'System.InvalidOperationException' `
                           -ExceptionMessage $message `
                           -ErrorId 'CommandAlreadyAvailable' `
                           -CallerPSCmdlet $PSCmdlet `
                           -ErrorCategory InvalidOperation

                return $false
            }
        }
    }

    return $true
}