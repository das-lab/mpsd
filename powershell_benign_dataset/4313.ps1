



function SuiteSetup {
    Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue
    Import-Module "$PSScriptRoot\Asserts.psm1" -WarningAction SilentlyContinue

    $script:PSGetLocalAppDataPath = Get-PSGetLocalAppDataPath
    $script:TempPath = Get-TempPath

    
    Install-NuGetBinaries

    $psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
    Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $psgetModuleInfo.ModuleBase

    $script:moduleSourcesFilePath= Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml"
    $script:moduleSourcesBackupFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml_$(get-random)_backup"

    if(Test-Path $script:moduleSourcesFilePath)
    {
        Rename-Item $script:moduleSourcesFilePath $script:moduleSourcesBackupFilePath -Force
    }

    GetAndSet-PSGetTestGalleryDetails -IsScriptSuite -SetPSGallery

    Get-InstalledScript -Name Fabrikam-ServerScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
    Get-InstalledScript -Name Fabrikam-ClientScript -ErrorAction SilentlyContinue | Uninstall-Script -Force

    $script:AddedAllUsersInstallPath    = Set-PATHVariableForScriptsInstallLocation -Scope AllUsers
    $script:AddedCurrentUserInstallPath = Set-PATHVariableForScriptsInstallLocation -Scope CurrentUser
}

function SuiteCleanup {
    if(Test-Path $script:moduleSourcesBackupFilePath)
    {
        Move-Item $script:moduleSourcesBackupFilePath $script:moduleSourcesFilePath -Force
    }
    else
    {
        RemoveItem $script:moduleSourcesFilePath
    }

    
    $null = Import-PackageProvider -Name PowerShellGet -Force

    if($script:AddedAllUsersInstallPath)
    {
        Reset-PATHVariableForScriptsInstallLocation -Scope AllUsers
    }

    if($script:AddedCurrentUserInstallPath)
    {
        Reset-PATHVariableForScriptsInstallLocation -Scope CurrentUser
    }
}

