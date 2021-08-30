














param(
    [Parameter(Mandatory = $false, Position = 0)]
    [ValidateSet("Release", "Debug")]
    [string] $BuildConfig,

    [Parameter(Mandatory = $false, Position = 1)]
    [ValidateSet("All", "Latest", "Stack", "NetCore", "ServiceManagement", "AzureStorage")]
    [string] $Scope
)


function New-ModulePsm1 {
    [CmdletBinding()]
    param(
        [string]$ModulePath,
        [string]$TemplatePath,
        [switch]$IsRMModule,
        [switch]$IsNetcore
    )

    PROCESS {
        $manifestDir = Get-Item -Path $ModulePath
        $moduleName = $manifestDir.Name + ".psd1"
        $manifestPath = Join-Path -Path $ModulePath -ChildPath $moduleName
        $file = Get-Item $manifestPath
        Import-LocalizedData -BindingVariable ModuleMetadata -BaseDirectory $file.DirectoryName -FileName $file.Name

        
        if ($ModuleMetadata.RootModule) {
            Write-Host "root modules exists, skipping..."
            return
        }

        
        $templateOutputPath = $manifestPath -replace ".psd1", ".psm1"
        [string]$importedModules
        if ($ModuleMetadata.RequiredModules -ne $null) {
            foreach ($mod in $ModuleMetadata.RequiredModules) {
                if ($mod["ModuleVersion"]) {
                    $importedModules += New-MinimumVersionEntry -ModuleName $mod["ModuleName"] -MinimumVersion $mod["ModuleVersion"]
                } elseif ($mod["RequiredVersion"]) {
                    $importedModules += "Import-Module " + $mod["ModuleName"] + " -RequiredVersion " + $mod["RequiredVersion"] + " -Global`r`n"
                }
            }
        }

        
        if ($ModuleMetadata.NestedModules -ne $null) {
            foreach ($dll in $ModuleMetadata.NestedModules) {
                $importedModules += "Import-Module (Join-Path -Path `$PSScriptRoot -ChildPath " + $dll.Substring(2) + ")`r`n"
            }
        }

        
        $template = Get-Content -Path $TemplatePath
        $template = $template -replace "%MODULE-NAME%", $file.BaseName
        $template = $template -replace "%DATE%", [string](Get-Date)
        $template = $template -replace "%IMPORTED-DEPENDENCIES%", $importedModules

        
        if ($IsNetcore)
        {
            $template = $template -replace "%AZORAZURERM%", "AzureRM"
            $template = $template -replace "%ISAZMODULE%", "`$true"
        }
        else
        {
            $template = $template -replace "%AZORAZURERM%", "`Az"
            $template = $template -replace "%ISAZMODULE%", "`$false"
        }

        
        $contructedCommands = Find-DefaultResourceGroupCmdlets -IsRMModule:$IsRMModule -ModuleMetadata $ModuleMetadata -ModulePath $ModulePath
        $template = $template -replace "%DEFAULTRGCOMMANDS%", $contructedCommands

        Write-Host "Writing psm1 manifest to $templateOutputPath"
        $template | Out-File -FilePath $templateOutputPath -Force
        $file = Get-Item -Path $templateOutputPath
    }
}


function Get-Cmdlets {
    [CmdletBinding()]
    param(
        [Hashtable]$ModuleMetadata,
        [string]$ModulePath
    )
    $nestedModules = $ModuleMetadata.NestedModules
    $cmdlets = @()
    foreach ($module in $nestedModules) {
        $dllPath = Join-Path -Path $ModulePath -ChildPath $module
        $Assembly = [Reflection.Assembly]::LoadFrom($dllPath)
        $dllCmdlets = $Assembly.GetTypes() | Where-Object {$_.CustomAttributes.AttributeType.Name -contains "CmdletAttribute"}
        $cmdlets += $dllCmdlets
    }
    return $cmdlets
}


