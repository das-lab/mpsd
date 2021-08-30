
















param(
    [ValidateNotNull()]
    [String[]]$Modules = @(
        "Azs.AzureBridge.Admin",
        "Azs.Backup.Admin",
        "Azs.Commerce.Admin",
        "Azs.Compute.Admin",
        "Azs.Fabric.Admin",
        "Azs.Gallery.Admin",
        "Azs.InfrastructureInsights.Admin",
        "Azs.KeyVault.Admin",
        "Azs.Network.Admin",
        "Azs.Storage.Admin",
        "Azs.Subscriptions.Admin",
        "Azs.Subscriptions",
        "Azs.Update.Admin"
    ),

    [ValidateNotNull()]
    [String[]]$Skipped = @()
)

Import-Module AzureRM.Profile -Force

$Scheduled = $Modules | Where-Object { !($_ -in $Skipped) }


foreach ($module in $Scheduled) {
    if ( !($module -in $Modules) ) {
        throw "The module '$module' is not in All."
    }
}


function Update-Help {
    [CmdletBinding()]
    param(
        [string]$BuildConfig
    )

    
    $rootFolder = "$($PSSCriptRoot)\..\src\StackAdmin\"

    
    [int]$Failures = 0
    $adminModules = Get-ChildItem -Path $rootFolder -Directory -Filter Azs.*
    foreach ($module in $adminModules) {
        $moduleDir = $module.FullName + "\Module"
        $module = $module.FullName | Split-Path -Leaf
        if ( $module -in $Scheduled ) {
            Push-Location $moduleDir | Out-Null
            try {
                Import-Module ".\$module" -Force | Out-Null
                if (Test-Path "..\Help") {
                    Write-Host "Removing old help files"
                    Remove-Item -Path "..\Help" -Force -Recurse
                }

                Write-Host "creating $module..."
                New-MarkdownHelp -Module $module -AlphabeticParamsOrder -OutputFolder ..\Help -WithModulePage
                Update-MarkdownHelpModule -Path ..\Help -RefreshModulePage -AlphabeticParamsOrder
                Write-Host "done..."
            } catch {
                $Failures += 1
                Write-Error "$($_.Exception)"
                break
            } finally {
                Pop-Location | Out-Null
            }
        }
    }
    return $Failures
}

write-Host "Updating markdown modules..."
exit (Update-Help -BuildConfig $BuildConfig)