Describe PowerShell.PSGet.UninstallScriptTests -Tags 'BVT','InnerLoop' {

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    AfterEach {
        Get-InstalledScript -Name Fabrikam-ServerScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
        Get-InstalledScript -Name Fabrikam-ClientScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
    }

    It ValidateGetInstalledScriptAndUninstallScriptCmdletsWithMinimumVersion {

        $ScriptName = 'Fabrikam-ServerScript'
        $version = "2.0"

        try
        {
            Install-Script -Name $ScriptName -RequiredVersion $version -Force
            $script = Get-InstalledScript -Name $ScriptName -MinimumVersion 1.0
            AssertEquals $script.Name $ScriptName "Get-InstalledScript is not working properly, $script"
            AssertEquals $script.Version $Version "Get-InstalledScript is not working properly, $script"
        }
        finally
        {
            PowerShellGet\Uninstall-Script -Name $ScriptName -MinimumVersion $Version
            $script = Get-InstalledScript -Name $ScriptName -ErrorAction SilentlyContinue
            AssertNull $script "Script uninstallation is not working properly, $script"
        }
    }

    It ValidateGetInstalledScriptAndUninstallScriptCmdletWithMinMaxRange {

        $ScriptName = 'Fabrikam-ServerScript'
        $version = "2.0"

        try
        {
            Install-Script -Name $ScriptName -RequiredVersion $version -Force
            $script = Get-InstalledScript -Name $ScriptName -MinimumVersion $Version -MaximumVersion $Version
            AssertEquals $script.Name $ScriptName "Get-InstalledScript is not working properly, $script"
            AssertEquals $script.Version $Version "Get-InstalledScript is not working properly, $script"
        }
        finally
        {
            PowerShellGet\Uninstall-Script -Name $ScriptName -MinimumVersion $Version -MaximumVersion $Version
            $script = Get-InstalledScript -Name $ScriptName -ErrorAction SilentlyContinue
            AssertNull $script "Script uninstallation is not working properly, $script"
        }
    }

    It ValidateGetInstalledScriptAndUninstallScriptCmdletWithRequiredVersion {

        $ScriptName = 'Fabrikam-ServerScript'
        $version = "2.0"

        try
        {
            Install-Script -Name $ScriptName -RequiredVersion $version -Force
            $script = Get-InstalledScript -Name $ScriptName -RequiredVersion $Version
            AssertEquals $script.Name $ScriptName "Get-InstalledScript is not working properly, $script"
            AssertEquals $script.Version $Version "Get-InstalledScript is not working properly, $script"
        }
        finally
        {
            PowerShellGet\Uninstall-Script -Name $ScriptName -RequiredVersion $Version
            $script = Get-InstalledScript -Name $ScriptName -ErrorAction SilentlyContinue
            AssertNull $script "Script uninstallation is not working properly, $script"
        }
    }

    It ValidateGetInstalledScriptAndUninstallScriptCmdletWithMiximumVersion {

        $ScriptName = 'Fabrikam-ServerScript'
        $version = "2.0"

        try
        {
            Install-Script -Name $ScriptName -RequiredVersion $version -Force
            $script = Get-InstalledScript -Name $ScriptName -MaximumVersion $Version
            AssertEquals $script.Name $ScriptName "Get-InstalledScript is not working properly, $script"
            AssertEquals $script.Version $Version "Get-InstalledScript is not working properly, $script"
        }
        finally
        {
            PowerShellGet\Uninstall-Script -Name $ScriptName -RequiredVersion $Version
            $script = Get-InstalledScript -Name $ScriptName -ErrorAction SilentlyContinue
            AssertNull $script "Script uninstallation is not working properly, $script"
        }
    }

    
    
    
    
    
    
    It "UninstallScriptWithWhatIf" {
        $outputPath = $script:TempPath
        $guid =  [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1
        $content = $null

        try
        {  
	        Find-Script Fabrikam-ServerScript | Install-Script          
            $result = ExecuteCommand $runspace 'PowerShellGet\Uninstall-Script Fabrikam-ServerScript -whatif'
        }
        finally
        {
            $fileName = "WriteLine-0.txt"
            $path = join-path $outputFilePath $fileName
            if(Test-Path $path)
            {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $itemInfo = Find-Script Fabrikam-ServerScript -Repository PSGallery
        $uninstallShouldProcessMessage = $script:LocalizedData.InstallScriptwhatIfMessage -f ($itemInfo.Name, $itemInfo.Version)
        Assert ($content -and ($content -match $uninstallShouldProcessMessage)) "Uninstall script whatif message is missing, Expected:$uninstallShouldProcessMessage, Actual:$content"

        $res = Get-InstalledScript Fabrikam-ServerScript
        Assert ($res) "Uninstall-Script should not uninstall the script with -WhatIf option"
    } `
    -Skip:$(($PSEdition -eq 'Core') -or ($PSCulture -ne 'en-US') -or ([System.Environment]::OSVersion.Version -lt '6.2.9200.0'))

    
    
    
    
    
    
    It "UninstallScriptWithConfirmAndNoToPrompt" {
        $outputPath = $script:TempPath
        $guid =  [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        
        $Global:proxy.UI.ChoiceToMake=2
        $content = $null

        try
        {
	        Install-Script Fabrikam-ServerScript -Repository PSGallery -force
            $result = ExecuteCommand $runspace 'PowerShellGet\Uninstall-Script Fabrikam-ServerScript -Confirm'
        }
        finally
        {
            $fileName = "PromptForChoice-0.txt"
            $path = join-path $outputFilePath $fileName
            if(Test-Path $path)
            {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }
        
        $itemInfo = Find-Script Fabrikam-ServerScript -Repository PSGallery

        $UninstallShouldProcessMessage = $script:LocalizedData.InstallScriptwhatIfMessage -f ($itemInfo.Name, $itemInfo.Version)
        Assert ($content -and ($content -match $UninstallShouldProcessMessage)) "Uninstall script confirm prompt is not working, Expected:$UninstallShouldProcessMessage, Actual:$content"

        $res = Get-InstalledScript Fabrikam-ServerScript
        Assert ($res) "Uninstall-Script should not uninstall the script if confirm is not accepted"
    } `
    -Skip:$(($PSEdition -eq 'Core') -or ($PSCulture -ne 'en-US') -or ([System.Environment]::OSVersion.Version -lt '6.2.9200.0'))

    
    
    
    
    
    
    It "UninstallScriptWithConfirmAndYesToPrompt" {
        $outputPath = $script:TempPath
        $guid =  [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        
        $Global:proxy.UI.ChoiceToMake=0
        $content = $null

        try
        {
            Find-Script Fabrikam-ServerScript | Install-Script
            $result = ExecuteCommand $runspace 'PowerShellGet\Uninstall-Script Fabrikam-ServerScript -Confirm'
        }
        finally
        {
            $fileName = "PromptForChoice-0.txt"
            $path = join-path $outputFilePath $fileName
            if(Test-Path $path)
            {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $itemInfo = Find-Script Fabrikam-ServerScript -Repository PSGallery

        $UninstallShouldProcessMessage = $script:LocalizedData.InstallScriptwhatIfMessage -f ($itemInfo.Name, $itemInfo.Version)
        Assert ($content -and ($content -match $UninstallShouldProcessMessage)) "Uninstall script confirm prompt is not working, Expected:$UninstallShouldProcessMessage, Actual:$content"

        $res = Get-InstalledScript Fabrikam-ServerScript -ErrorAction SilentlyContinue
        AssertNull $res "Uninstall-Script should uninstall a script if Confirm is not accepted"
    } `
    -Skip:$(($PSEdition -eq 'Core') -or ($PSCulture -ne 'en-US') -or ([System.Environment]::OSVersion.Version -lt '6.2.9200.0'))
}

Describe PowerShell.PSGet.UninstallScriptTests.ErrorCases -Tags 'P1','InnerLoop','RI' {

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    
    It ValidateUninstallScriptWithMultiNamesAndRequiredVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {PowerShellGet\Uninstall-Script -Name Fabrikam-ClientScript,Fabrikam-ServerScript -RequiredVersion 3.0 } `
                                    -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Uninstall-Script"
    }

    It ValidateUninstallScriptWithMultiNamesAndMinVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {PowerShellGet\Uninstall-Script -Name Fabrikam-ClientScript,Fabrikam-ServerScript -MinimumVersion 3.0 } `
                                    -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Uninstall-Script"
    }

    It ValidateUninstallScriptWithMultiNamesAndMaxVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {PowerShellGet\Uninstall-Script -Name Fabrikam-ClientScript,Fabrikam-ServerScript -MaximumVersion 3.0 } `
                                    -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Uninstall-Script"
    }

    It ValidateUninstallScriptWithSingleWildcardName {
        AssertFullyQualifiedErrorIdEquals -scriptblock {PowerShellGet\Uninstall-Script -Name Fabrikam-Client*ipt} `
                                    -expectedFullyQualifiedErrorId "NameShouldNotContainWildcardCharacters,Uninstall-Script"
    }

    It ValidateUninstallScriptWithSingleNameRequiredandMinVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {PowerShellGet\Uninstall-Script -Name Fabrikam-ClientScript -RequiredVersion 3.0 -MinimumVersion 1.0 } `
                                    -expectedFullyQualifiedErrorId "VersionRangeAndRequiredVersionCannotBeSpecifiedTogether,Uninstall-Script"
    }

    It ValidateUninstallScriptWithSingleNameRequiredandMaxVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {PowerShellGet\Uninstall-Script -Name Fabrikam-ClientScript -RequiredVersion 3.0 -MaximumVersion 1.0 } `
                                    -expectedFullyQualifiedErrorId "VersionRangeAndRequiredVersionCannotBeSpecifiedTogether,Uninstall-Script"
    }

    It ValidateUninstallScriptWithSingleNameInvalidMinMaxRange {
        AssertFullyQualifiedErrorIdEquals -scriptblock {PowerShellGet\Uninstall-Script -Name Fabrikam-ClientScript -MinimumVersion 3.0 -MaximumVersion 1.0 } `
                                    -expectedFullyQualifiedErrorId "MinimumVersionIsGreaterThanMaximumVersion,Uninstall-Script"
    }
}