function Find-DefaultResourceGroupCmdlets {
    [CmdletBinding()]
    param(
        [Hashtable]$ModuleMetadata,
        [string]$ModulePath,
        [switch]$IsRMModule
    )
    PROCESS {
        $contructedCommands = "@("
        if ($IsRMModule) {
            $AllCmdlets = Get-Cmdlets -ModuleMetadata $ModuleMetadata -ModulePath $ModulePath
            $FilteredCommands = $AllCmdlets | Where-Object {Test-CmdletRequiredParameter -Cmdlet $_ -Parameter "ResourceGroupName"}
            foreach ($command in $FilteredCommands) {
                $contructedCommands += "'" + $command.GetCustomAttributes("System.Management.Automation.CmdletAttribute").VerbName + "-" + $command.GetCustomAttributes("System.Management.Automation.CmdletAttribute").NounName + ":ResourceGroupName" + "',"
            }
            $contructedCommands = $contructedCommands -replace ",$", ""
        }
        $contructedCommands += ")"
        return $contructedCommands
    }
}


function Test-CmdletRequiredParameter {
    [CmdletBinding()]
    param(
        [Object]$Cmdlet,
        [string]$Parameter
    )

    PROCESS {
        $rgParameter = $Cmdlet.GetProperties() | Where-Object {$_.Name -eq $Parameter}
        if ($rgParameter -ne $null) {
            $parameterAttributes = $rgParameter.CustomAttributes | Where-Object {$_.AttributeType.Name -eq "ParameterAttribute"}
            foreach ($attr in $parameterAttributes) {
                $hasParameterSet = $attr.NamedArguments | Where-Object {$_.MemberName -eq "ParameterSetName"}
                $MandatoryParam = $attr.NamedArguments | Where-Object {$_.MemberName -eq "Mandatory"}
                if (($hasParameterSet -ne $null) -or (!$MandatoryParam.TypedValue.Value)) {
                    return $false
                }
            }
            return $true
        }
        return $false
    }
}


function New-MinimumVersionEntry {
    [CmdletBinding()]
    param(
        [string]$ModuleName,
        [string]$MinimumVersion
    )

    PROCESS {
        return "`$module = Get-Module $ModuleName `
if (`$module -ne `$null -and `$module.Version.ToString().CompareTo(`"$MinimumVersion`") -lt 0) `
{ `
    Write-Error `"This module requires $ModuleName version $MinimumVersion. An earlier version of $ModuleName is imported in the current PowerShell session. Please open a new session before importing this module. This error could indicate that multiple incompatible versions of the Azure PowerShell cmdlets are installed on your system. Please see https://aka.ms/azps-version-error for troubleshooting information.`" -ErrorAction Stop `
} `
elseif (`$module -eq `$null) `
{ `
    Import-Module $ModuleName -MinimumVersion $MinimumVersion -Scope Global `
}`r`n"
    }
}


function Update-RMModule {
    [CmdletBinding()]
    param(
        $Modules
    )
    $Ignore = @('AzureRM.Profile', 'Azure.Storage')
    foreach ($module in $Modules) {
        
        
        if ( -not ($module.Name -in $Ignore)) {
            $modulePath = $module.FullName
            Write-Host "Updating $module module from $modulePath"
            New-ModulePsm1 -ModulePath $modulePath -TemplatePath $script:TemplateLocation -IsRMModule
            Write-Host "Updated $module module`n"
        }
    }
}


function Update-Azure {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [String]$Scope,

        [ValidateNotNullOrEmpty()]
        [ValidateSet('Debug', 'Release')]
        [String]$BuildConfig
    )

    if ($Scope -in $script:AzureRMScopes) {
        Write-Host "Updating profile module"
        New-ModulePsm1 -ModulePath "$script:AzureRMRoot\AzureRM.Profile" -TemplatePath $script:TemplateLocation -IsRMModule
        Write-Host "Updated profile module"
        Write-Host " "
    }

    if ($scope -in $script:StorageScopes) {
        $modulePath = "$script:AzurePackages\$buildConfig\Storage\Azure.Storage"
        Write-Host "Updating AzureStorage module from $modulePath"
        New-ModulePsm1 -ModulePath $modulePath -TemplatePath $script:TemplateLocation -IsRMModule:$false
        Write-Host " "
    }

    if ($scope -in $script:ServiceScopes) {
        $modulePath = "$script:AzurePackages\$buildConfig\ServiceManagement\Azure"
        Write-Host "Updating ServiceManagement(aka Azure) module from $modulePath"
        New-ModulePsm1 -ModulePath $modulePath -TemplatePath $script:TemplateLocation
        Write-Host " "
    }

    
    if ($Scope -in $script:AzureRMScopes) {
        $resourceManagerModules = Get-ChildItem -Path $script:AzureRMRoot -Directory
        Write-Host "Updating Azure modules"
        Update-RMModule -Modules $resourceManagerModules
        Write-Host " "
    }

    
    if ($Scope -in $script:AzureRMScopes) {
        $modulePath = "$PSScriptRoot\AzureRM"
        Write-Host "Updating AzureRM module from $modulePath"
        New-ModulePsm1 -ModulePath $modulePath -TemplatePath $script:TemplateLocation
        Write-Host " "
    }
}


