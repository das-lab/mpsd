
    
    
    
    
    
    
    
    
    
    


param (
    [Parameter(Mandatory = $true)]
    [string] $spPassword,
    [string] $modulesDir = '',
    [bool] $createPackages = $true,
    [bool] $uploadPackages = $true,
    [bool] $processRunbooks = $true,
    [bool] $waitForResults = $true
)

. "$PSScriptRoot\Management\PackageGenerator.ps1"
. "$PSScriptRoot\Management\ModuleUploader.ps1"
. "$PSScriptRoot\Management\RunbookProcessor.ps1"

try {
    $srcPath = "$PSScriptRoot\..\..\src"
    $projectList = @('Accounts', 'Compute', 'Resources', 'Storage', 'Websites', 'Network', 'Sql')
    $testResourcesDir = "$PSScriptRoot\TestResources"
    $packagingDir = "$PSScriptRoot\Package"
    $helperModuleName = 'Smoke.Helper'
    $testModuleName = 'Smoke.Tests'
    $runbooksPath = "$PSScriptRoot\Runbooks"
    $success = $false

    $automation = @{
        ResourceGroupName = 'azposjhautomation';
        AccountName = 'azposhautomation'
    }

    $storage = @{
        ResourceGroupName = 'transit2automation';
        AccountName = 'transit2automation';
        ContainerName = 'testsmodule'
    }

    $template = @{
        SubscriptionName = 'Azure SDK Powershell Test';
        AutomationConnectionName = 'AzureRunAsConnection';
        Path = "$testResourcesDir\RunbookTemplate.ps1"
    }

    $signedModuleList = @('Az.Automation', 'Az.Compute','Az.Resources', 'Az.Storage', 'Az.Websites', 'Az.Network', 'Az.Sql')
    
    
    $signedModules = @{
        Accounts = @('Az.Accounts');
    }
    
    $signedModules.Other = $signedModuleList | Where-Object { ($signedModules.Accounts) -inotcontains $_ }

    Import-Module Az.Accounts
    Import-Module Az.Storage
    Import-Module Az.Automation

    
    
    $password = ConvertTo-SecureString -String $spPassword -AsPlainText -Force
    $creds = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList '512d9f44-dacc-4a72-8bab-3ff8362d14b7', $password
    Login-AzAccount -Credential $creds -ServicePrincipal -TenantId 72f988bf-86f1-41af-91ab-2d7cd011db47 -Subscription 'Azure SDK Infrastructure' -ErrorAction Stop

    if($createPackages) {
        Write-Verbose '=== Create Packages ========================'
        Create-HelperModule `
            -moduleDir $testResourcesDir `
            -moduleName $helperModuleName `
            -archiveDir $packagingDir
        Create-SignedModules `
            -signedModules $signedModules `
            -modulesDir $modulesDir `
            -archiveDir $packagingDir
        Create-SmokeTestModule `
            -srcPath $srcPath `
            -archiveDir $packagingDir `
            -moduleName $testModuleName `
            -projectList $projectList
        Write-Verbose '============================================='
    }

    if($uploadPackages) {
        Write-Verbose '=== Upload Modules ========================'
        Remove-HelperModulesFromAutomationAccount `
            -automation $automation `
            -moduleNames $helperModuleName, $testModuleName
        Upload-Modules `
            -automation $automation `
            -storage $storage `
            -signedModules $signedModules `
            -archiveDir $packagingDir
            Write-Verbose '============================================='
    }

    if($processRunbooks) {
        Write-Verbose '=== Process Runbooks ========================'
        Create-Runbooks `
            -template $template `
            -srcPath $srcPath `
            -projectList $projectList `
            -outputPath $runbooksPath
        $jobs = Start-Runbooks `
            -automation $automation `
            -runbooksPath $runbooksPath
        if ($waitForResults) {
            $success = Wait-RunbookResults `
                -automation $automation `
                -jobs $jobs
        }
        Write-Verbose '============================================='
    }

    Write-Verbose '=== All Done ========================'
    
    if (-not $success) {
        exit 1
    }
} catch {
    Write-Host "Something went wrong: $_" -ForegroundColor Red
    $_.ScriptStackTrace.Split([Environment]::NewLine) | Where-Object { $_.Length -gt 0 } | ForEach-Object { Write-Verbose "`t$_" }
    exit 1
}

exit 0