function Update-Stack {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Debug', 'Release')]
        [String]$BuildConfig
    )

    Write-Host "Updating profile module for stack"
    New-ModulePsm1 -ModulePath "$script:StackRMRoot\AzureRM.Profile" -TemplatePath $script:TemplateLocation -IsRMModule
    Write-Host "Updated profile module"
    Write-Host " "

    $modulePath = "$script:StackPackages\$buildConfig\Storage\Azure.Storage"
    Write-Host "Updating AzureStorage module from $modulePath"
    New-ModulePsm1 -ModulePath $modulePath -TemplatePath $script:TemplateLocation -IsRMModule:$false
    Write-Host " "

    $StackRMModules = Get-ChildItem -Path $script:StackRMRoot -Directory
    Write-Host "Updating stack modules"
    Update-RMModule -Modules $StackRMModules
    Write-Host " "

    $modulePath = "$script:StackProjects\AzureRM"
    Write-Host "Updating AzureRM module from $modulePath"
    New-ModulePsm1 -ModulePath $modulePath -TemplatePath $script:TemplateLocation
    Write-Host " "

    $modulePath = "$script:StackProjects\AzureStack"
    Write-Host "Updating AzureStack module from $modulePath"
    New-ModulePsm1 -ModulePath $modulePath -TemplatePath $script:TemplateLocation
    Write-Host " "
}


function Update-Netcore {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Debug', 'Release')]
        [String]$BuildConfig
    )

    $AzureRMModules = Get-ChildItem -Path $script:AzureRMRoot -Directory

    
    Write-Host "Updating Accounts module"
    New-ModulePsm1 -ModulePath "$script:AzureRMRoot\Az.Accounts" -TemplatePath $script:TemplateLocation -IsRMModule -IsNetcore
    Write-Host "Updated Accounts module"

    $env:PSModulePath += "$([IO.Path]::PathSeparator)$script:AzureRMRoot\Az.Accounts";

    foreach ($module in $AzureRMModules) {
        if (($module.Name -ne "Az.Accounts")) {
            $modulePath = $module.FullName
            Write-Host "Updating $module module from $modulePath"
            New-ModulePsm1 -ModulePath $modulePath -TemplatePath $script:TemplateLocation -IsRMModule -IsNetcore
            Write-Host "Updated $module module"
        }
    }

    $modulePath = "$PSScriptRoot\Az"
    Write-Host "Updating Netcore module from $modulePath"
    New-ModulePsm1 -ModulePath $modulePath -TemplatePath $script:TemplateLocation -IsNetcore
    Write-Host "Updated Netcore module"
}




$script:TemplateLocation = "$PSScriptRoot\AzureRM.Example.psm1"


$script:NetCoreScopes = @('NetCore')
$script:AzureScopes = @('All', 'Latest', 'ServiceManagement', 'AzureStorage')
$script:StackScopes = @('All', 'Stack')


$script:AzureRMScopes = @('All', 'Latest')
$script:StorageScopes = @('All', 'Latest', 'AzureStorage')
$script:ServiceScopes = @('All', 'Latest', 'ServiceManagement')


$script:AzurePackages = "$PSScriptRoot\..\artifacts"
$script:StackPackages = "$PSScriptRoot\..\src\Stack"
$script:StackProjects = "$PSScriptRoot\..\src\StackAdmin"


$script:AzureRMRoot = "$script:AzurePackages\$buildConfig"
$script:StackRMRoot = "$script:StackPackages\$buildConfig"



Write-Host "Updating $Scope package (and its dependencies)"

if ($Scope -in $NetCoreScopes) {
    Update-Netcore -BuildConfig $BuildConfig
}

if ($Scope -in $AzureScopes) {
    Update-Azure -Scope $Scope -BuildConfig $BuildConfig
}

if ($Scope -in $StackScopes) {
    Update-Stack -BuildConfig $BuildConfig
}

