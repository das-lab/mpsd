





if($IsMacOS) {
    return
}

function SuiteSetup {
    Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue
    Import-Module "$PSScriptRoot\Asserts.psm1" -WarningAction SilentlyContinue

    $script:ProgramFilesModulesPath = Get-AllUsersModulesPath
    $script:MyDocumentsModulesPath = Get-CurrentUserModulesPath
    $script:PSGetLocalAppDataPath = Get-PSGetLocalAppDataPath
    $script:TempPath = Get-TempPath
    $script:CurrentPSGetFormatVersion = "1.0"
    $script:OutdatedNuGetExeVersion = [System.Version]"2.8.60717.93"

    
    Install-NuGetBinaries

    $script:psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
    Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $script:psgetModuleInfo.ModuleBase

    $script:PSGalleryRepoPath = Join-Path -Path $script:TempPath -ChildPath 'PSGalleryRepo'
    RemoveItem $script:PSGalleryRepoPath
    $null = New-Item -Path $script:PSGalleryRepoPath -ItemType Directory -Force

    $script:moduleSourcesFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml"
    $script:moduleSourcesBackupFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml_$(get-random)_backup"
    if(Test-Path $script:moduleSourcesFilePath)
    {
        Rename-Item $script:moduleSourcesFilePath $script:moduleSourcesBackupFilePath -Force
    }

    Set-PSGallerySourceLocation -Location $script:PSGalleryRepoPath -PublishLocation $script:PSGalleryRepoPath

    $modSource = Get-PSRepository -Name "PSGallery"
    AssertEquals $modSource.SourceLocation $script:PSGalleryRepoPath "Test repository's SourceLocation is not set properly"
    AssertEquals $modSource.PublishLocation $script:PSGalleryRepoPath "Test repository's PublishLocation is not set properly"

    $script:ApiKey="TestPSGalleryApiKey"

    
    $script:TempModulesPath = Join-Path -Path $script:TempPath -ChildPath "PSGet_$(Get-Random)"
    $null = New-Item -Path $script:TempModulesPath -ItemType Directory -Force

    $script:PublishModuleName = "ContosoPublishModule"
    $script:PublishModuleBase = Join-Path $script:TempModulesPath $script:PublishModuleName
    $null = New-Item -Path $script:PublishModuleBase -ItemType Directory -Force
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

    RemoveItem $script:PSGalleryRepoPath
    RemoveItem $script:TempModulesPath
}

Describe PowerShell.PSGet.PublishModuleTests -Tags 'BVT','InnerLoop' {
    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    BeforeEach {
        Set-Content (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psm1") -Value "function Get-$script:PublishModuleName { Get-Date }"

        $version = "1.0"
        $script:PublishModuleBase = Join-Path $script:TempModulesPath $script:PublishModuleName
        New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"

        
        Copy-Item $script:PublishModuleBase $script:ProgramFilesModulesPath -Recurse -Force
    }

    AfterEach {
        RemoveItem "$script:PSGalleryRepoPath\*"
        RemoveItem "$script:ProgramFilesModulesPath\$script:PublishModuleName\*"
        RemoveItem "$script:ProgramFilesModulesPath\$script:PublishModuleName"
        RemoveItem "$script:PublishModuleBase\*"
    }

    
    
    
    
    
    
    It "PublishModuleWithName" {
        $version = "1.0"
        $semanticVersion = '1.0.0'
        New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"

        
        Copy-Item $script:PublishModuleBase $script:ProgramFilesModulesPath -Recurse -Force

        Publish-Module -Name $script:PublishModuleName -ReleaseNotes "$script:PublishModuleName release notes" -Tags PSGet -LicenseUri "https://$script:PublishModuleName.com/license" -ProjectUri "https://$script:PublishModuleName.com" -WarningAction SilentlyContinue

        $psgetItemInfo = Find-Module $script:PublishModuleName -RequiredVersion $version
        
        Assert (($psgetItemInfo.Name -eq $script:PublishModuleName) -and (($psgetItemInfo.Version.ToString() -eq $version) -or ($psgetItemInfo.Version.ToString() -eq $semanticVersion))) "Publish-Module should publish a module with valid module name, $($psgetItemInfo.Name)"
    }

    
    
    
    
    
    
    It "PublishModuleWithNameForSxSVersion" {
        $version = "2.0.0.0"
        $semanticVersion = '2.0.0'
        RemoveItem "$script:PublishModuleBase\*"
        RemoveItem "$script:ProgramFilesModulesPath\$script:PublishModuleName\*"

        $moduleBaseWithVersion = (Join-Path -Path $script:PublishModuleBase -ChildPath "$version")
        $null = New-Item -Path $moduleBaseWithVersion -ItemType Directory -Force
        Set-Content (Join-Path $moduleBaseWithVersion "$script:PublishModuleName.psm1") -Value "function Get-$script:PublishModuleName { Get-Date }"

        New-ModuleManifest -Path (Join-Path $moduleBaseWithVersion "$script:PublishModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"

        
        Copy-Item $script:PublishModuleBase $script:ProgramFilesModulesPath -Recurse -Force

        Publish-Module -Name $script:PublishModuleName -NuGetApiKey $script:ApiKey -ReleaseNotes "$script:PublishModuleName release notes" -Tags PSGet -LicenseUri "https://$script:PublishModuleName.com/license" -ProjectUri "https://$script:PublishModuleName.com" -WarningAction SilentlyContinue

        $psgetItemInfo = Find-Module $script:PublishModuleName -RequiredVersion $version
        Assert (($psgetItemInfo.Name -eq $script:PublishModuleName) -and (($psgetItemInfo.Version.ToString() -eq $version) -or ($psgetItemInfo.Version.ToString() -eq $semanticVersion))) "Publish-Module should publish a module with valid module name, $($psgetItemInfo.Name)"
    } `
    -Skip:$(-not (Test-ModuleSxSVersionSupport))

    
    
    
    
    
    
    It PublishModuleWithNameRequiredVersionForSxSVersion {
        $version = "2.0.0"
        $moduleBaseWithVersion = (Join-Path -Path $script:PublishModuleBase -ChildPath "$version")
        $null = New-Item -Path $moduleBaseWithVersion -ItemType Directory -Force
        Set-Content (Join-Path -Path $moduleBaseWithVersion -ChildPath "$script:PublishModuleName.psm1") -Value "function Get-$script:PublishModuleName { Get-Date }"

        New-ModuleManifest -Path (Join-Path -Path $moduleBaseWithVersion -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"

        
        Copy-Item $script:PublishModuleBase $script:ProgramFilesModulesPath -Recurse -Force

        Publish-Module -Name $script:PublishModuleName `
                       -RequiredVersion $version `
                       -NuGetApiKey $script:ApiKey `
                       -ReleaseNotes "$script:PublishModuleName release notes" `
                       -Tags 'PSGet' `
                       -LicenseUri "https://$script:PublishModuleName.com/license" `
                       -ProjectUri "https://$script:PublishModuleName.com" `
                       -WarningAction SilentlyContinue

        $psgetItemInfo = Find-Module $script:PublishModuleName -RequiredVersion $version
        Assert (($psgetItemInfo.Name -eq $script:PublishModuleName) -and ($psgetItemInfo.Version.ToString() -eq $version)) "Publish-Module should publish a module with valid module name, $($psgetItemInfo.Name)"
    } `
    -Skip:$(-not (Test-ModuleSxSVersionSupport))

    
    
    
    
    
    
    It "PublishModuleWithPath" {
        $version = "1.0"
        New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"
        Publish-Module -Path $script:PublishModuleBase -NuGetApiKey $script:ApiKey -ReleaseNotes "$script:PublishModuleName release notes" -Tags PSGet -LicenseUri "https://$script:PublishModuleName.com/license" -ProjectUri "https://$script:PublishModuleName.com" -WarningAction SilentlyContinue
        $psgetItemInfo = Find-Module $script:PublishModuleName -RequiredVersion $version
        Assert ($psgetItemInfo.Name -eq $script:PublishModuleName) "Publish-Module should publish a module with valid module path, $($psgetItemInfo.Name)"
    }

    
    
    
    
    
    
    It "PublishModuleLeavesOutHiddenFiles" {

        
        $version = "1.0"
        New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"
        New-Item -Type Directory -Path $script:PublishModuleBase -Name ".git"
        New-Item -Type File -Path $script:PublishModuleBase\.git\dummy
        New-Item -Type File -Path $script:PublishModuleBase -Name "normal"
        $hiddenDir = Get-Item $script:PublishModuleBase\.git -force
        $hiddenDir.Attributes = "hidden"

        
        Publish-Module -Path $script:PublishModuleBase -NuGetApiKey $script:ApiKey -ReleaseNotes "$script:PublishModuleName release notes" -Tags PSGet -LicenseUri "https://$script:PublishModuleName.com/license" -ProjectUri "https://$script:PublishModuleName.com" -WarningAction SilentlyContinue
        New-Item -type directory -path $script:PublishModuleBase -Name saved
        Save-Module $script:PublishModuleName -RequiredVersion $version -Path $script:PublishModuleBase\saved

        
        $contents = (dir -rec -force $script:PublishModuleBase | Out-String)
        $basedir = "$script:PublishModuleBase\saved\$script:PublishModuleName"
        if($PSVersionTable.PSVersion -gt '5.0.0') {
            $basedir = join-path $basedir "1.0.0"
        }

        Assert ((Test-Path $basedir\.git) -eq $false) ".git dir shouldn't be included ($contents)"
        Assert ((Test-Path $basedir\normal) -eq $true) "normal file should be included ($contents)"
    }

    
    
    
    
    
    
    It "PublishModuleWithRelativePath" {
        $version = "1.0"
        $moduleBase = $script:PublishModuleBase

        if($PSVersionTable.PSVersion -gt '5.0.0')
        {
            $moduleBase = (Join-Path -Path $script:PublishModuleBase -ChildPath "$version")
            $null = New-Item -ItemType Directory -Path $moduleBase -Force
        }

        New-ModuleManifest -Path (Join-Path -Path $moduleBase -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"
        $currentLocation = Get-Location
        try
        {
            Set-Location -Path $moduleBase
            Publish-Module -Path .\ -NuGetApiKey $script:ApiKey -ReleaseNotes "$script:PublishModuleName release notes" -Tags PSGet -LicenseUri "https://$script:PublishModuleName.com/license" -ProjectUri "https://$script:PublishModuleName.com" -WarningAction SilentlyContinue
            $psgetItemInfo = Find-Module $script:PublishModuleName -RequiredVersion $version
            Assert ($psgetItemInfo.Name -eq $script:PublishModuleName) "Publish-Module should publish a module with valid module relative path, $($psgetItemInfo.Name)"
        }
        finally
        {
            $currentLocation | Set-Location
        }
    }

    
    
    
    
    
    
    It "PublishModulePathWithoutVersion" {
        $version = "2.0"
        $Name = "TestModule_$(Get-Random)"

        
        $moduleBase = Join-Path -Path $script:TempModulesPath -ChildPath $Name
        $moduleBaseWithoutVersion = $moduleBase

        if($PSVersionTable.PSVersion -gt '5.0.0')
        {
            $moduleBase = Join-Path -Path $moduleBase -ChildPath $version
        }

        $null = New-Item -ItemType Directory -Path $moduleBase -Force

        New-ModuleManifest -Path (Join-Path -Path $moduleBase -ChildPath "$Name.psd1") -ModuleVersion $version -Description "$Name module"

        Publish-Module -Path $moduleBaseWithoutVersion -NuGetApiKey $script:ApiKey -WarningAction SilentlyContinue
        $psgetItemInfo = Find-Module $Name -RequiredVersion $version
        Assert ($psgetItemInfo.Name -eq $Name) "Publish-Module should publish a module path without version, $($psgetItemInfo.Name)"
    }

    
    
    
    
    
    
    It "PublishModuleWithAmbiguousPathWithoutVersion" {
        $version1 = "1.0"
        $version2 = "2.0"
        $moduleBase = $script:PublishModuleBase
        $moduleBaseWithoutVersion = $script:PublishModuleBase

        $moduleBase = Join-Path -Path $script:PublishModuleBase -ChildPath $version1
        $null = New-Item -ItemType Directory -Path $moduleBase -Force
        New-ModuleManifest -Path (Join-Path -Path $moduleBase -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion $version1 -Description "$script:PublishModuleName module"

        $moduleBase = Join-Path -Path $script:PublishModuleBase -ChildPath $version2
        $null = New-Item -ItemType Directory -Path $moduleBase -Force
        New-ModuleManifest -Path (Join-Path -Path $moduleBase -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion $version2 -Description "$script:PublishModuleName module"

        AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Module -Path $moduleBaseWithoutVersion -WarningAction SilentlyContinue}`
                                          -expectedFullyQualifiedErrorId 'AmbiguousModulePathToPublish,Publish-Module'
    } `
    -Skip:$(-not (Test-ModuleSxSVersionSupport))

    
    
    
    
    
    
    It PublishModuleWithPathForSxSVersion {
        $version = "2.0.0"

        $moduleBaseWithVersion = (Join-Path -Path $script:PublishModuleBase -ChildPath "$version")
        $null = New-Item -Path $moduleBaseWithVersion -ItemType Directory -Force
        Set-Content (Join-Path -Path $moduleBaseWithVersion -ChildPath "$script:PublishModuleName.psm1") -Value "function Get-$script:PublishModuleName { Get-Date }"

        New-ModuleManifest -Path (Join-Path -Path $moduleBaseWithVersion -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"

        Publish-Module -Path $moduleBaseWithVersion `
                       -NuGetApiKey $script:ApiKey `
                       -ReleaseNotes "$script:PublishModuleName release notes" `
                       -Tags 'PSGet' `
                       -LicenseUri "https://$script:PublishModuleName.com/license" `
                       -ProjectUri "https://$script:PublishModuleName.com" `
                       -WarningAction SilentlyContinue

        $psgetItemInfo = Find-Module $script:PublishModuleName -RequiredVersion $version
        Assert (($psgetItemInfo.Name -eq $script:PublishModuleName) -and ($psgetItemInfo.Version.ToString() -eq $version)) "Publish-Module should publish a module with valid module name, $($psgetItemInfo.Name)"
    } `
    -Skip:$(-not (Test-ModuleSxSVersionSupport))

    
    
    
    
    
    
    It "PublishModuleWithConfirmAndNoToPrompt" {
        $outputPath = $script:TempPath
        $guid =  [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        
        $Global:proxy.UI.ChoiceToMake=2
        $content = $null

        $version = "1.0"
        New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"

        
        Copy-Item $script:PublishModuleBase $script:ProgramFilesModulesPath -Recurse -Force

        try
        {
            $result = ExecuteCommand $runspace "Publish-Module -Name $script:PublishModuleName -NuGetApiKey $script:ApiKey -Confirm"
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

        $shouldProcessMessage = $script:LocalizedData.PublishModulewhatIfMessage -f ($version, $script:PublishModuleName)
        Assert ($content -and ($content -match $shouldProcessMessage)) "publish module confirm prompt is not working, $content"

        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Module $script:PublishModuleName -RequiredVersion $version}`
                                          -expectedFullyQualifiedErrorId "NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.FindPackage"
    } `
    -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    
    
    
    
    
    
    It "PublishModuleWithConfirmAndYesToPrompt" {
        $outputPath = $script:TempPath
        $guid =  [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        
        $Global:proxy.UI.ChoiceToMake=0
        $content = $null

        $version = "2.0"
        New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"

        
        Copy-Item $script:PublishModuleBase $script:ProgramFilesModulesPath -Recurse -Force

        try
        {
            $result = ExecuteCommand $runspace 'Import-Module PowerShellGet -Global -Force; $PSGallerySourceUri="$script:TempPath\PSGalleryRepo"; $PSGalleryPublishUri="$script:TempPath\PSGalleryRepo"; Publish-Module -Name ContosoPublishModule -NuGetApiKey TestPSGalleryApiKey -Confirm'
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

        $shouldProcessMessage = $script:LocalizedData.PublishModulewhatIfMessage -f ($version, $script:PublishModuleName)
        Assert ($content -and ($content -match $shouldProcessMessage)) "publish module confirm prompt is not working, $content"

        $psgetItemInfo = Find-Module $script:PublishModuleName -RequiredVersion $version
        Assert (($psgetItemInfo.Name -eq $script:PublishModuleName) -or (($psgetItemInfo.Version.ToString() -eq $version))) "Publish-Module should publish a module with valid module name after confirming YES, $($psgetItemInfo.Name)"
    } `
    -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    
    
    
    
    
    
    It "PublishModuleWithWhatIf" {
        $version = "3.0"
        New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"

        
        Copy-Item $script:PublishModuleBase $script:ProgramFilesModulesPath -Recurse -Force

        $outputPath = $script:TempPath
        $guid =  [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1
        $content = $null

        try
        {
            $result = ExecuteCommand $runspace 'Import-Module PowerShellGet -Global -Force; $PSGallerySourceUri="$script:TempPath\PSGalleryRepo"; $PSGalleryPublishUri="$script:TempPath\PSGalleryRepo"; Publish-Module -Name ContosoPublishModule -NuGetApiKey TestPSGalleryApiKey -WhatIf'
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

        $shouldProcessMessage = $script:LocalizedData.PublishModulewhatIfMessage -f ($version, $script:PublishModuleName)
        Assert ($content -and ($content -match $shouldProcessMessage)) "publish module whatif message is missing, $content"

        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Module $script:PublishModuleName -RequiredVersion $version}`
                                          -expectedFullyQualifiedErrorId "NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.FindPackage"
    } `
    -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    
    
    
    
    
    
    It "PublishModuleMultipleVersions" {
        $version = "1.0.0"
        New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"

        
        Copy-Item $script:PublishModuleBase $script:ProgramFilesModulesPath -Recurse -Force

        Publish-Module -Name $script:PublishModuleName -NuGetApiKey $script:ApiKey -ReleaseNotes "$script:PublishModuleName release notes" -Tags PSGet -LicenseUri "https://$script:PublishModuleName.com/license" -ProjectUri "https://$script:PublishModuleName.com" -WarningAction SilentlyContinue

        $psgetItemInfo = Find-Module $script:PublishModuleName -RequiredVersion $version
        Assert (($psgetItemInfo.Name -eq $script:PublishModuleName) -and ($psgetItemInfo.Version.ToString() -eq $version)) "Publish-Module should publish a module with valid module name, $($psgetItemInfo.Name)"


        $version = "2.0.0"
        New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"

        
        Copy-Item $script:PublishModuleBase $script:ProgramFilesModulesPath -Recurse -Force

        Publish-Module -Name $script:PublishModuleName -NuGetApiKey $script:ApiKey -ReleaseNotes "$script:PublishModuleName release notes" -Tags PSGet -LicenseUri "https://$script:PublishModuleName.com/license" -ProjectUri "https://$script:PublishModuleName.com" -WarningAction SilentlyContinue

        $psgetItemInfo = Find-Module $script:PublishModuleName -RequiredVersion $version
        Assert (($psgetItemInfo.Name -eq $script:PublishModuleName) -and ($psgetItemInfo.Version.ToString() -eq $version)) "Publish-Module should publish a module with valid module name, $($psgetItemInfo.Name)"
    }

    
    
    
    
    
    
    It "PublishModuleWithNonExistingNestedModule" {
        New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion '1.0' -Description "$script:PublishModuleName module" -NestedModules "NonExistingNestedModule"

        AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Module -Path $script:PublishModuleBase -WarningAction SilentlyContinue}`
                                          -expectedFullyQualifiedErrorId 'UnableToResolveModuleDependency,Publish-PSArtifactUtility'
    }

    
    
    
    
    
    
    It "PublishModuleWithInvalidEntryInPSD1" {
        New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion '1.0' -Description "$script:PublishModuleName module" -NestedModules "NonExistingNestedModule"

        Set-Content -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") -Value @'
    @{
    ModuleVersion = 1.0
    Guid = '680e031b-f318-4534-bdc9-10f1787b2400'
    Copyright = '(c) 2015 manikb. All rights reserved.'
    Description = 'Test module description'
    Author = 'Contoso Author (author@contoso.com)'
    FunctionsToExport = '*'
    CmdletsToExport = '*'
    VariablesToExport = '*'
    AliasesToExport = '*'
    FileList2 = @()
    }
'@
        AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Module -Path $script:PublishModuleBase -WarningAction SilentlyContinue}`
                                          -expectedFullyQualifiedErrorId 'Modules_InvalidManifestMember,Microsoft.PowerShell.Commands.TestModuleManifestCommand'
    }

    It "PublishModuleWithPSEditionVariableInPSD1" {

        $Psd1FilePath = (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1")

        New-ModuleManifest -Path $Psd1FilePath

        Set-Content -Path $Psd1FilePath -Force -Value @'
@{
    ModuleVersion = '1.0'
    Guid = '680e031b-f318-4534-bdc9-10f1787b2400'
    Copyright = '(c) 2015 manikb. All rights reserved.'
    Description = 'Test module description'
    Author = 'Contoso Author (author@contoso.com)'
    FunctionsToExport = if($PSEdition -eq 'Desktop'){@('A','B')}elseif($PSEdition -eq 'Core'){@('C','D')};
    CmdletsToExport = '*'
    VariablesToExport = '*'
    AliasesToExport = '*'
}
'@
        if($PSVersionTable.PSVersion -ge '5.1.0')
        {
            Publish-Module -Path $script:PublishModuleBase -WarningAction SilentlyContinue
            $res = Find-Module -Name $script:PublishModuleName
            AssertEquals $res.Name $script:PublishModuleName "Module should be published with PSEdition variable"
        }
        else
        {
            AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Module -Path $script:PublishModuleBase -WarningAction SilentlyContinue}`
                                              -expectedFullyQualifiedErrorId 'Modules_InvalidManifest,Microsoft.PowerShell.Commands.TestModuleManifestCommand'
        }
    }

    It "PublishModuleWithPSScriptRootVariableInPSD1" {

        $Psd1FilePath = (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1")

        New-ModuleManifest -Path $Psd1FilePath

        Set-Content -Path $Psd1FilePath -Force -Value @'
@{
    ModuleVersion = '1.0'
    Guid = '680e031b-f318-4534-bdc9-10f1787b2400'
    Copyright = '(c) 2015 manikb. All rights reserved.'
    Description = "Test module description; $PSScriptRoot\ReleaseNotes.md has full description."
    Author = 'Contoso Author (author@contoso.com)'
    FunctionsToExport = '*'
    CmdletsToExport = '*'
    VariablesToExport = '*'
    AliasesToExport = '*'
}
'@
        Publish-Module -Path $script:PublishModuleBase -WarningAction SilentlyContinue
        $res = Find-Module -Name $script:PublishModuleName
        AssertEquals $res.Name $script:PublishModuleName "Module should be published with PSScriptRoot variable"
    }

    It "PublishModuleWithInvalidVariableInPSD1" {

        $Psd1FilePath = (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1")

        New-ModuleManifest -Path $Psd1FilePath

        Set-Content -Path $Psd1FilePath -Force -Value @'
@{
    ModuleVersion = '1.0'
    Guid = '680e031b-f318-4534-bdc9-10f1787b2400'
    Copyright = '(c) 2015 manikb. All rights reserved.'
    Description = 'Test module description'
    Author = 'Contoso Author (author@contoso.com)'
    FunctionsToExport = '*'
    CmdletsToExport = '*'
    VariablesToExport = '*'
    AliasesToExport = '*'
    FileList = "$InvalidVariable\TestFile.psm1"
}
'@
        AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Module -Path $script:PublishModuleBase -WarningAction SilentlyContinue}`
                                          -expectedFullyQualifiedErrorId 'Modules_InvalidManifest,Microsoft.PowerShell.Commands.TestModuleManifestCommand'

    }

    It "GetManifestHashTableWithInvalidVariableInPSD1" {

        $Psd1FilePath = (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1")

        New-ModuleManifest -Path $Psd1FilePath

        Set-Content -Path $Psd1FilePath -Force -Value @'
@{
    ModuleVersion = '1.0'
    Guid = '680e031b-f318-4534-bdc9-10f1787b2400'
    Copyright = '(c) 2015 manikb. All rights reserved.'
    Description = 'Test module description'
    Author = 'Contoso Author (author@contoso.com)'
    FunctionsToExport = '*'
    CmdletsToExport = '*'
    VariablesToExport = '*'
    AliasesToExport = '*'
    FileList = "$InvalidVariable\TestFile.psm1"
}
'@
        function Get-ManifestHashTableCaller
        {
            [CmdletBinding()]
            param($Psd1FilePath)

            & $script:psgetModuleInfo Get-ManifestHashTable -Path $Psd1FilePath -CallerPSCmdlet $PSCmdlet
        }

        AssertFullyQualifiedErrorIdEquals -scriptblock { Get-ManifestHashTableCaller -Psd1FilePath $Psd1FilePath }`
                                          -expectedFullyQualifiedErrorId 'ParseException,Get-ManifestHashTableCaller'

    }

    
    
    
    
    
    
    It PublishModuleWithXMLSpecialCharacters {
        $ModuleName = "ModuleWithSpecialChars"
        $ModuleBase = Join-Path $script:TempModulesPath $ModuleName
        $null = New-Item -Path $ModuleBase -ItemType Directory -Force

        $version = "1.0.0"
        $Description = "$ModuleName module <TestElement> $&*!()[]{}@
        $ReleaseNotes = @("$ModuleName release notes", " <TestElement> $&*!()[]{}@
        $Tags = "PSGet","Special$&*!()[]{}@
        $ProjectUri = "https://$ModuleName.com/Project"
        $IconUri = "https://$ModuleName.com/Icon"
        $LicenseUri = "https://$ModuleName.com/license"
        $Author = "Author
        $CompanyName = "CompanyName <TestElement>$&*!()[]{}@
        $CopyRight = "CopyRight <TestElement>$&*!()[]{}@

        New-ModuleManifest -Path (Join-Path -Path $ModuleBase -ChildPath "$ModuleName.psd1") -ModuleVersion $version -Description $Description -Author $Author -CompanyName $CompanyName -Copyright $CopyRight

        Publish-Module -Path $ModuleBase -NuGetApiKey $script:ApiKey -ReleaseNotes $ReleaseNotes -Tags $Tags -LicenseUri $LicenseUri -ProjectUri $ProjectUri -WarningAction SilentlyContinue

        RemoveItem -path $ModuleBase

        $psgetItemInfo = Find-Module $ModuleName -RequiredVersion $version

        AssertEqualsCaseInsensitive $psgetItemInfo.Name $ModuleName "ModuleName should be same as the published one"
        AssertEqualsCaseInsensitive $psgetItemInfo.version $version "version should be same as the published one"
        AssertEqualsCaseInsensitive $psgetItemInfo.Description $Description "Description should be same as the published one"
        AssertEqualsCaseInsensitive $psgetItemInfo.ReleaseNotes "$($ReleaseNotes -join "`n")" "ReleaseNotes should be same as the published one"
        AssertEqualsCaseInsensitive $psgetItemInfo.ProjectUri $ProjectUri "ProjectUri should be same as the published one"
        AssertEqualsCaseInsensitive $psgetItemInfo.Author $Author "Author should be same as the published one"
        AssertEqualsCaseInsensitive $psgetItemInfo.CompanyName $CompanyName "CompanyName should be same as the published one"
        AssertEqualsCaseInsensitive $psgetItemInfo.CopyRight $CopyRight "CopyRight should be same as the published one"
        Assert       ($psgetItemInfo.Tags -contains $($Tags[0])) "Tags ($($psgetItemInfo.Tags)) should contain the published one ($($Tags[0]))"
        Assert       ($psgetItemInfo.Tags -contains $($Tags[1])) "Tags ($($psgetItemInfo.Tags)) should contain the published one ($($Tags[1]))"
        AssertEqualsCaseInsensitive $psgetItemInfo.LicenseUri $LicenseUri "LicenseUri should be same as the published one"
    }

    
    
    
    
    
    
    It PublishModulePSDataInManifestFile {
        $version = "1.0.0"
        $Description = "$script:PublishModuleName module"
        $ReleaseNotes = "$script:PublishModuleName release notes"
        $Tags = "PSGet","DSC"
        $ProjectUri = "https://$script:PublishModuleName.com/Project"
        $IconUri = "https://$script:PublishModuleName.com/Icon"
        $LicenseUri = "https://$script:PublishModuleName.com/license"
        $Author = "AuthorName"
        $CompanyName = "CompanyName"
        $CopyRight = "CopyRight"

        New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") `
                           -ModuleVersion $version `
                           -Description "$script:PublishModuleName module" `
                           -NestedModules "$script:PublishModuleName.psm1" `
                           -Author $Author `
                           -CompanyName $CompanyName `
                           -Copyright $CopyRight `
                           -Tags $Tags `
                           -IconUri $IconUri `
                           -ProjectUri $ProjectUri `
                           -LicenseUri $LicenseUri `
                           -ReleaseNotes $ReleaseNotes `
                           -WarningAction SilentlyContinue


        Publish-Module -Path $script:PublishModuleBase -NuGetApiKey $script:ApiKey -WarningAction SilentlyContinue

        $psgetItemInfo = Find-Module $script:PublishModuleName -RequiredVersion $version

        AssertEqualsCaseInsensitive $psgetItemInfo.Name $script:PublishModuleName "ModuleName should be same as the published one"
        AssertEqualsCaseInsensitive $psgetItemInfo.version $version "version should be same as the published one"
        AssertEqualsCaseInsensitive $psgetItemInfo.Description $Description "Description should be same as the published one"
        AssertEqualsCaseInsensitive $psgetItemInfo.ReleaseNotes $ReleaseNotes "ReleaseNotes should be same as the published one"
        AssertEqualsCaseInsensitive $psgetItemInfo.ProjectUri $ProjectUri "ProjectUri should be same as the published one"
        AssertEqualsCaseInsensitive $psgetItemInfo.Author $Author "Author should be same as the published one"
        AssertEqualsCaseInsensitive $psgetItemInfo.CompanyName $CompanyName "CompanyName should be same as the published one"
        AssertEqualsCaseInsensitive $psgetItemInfo.CopyRight $CopyRight "CopyRight should be same as the published one"
        Assert       ($psgetItemInfo.Tags -contains $Tags[0]) "Tags ($($psgetItemInfo.Tags)) should contain the published one ($($Tags[0]))"
        Assert       ($psgetItemInfo.Tags -contains $Tags[1]) "Tags ($($psgetItemInfo.Tags)) should contain the published one ($($Tags[1]))"
        AssertEqualsCaseInsensitive $psgetItemInfo.LicenseUri $LicenseUri "LicenseUri should be same as the published one"
    } `
    -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')

    
    
    
    
    
    
    It PublishModuleFunctionsAsTagsWarnWithoutSkipAutomaticTags {
        $version = "1.0.0"
        $Description = "$script:PublishModuleName module"
        $Tags = "PSGet","DSC"
        $Author = "AuthorName"
        $CompanyName = "CompanyName"
        $CopyRight = "CopyRight"

        $functionNames = 1..250 | Foreach-Object { "Get-TestFunction$($_)" }
        $tempFunctions = 1..250 | Foreach-Object { "function Get-TestFunction$($_) { Get-Date }" + [Environment]::NewLine }
        Set-Content (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psm1") -Value $tempFunctions

        New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") `
                           -ModuleVersion $version `
                           -Description "$script:PublishModuleName module" `
                           -NestedModules "$script:PublishModuleName.psm1" `
                           -Author $Author `
                           -CompanyName $CompanyName `
                           -Copyright $CopyRight `
                           -Tags $Tags `
                           -FunctionsToExport $functionNames

        Publish-Module -Path $script:PublishModuleBase `
                       -NuGetApiKey $script:ApiKey `
                       -Repository "PSGallery" `
                       -WarningAction SilentlyContinue `
                       -WarningVariable wa

        Assert ("$wa".Contains('4000 characters')) "Warning messages should include 'Tag list exceeded 4000 characters and may not be accepted by some Nuget feeds.'"
    } `
    -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')

    
    
    
    
    
    
    It PublishModuleFunctionsAsTagsWithSkipAutomaticTags {
        $version = "1.0.0"
        $Description = "$script:PublishModuleName module"
        $Tags = "PSGet","DSC"
        $Author = "AuthorName"
        $CompanyName = "CompanyName"
        $CopyRight = "CopyRight"

        $functionNames = 1..250 | Foreach-Object { "Get-TestFunction$($_)" }
        $tempFunctions = 1..250 | Foreach-Object { "function Get-TestFunction$($_) { Get-Date }" + [Environment]::NewLine }
        Set-Content (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psm1") -Value $tempFunctions

        New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") `
                           -ModuleVersion $version `
                           -Description "$script:PublishModuleName module" `
                           -NestedModules "$script:PublishModuleName.psm1" `
                           -Author $Author `
                           -CompanyName $CompanyName `
                           -Copyright $CopyRight `
                           -Tags $Tags `
                           -FunctionsToExport $functionNames

        Publish-Module -Path $script:PublishModuleBase `
                       -NuGetApiKey $script:ApiKey `
                       -Repository "PSGallery" `
                       -SkipAutomaticTags `
                       -WarningAction SilentlyContinue `
                       -WarningVariable wa

        Assert (-not "$wa".Contains('4000 characters')) "Warning messages should not include 'Tag list exceeded 4000 characters and may not be accepted by some Nuget feeds.'"
    } `
    -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')

    
    
    
    
    
    
    It PublishModuleWithUriObjectsAndPSDataInManifestFile {
        $version = "1.0.0"
        $Description = "$script:PublishModuleName module"
        $ReleaseNotes = "$script:PublishModuleName release notes"
        $Tags = "PSGet","DSC"
        $ProjectUri = New-Object System.Uri "https://$script:PublishModuleName.com/Project"
        $IconUri = New-Object System.Uri "https://$script:PublishModuleName.com/Icon"
        $LicenseUri = New-Object System.Uri "https://$script:PublishModuleName.com/license"
        $Author = "AuthorName"
        $CompanyName = "CompanyName"
        $CopyRight = "CopyRight"

        New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") `
                           -ModuleVersion $version `
                           -Description "$script:PublishModuleName module" `
                           -NestedModules "$script:PublishModuleName.psm1" `
                           -Author $Author `
                           -CompanyName $CompanyName `
                           -Copyright $CopyRight `
                           -Tags $Tags `
                           -ReleaseNotes $ReleaseNotes


        Publish-Module -Path $script:PublishModuleBase -NuGetApiKey $script:ApiKey `
                       -Repository "PSGallery" `
                       -ProjectUri $ProjectUri -LicenseUri $LicenseUri -IconUri $IconUri `
                       -WarningAction SilentlyContinue

        $psgetItemInfo = Find-Module $script:PublishModuleName -RequiredVersion $version

        AssertEquals $psgetItemInfo.Name $script:PublishModuleName "ModuleName should be same as the published one"
        AssertEquals $psgetItemInfo.version $version "version should be same as the published one"
        AssertEquals $psgetItemInfo.Description $Description "Description should be same as the published one"
        AssertEquals $psgetItemInfo.ReleaseNotes $ReleaseNotes "ReleaseNotes should be same as the published one"
        AssertEquals $psgetItemInfo.ProjectUri $ProjectUri "ProjectUri should be same as the published one"
        AssertEquals $psgetItemInfo.Author $Author "Author should be same as the published one"
        AssertEquals $psgetItemInfo.CompanyName $CompanyName "CompanyName should be same as the published one"
        AssertEquals $psgetItemInfo.CopyRight $CopyRight "CopyRight should be same as the published one"
        Assert       ($psgetItemInfo.Tags -contains $Tags[0]) "Tags ($($psgetItemInfo.Tags)) should contain the published one ($($Tags[0]))"
        Assert       ($psgetItemInfo.Tags -contains $Tags[1]) "Tags ($($psgetItemInfo.Tags)) should contain the published one ($($Tags[1]))"
        AssertEquals $psgetItemInfo.LicenseUri $LicenseUri "LicenseUri should be same as the published one"
        Assert ($psgetItemInfo.PublishedDate -and ($psgetItemInfo.PublishedDate.GetType().Name -eq 'DateTime')) "PublishedDate is missing, $($psgetItemInfo.PublishedDate)"
    } `
    -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')

    
    
    
    
    
    
    
    
    It ValidateWithoutPSGetFormatVersion {

        $moduleName = "TestMod_$(Get-Random)"

        CreateAndPublishTestModuleWithVersionFormat -ModuleName $moduleName `
                                                    -NuGetApiKey $script:ApiKey `
                                                    -Repository "PSGallery" `
                                                    -Versions @('1.0.0','2.0.0') `
                                                    -PSGetFormatVersion '0.0' `
                                                    -ModulesPath $script:TempModulesPath

        try
        {
            $psgetItemInfo = Find-Module -Name $moduleName -RequiredVersion '1.0.0'
            AssertNotNull $psgetItemInfo "Module without PowerShellGetFormatVersion is not found"
            AssertNull $psgetItemInfo.PowerShellGetFormatVersion "PowerShellGetFormatVersion property is not null, $($psgetItemInfo.PowerShellGetFormatVersion)"

            Install-Module -Name $moduleName -RequiredVersion '1.0.0'
            $moduleInfo = Get-Module -ListAvailable -Name $moduleName
            AssertEquals $moduleInfo.Name $moduleName "$moduleName Module without PowerShellGetFormatVersion is not installed"
            AssertEquals $moduleInfo.Version "1.0.0" "Invalid PowerShellGetFormatVersion value on PSGetModuleInfo, $($moduleInfo.Version)"

            Update-Module -Name $moduleName -RequiredVersion '2.0.0'
            if(Test-ModuleSxSVersionSupport)
            {
                $moduleInfo = Get-Module -FullyQualifiedName @{ModuleName=$moduleName;RequiredVersion='2.0.0'} -ListAvailable
            }
            else
            {
                $moduleInfo = Get-Module $moduleName -ListAvailable
            }
            AssertEquals $moduleInfo.Name $moduleName "$moduleName Module without PowerShellGetFormatVersion is not updated properly"
            AssertEquals $moduleInfo.Version "2.0.0" "Invalid PowerShellGetFormatVersion value on PSGetModuleInfo, $($moduleInfo.Version)"
        }
        finally
        {
           PSGetTestUtils\Uninstall-Module -Name $moduleName
           
        }
    }

    
    
    
    
    
    
    
    
    It ValidateCompatiblePSGetFormatVersion {

        $PSGetFormatVersion = [Version]'1.7'
        $moduleName = "TestMod_$(Get-Random)"

        CreateAndPublishTestModuleWithVersionFormat -ModuleName $moduleName `
                                                    -NuGetApiKey $script:ApiKey `
                                                    -Repository "PSGallery" `
                                                    -Versions @('1.0.0','2.0.0') `
                                                    -PSGetFormatVersion $PSGetFormatVersion `
                                                    -ModulesPath $script:TempModulesPath

        try
        {
            $psgetItemInfo = Find-Module -Name $moduleName -RequiredVersion '1.0.0'
            AssertNotNull $psgetItemInfo "Module without PowerShellGetFormatVersion is not found"
            AssertEquals $psgetItemInfo.PowerShellGetFormatVersion $PSGetFormatVersion "PowerShellGetFormatVersion property is not null, $($psgetItemInfo.PowerShellGetFormatVersion)"

            Install-Module -Name $moduleName -RequiredVersion '1.0.0'
            $moduleInfo = Get-Module -ListAvailable -Name $moduleName
            AssertEquals $moduleInfo.Name $moduleName "$moduleName Module without PowerShellGetFormatVersion is not installed"
            AssertEquals $moduleInfo.Version "1.0.0" "Invalid PowerShellGetFormatVersion value on PSGetModuleInfo, $($moduleInfo.Version)"

            Update-Module -Name $moduleName -RequiredVersion '2.0.0'

            if(Test-ModuleSxSVersionSupport)
            {
                $moduleInfo = Get-Module -FullyQualifiedName @{ModuleName=$moduleName;RequiredVersion='2.0.0'} -ListAvailable
            }
            else
            {
                $moduleInfo = Get-Module $moduleName -ListAvailable
            }

            AssertEquals $moduleInfo.Name $moduleName "$moduleName Module without PowerShellGetFormatVersion is not updated properly"
            AssertEquals $moduleInfo.Version "2.0.0" "Invalid PowerShellGetFormatVersion value on PSGetModuleInfo, $($moduleInfo.Version)"
        }
        finally
        {
           PSGetTestUtils\Uninstall-Module -Name $moduleName
        }
    }

    
    
    
    
    
    
    
    
    It ValidateIncompatiblePSGetFormatVersion {

        $PSGetFormatVersion = [Version]'2.1'
        $moduleName = "TestMod_$(Get-Random)"

        CreateAndPublishTestModuleWithVersionFormat -ModuleName $moduleName `
                                                    -NuGetApiKey $script:ApiKey `
                                                    -Repository "PSGallery" `
                                                    -Versions @('1.0.0','2.0.0') `
                                                    -PSGetFormatVersion $PSGetFormatVersion `
                                                    -ModulesPath $script:TempModulesPath `
                                                    -WarningAction SilentlyContinue

        $psgetItemInfo = Find-Module -Name $moduleName -RequiredVersion '1.0.0'
        AssertNotNull $psgetItemInfo "Module without PowerShellGetFormatVersion is not found"
        AssertEquals $psgetItemInfo.PowerShellGetFormatVersion $PSGetFormatVersion "PowerShellGetFormatVersion property is not null, $($psgetItemInfo.PowerShellGetFormatVersion)"

        AssertFullyQualifiedErrorIdEquals -scriptblock {Install-Module -Name $moduleName -RequiredVersion '1.0.0' -WarningAction SilentlyContinue } `
                                            -expectedFullyQualifiedErrorId "NotSupportedPowerShellGetFormatVersion,Install-Package,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage"
    }

    
    
    
    
    
    
    It PublishModuleWithSupportedParameter {
       $version = "1.0"
       $Tags = "Tags"
       $LicenseUri = 'https://contoso.com/license'
       $ProjectUri = 'https://contoso.com/'
       $IconUri = 'https://contoso.com/icon'
       $ReleaseNotes = 'Test module for external module dependecies'
       New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"
       
       Copy-Item $script:PublishModuleBase $script:ProgramFilesModulesPath -Recurse -Force

       Publish-Module -Name $script:PublishModuleName -NuGetApiKey $script:ApiKey -Tags $Tags -LicenseUri $LicenseUri -IconUri $IconUri  `
                      -ProjectUri $ProjectUri -ReleaseNotes $ReleaseNotes -WarningAction SilentlyContinue -WarningVariable wa

       AssertEquals $wa.Count 5 "There should be one warning message"
       Assert ("$wa".Contains("ReleaseNotes")) "Warning messages should include 'ReleaseNotes is now supported'"
       Assert ("$wa".Contains("LicenseUri")) "Warning messages should include 'LicenseUri is now supported'"
       Assert ("$wa".Contains("ProjectUri")) "Warning messages should include 'ProjectUri are now supported'"
       Assert ("$wa".Contains("IconUri")) "Warning messages should include 'IconUri is now supported'"
       Assert ("$wa".Contains("Tags")) "Warning messages should include 'Tags are now supported'"
    } `
    -Skip:$($PSCulture -ne 'en-US')

    
    
    
    
    
    
    It PublishModuleWithAsteriskInExportedProperties  {
        $ModuleName = "DscTestModule"
        $TempModulesPath = Join-Path $script:TempPath "$(Get-Random)"
        $null = New-Item -Path $TempModulesPath -ItemType Directory -Force

        $TestModuleSourcePath = Join-Path -Path $PSScriptRoot -ChildPath TestModules | Join-Path -ChildPath $ModuleName
        Copy-Item -Path $TestModuleSourcePath -Destination $TempModulesPath -Recurse -Force
        $ModuleBase = Join-Path -Path $TempModulesPath -ChildPath $ModuleName

        
        $content = @"
            using System;
            using System.Management.Automation;
            namespace PSGetTestModule
            {
               [Cmdlet("Test","PSGetTestCmdlet")]
                public class PSGetTestCmdlet : PSCmdlet
                {
                    [Parameter]
                    public int a {
                        get;
                        set;
                    }
                    protected override void ProcessRecord()
                    {
                        String s = "Value is :" + a;
                        WriteObject(s);
                    }
                }
            }

"@

        $binaryDllName = "psgettestbinary_$(Get-Random).dll"
        $testBinaryPath = Join-Path -Path $ModuleBase -ChildPath $binaryDllName
        Add-Type -TypeDefinition $content -OutputAssembly $testBinaryPath -OutputType Library

        $tags = @("PSGet","DSC","CommandsAndResource", 'Tag1','Tag2', 'Tag3', "Tag-$ModuleName-$version")
        $manfiestFilePath = Join-Path -Path $ModuleBase -ChildPath "$ModuleName.psd1"
        $version = '2.0.0'
        RemoveItem -path $manfiestFilePath

        if($PSVersionTable.PSVersion -ge '5.0.0')
        {
            New-ModuleManifest -Path $manfiestFilePath `
                           -ModuleVersion $version  `
                           -NestedModules "$ModuleName.psm1",$binaryDllName `
                           -Tags $tags `
                           -Description 'Temp Description KeyWord1 Keyword2 Keyword3' `
                           -LicenseUri "https://$ModuleName.com/license" `
                           -IconUri "https://$ModuleName.com/icon" `
                           -ProjectUri "https://$ModuleName.com" `
                           -ReleaseNotes "$ModuleName release notes" `
                           -DscResourcesToExport "*"
        }
        else
        {
            New-ModuleManifest -Path $manfiestFilePath `
                           -ModuleVersion $version  `
                           -NestedModules "$ModuleName.psm1",$binaryDllName `
                           -Description 'Temp Description KeyWord1 Keyword2 Keyword3' `
        }

        $null = Publish-Module -Path $ModuleBase `
                           -NuGetApiKey $script:ApiKey `
                           -ReleaseNotes "$ModuleName release notes" `
                           -Tags $tags `
                           -LicenseUri "https://$ModuleName.com/license" `
                           -IconUri "https://$ModuleName.com/icon" `
                           -ProjectUri "https://$ModuleName.com" `
                           -WarningAction SilentlyContinue `
                           -WarningVariable wa

        
        if($PSEdition -ne 'Core') {
            Assert ("$wa".Contains("exported cmdlets")) "Warning messages should include 'exported cmdlets'"
        }

        Assert ("$wa".Contains("exported functions")) "Warning messages should include 'exported functions'"

        if($PSVersionTable.PSVersion -ge '5.0.0')
        {
            Assert ("$wa".Contains("exported DscResources")) "Warning messages should include 'exported DscResources'"
        }

        $itemInfo = Find-Module -Includes RoleCapability | Where-Object {$_.Name -eq 'DscTestModule'}
        AssertNotNull $itemInfo "Publish-Module was not able to populate the RoleCapability Names."
        AssertEquals $itemInfo.Name 'DscTestModule' "Publish-Module was not able to populate the RoleCapability Names."
        Assert ($itemInfo.Includes.RoleCapability -contains 'Lev1Maintenance') "Publish-Module was not able to populate the RoleCapability Names: $($itemInfo.Includes.RoleCapability)"
        Assert ($itemInfo.Includes.RoleCapability -contains 'Lev2Maintenance') "Publish-Module was not able to populate the RoleCapability Names: $($itemInfo.Includes.RoleCapability)"
    } `
    -Skip:$($PSCulture -ne 'en-US')

    
    
    
    
    
    
    It PublishModuleWithBootstrappedNugetExe {
        try {
            $script:NuGetExeName = 'NuGet.exe'
            $script:PSGetProgramDataPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\PowerShell\PowerShellGet\'
            $script:ProgramDataExePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetProgramDataPath -ChildPath $script:NuGetExeName

            Install-NuGet28
            
            $script:psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
            Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $script:psgetModuleInfo.ModuleBase

            
            $oldNuGetExeVersion = [System.Version](Get-Command $script:ProgramDataExePath).FileVersionInfo.FileVersion
            AssertEquals $oldNuGetExeVersion $script:OutdatedNuGetExeVersion "Outdated NuGet.exe version is $oldNuGetExeVersion when it should have been $script:OutdatedNuGetExeVersion."
            $err = $null

            try {
                $result = Publish-Module -Name $script:PublishModuleName -Force -WarningAction SilentlyContinue
            }
            catch {
                $err = $_
            }

            AssertNull $err "$err"
            AssertNull $result "$result"
            Assert (test-path $script:ProgramDataExePath) "NuGet.exe did not install properly.  The file could not be found under path $script:PSGetProgramDataPath."

            $currentNuGetExeVersion = [System.Version](Get-Command $script:ProgramDataExePath).FileVersionInfo.FileVersion
            Assert ($currentNuGetExeVersion -gt $oldNuGetExeVersion) "Current NuGet.exe version is $currentNuGetExeVersion when it should have been greater than version $oldNuGetExeVersion."

            $module = find-module $script:PublishModuleName -RequiredVersion $version
            AssertEquals $module.Name $script:PublishModuleName "Module did not successfully publish. Module name was $($module.Name) when it should have been $script:PublishModuleName."
        }
        finally {
            Install-NuGetBinaries
        }
    } -Skip:$($PSEdition -eq 'Core')

    
    
    
    
    
    
    It PublishModuleUpgradeNugetExeAndYesToPrompt {
        try {
            $script:NuGetExeName = 'NuGet.exe'
            $script:PSGetProgramDataPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\PowerShell\PowerShellGet\'
            $script:ProgramDataExePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetProgramDataPath -ChildPath $script:NuGetExeName

            Install-NuGet28
            
            $script:psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
            Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $script:psgetModuleInfo.ModuleBase

            
            $oldNuGetExeVersion = [System.Version](Get-Command $script:ProgramDataExePath).FileVersionInfo.FileVersion
            AssertEquals $oldNuGetExeVersion $script:OutdatedNuGetExeVersion "Outdated NuGet.exe version is $oldNuGetExeVersion when it should have been $script:OutdatedNuGetExeVersion."

            $outputPath = $script:TempPath
            $guid = [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            
            $Global:proxy.UI.ChoiceToMake = 0
            $content = $null
            $err = $null

            try {
                $result = ExecuteCommand $runspace "Publish-Module -Name $script:PublishModuleName"
            }
            catch {
                $err = $_
            }
            finally {
                $fileName = "PromptForChoice-0.txt"
                $path = join-path $outputFilePath $fileName
                if (Test-Path $path) {
                    $content = get-content $path
                }

                CloseRunSpace $runspace
                RemoveItem $outputFilePath
            }

            AssertNull $result "$result"
            Assert ($content -and ($content -match 'upgrade')) "Publish module confirm prompt is not working, $content."
            Assert (test-path $script:ProgramDataExePath) "NuGet.exe did not install properly.  The file could not be found under path $script:PSGetProgramDataPath."

            $currentNuGetExeVersion = [System.Version](Get-Command $script:ProgramDataExePath).FileVersionInfo.FileVersion
            Assert ($currentNuGetExeVersion -gt $oldNuGetExeVersion) "Current NuGet.exe version is $currentNuGetExeVersion when it should have been greater than version $oldNuGetExeVersion."

            $module = find-module $script:PublishModuleName -RequiredVersion $version
            AssertEquals $module.Name $script:PublishModuleName "Module did not successfully publish. Module name was $($module.Name) when it should have been $script:PublishModuleName."
        }
        finally {
            Install-NuGetBinaries
        }
    } -Skip:$($PSEdition -eq 'Core'  -or $env:APPVEYOR_TEST_PASS -eq 'True')

    
    
    
    
    
    
    It PublishModuleInstallNugetExeAndYesToPrompt {
        try {
            $script:NuGetExeName = 'NuGet.exe'
            $script:PSGetProgramDataPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\PowerShell\PowerShellGet\'
            $script:ProgramDataExePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetProgramDataPath -ChildPath $script:NuGetExeName

            Remove-NuGetExe
            
            $script:psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
            Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $script:psgetModuleInfo.ModuleBase
            Assert ((test-path $script:ProgramDataExePath) -eq $false) "NuGet.exe did not install properly uninstall."

            $outputPath = $script:TempPath
            $guid = [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            
            $Global:proxy.UI.ChoiceToMake = 0
            $content = $null
            $err = $null

            try {
                $result = ExecuteCommand $runspace "Publish-Module -Name $script:PublishModuleName"
            }
            catch {
                $err = $_
            }
            finally {
                $fileName = "PromptForChoice-0.txt"
                $path = join-path $outputFilePath $fileName
                if (Test-Path $path) {
                    $content = get-content $path
                }

                CloseRunSpace $runspace
                RemoveItem $outputFilePath
            }

            AssertNull $err "$err"
            AssertNull $result "$result"
            Assert ($content -and ($content -match 'install')) "Publish module confirm prompt is not working, $content."
            Assert (test-path $script:ProgramDataExePath) "NuGet.exe did not install properly.  The file could not be found under path $script:PSGetProgramDataPath."

            $module = find-module $script:PublishModuleName -RequiredVersion $version
            AssertEquals $module.Name $script:PublishModuleName "Module did not successfully publish. Module name was $($module.Name) when it should have been $script:PublishModuleName."
        }
        finally {
            Install-NuGetBinaries
        }
    } -Skip:$($PSEdition -eq 'Core' -or $env:APPVEYOR_TEST_PASS -eq 'True')

    
    
    
    
    
    
    It PublishModuleUpgradeNugetExeAndNoToPrompt {
        try {
            RemoveItem "$script:ProgramFilesModulesPath\$script:PublishModuleName\*"
            RemoveItem "$script:ProgramFilesModulesPath\$script:PublishModuleName"

            $script:NuGetExeName = 'NuGet.exe'
            $script:PSGetProgramDataPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\PowerShell\PowerShellGet\'
            $script:ProgramDataExePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetProgramDataPath -ChildPath $script:NuGetExeName

            Install-NuGet28
            
            $script:psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
            Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $script:psgetModuleInfo.ModuleBase

            
            $oldNuGetExeVersion = [System.Version](Get-Command $script:ProgramDataExePath).FileVersionInfo.FileVersion
            AssertEquals $oldNuGetExeVersion $script:OutdatedNuGetExeVersion "Outdated NuGet.exe version is $oldNuGetExeVersion when it should have been $script:OutdatedNuGetExeVersion."

            $outputPath = $script:TempPath
            $guid = [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            
            $Global:proxy.UI.ChoiceToMake = 1
            $content = $null
            $err = $null

            try {
                $result = ExecuteCommand $runspace "Publish-Module -Name $script:PublishModuleName"
            }
            catch {
                $err = $_
            }
            finally {
                $fileName = "PromptForChoice-0.txt"
                $path = join-path $outputFilePath $fileName
                if (Test-Path $path) {
                    $content = get-content $path
                }
                CloseRunSpace $runspace
                RemoveItem $outputFilePath
            }

            AssertNotNull $err "$err"
            AssertNull $result "$result"
            Assert ($content -and ($content -match 'upgrade')) "Publish module confirm prompt is not working, $content."
            Assert (test-path $script:ProgramDataExePath) "NuGet.exe did not install properly.  The file could not be found under path $script:PSGetProgramDataPath."

            $currentNuGetExeVersion = [System.Version](Get-Command $script:ProgramDataExePath).FileVersionInfo.FileVersion
            AssertEquals $currentNuGetExeVersion $script:OutdatedNuGetExeVersion "Current version of NuGet.exe is $currentNuGetExeVersion when it should have been $script:OutdatedNuGetExeVersion."

            $module = find-module $script:PublishModuleName -RequiredVersion $version -ErrorAction SilentlyContinue
            AssertNull ($module) "Module published when it should not have."
        }
        finally {
            Install-NuGetBinaries
        }
    } -Skip:$($PSEdition -eq 'Core'  -or $env:APPVEYOR_TEST_PASS -eq 'True')

    
    
    
    
    
    
    It PublishModuleInstallNugetExeAndNoToPrompt {
        try {
            $script:NuGetExeName = 'NuGet.exe'
            $script:PSGetProgramDataPath = Microsoft.PowerShell.Management\Join-Path -Path $env:ProgramData -ChildPath 'Microsoft\Windows\PowerShell\PowerShellGet\'
            $script:ProgramDataExePath = Microsoft.PowerShell.Management\Join-Path -Path $script:PSGetProgramDataPath -ChildPath $script:NuGetExeName

            Remove-NuGetExe
            
            $script:psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
            Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $script:psgetModuleInfo.ModuleBase
            Assert ((test-path $script:ProgramDataExePath) -eq $false) "NuGet.exe did not install properly uninstall."

            $outputPath = $script:TempPath
            $guid = [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            
            $Global:proxy.UI.ChoiceToMake = 1
            $content = $null
            $err = $null

            try {
                $result = ExecuteCommand $runspace "Publish-Module -Name $script:PublishModuleName"
            }
            catch {
                $err = $_
            }
            finally {
                $fileName = "PromptForChoice-0.txt"
                $path = join-path $outputFilePath $fileName
                if (Test-Path $path) {
                    $content = get-content $path
                }
                CloseRunSpace $runspace
                RemoveItem $outputFilePath
            }

            AssertNotNull $err "$err"
            AssertNull $result "$result"
            Assert ($content -and ($content -match 'install')) "Publish module confirm prompt is not working, $content."
            Assert ((Test-Path $script:ProgramDataExePath) -eq $false) "NuGet.exe installed when it should not have."

            $module = find-module $script:PublishModuleName -RequiredVersion $version -ErrorAction SilentlyContinue
            AssertNull ($module) "Module published when it should not have."
        }
        finally {
            Install-NuGetBinaries
        }
    } -Skip:$($PSEdition -eq 'Core'  -or $env:APPVEYOR_TEST_PASS -eq 'True')
}

Describe PowerShell.PSGet.PublishModuleTests.P1 -Tags 'P1','OuterLoop' {

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    BeforeEach {
        Set-Content (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psm1") -Value "function Get-$script:PublishModuleName { Get-Date }"
    }

    AfterEach {
        RemoveItem "$script:PSGalleryRepoPath\*"
        RemoveItem "$script:ProgramFilesModulesPath\$script:PublishModuleName"
        RemoveItem "$script:PublishModuleBase\*"
    }

    It "PublishModuleWithForceAndExistingVersion" {
        $version = "1.0"
        New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"
        Publish-Module -Path $script:PublishModuleBase -NuGetApiKey $script:ApiKey -WarningAction SilentlyContinue
        $psgetItemInfo = Find-Module $script:PublishModuleName -RequiredVersion $version
        Assert ($psgetItemInfo.Name -eq $script:PublishModuleName) "Publish-Module should publish a module with valid module path, $($psgetItemInfo.Name)"

        AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Module -Path $script:PublishModuleBase -NuGetApiKey $script:ApiKey -Force -WarningAction SilentlyContinue}`
                                          -expectedFullyQualifiedErrorId 'ModuleVersionIsAlreadyAvailableInTheGallery,Publish-Module'
    }

    It "PublishModuleWithForceAndLowerVersion" {
        $version = '2.0'
        $ManifestFilePath = Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1"
        New-ModuleManifest -Path $ManifestFilePath -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"

        Publish-Module -Path $script:PublishModuleBase -NuGetApiKey $script:ApiKey -WarningAction SilentlyContinue
        $psgetItemInfo = Find-Module $script:PublishModuleName -RequiredVersion $version
        Assert ($psgetItemInfo.Name -eq $script:PublishModuleName) "Publish-Module should publish a module with valid module path, $($psgetItemInfo.Name)"

        $version = '1.0'
        Update-ModuleManifest -Path $ManifestFilePath -ModuleVersion $version
        Publish-Module -Path $script:PublishModuleBase -NuGetApiKey $script:ApiKey -Force -WarningAction SilentlyContinue

        $psgetItemInfo = Find-Module $script:PublishModuleName -RequiredVersion $version
        Assert ($psgetItemInfo.Name -eq $script:PublishModuleName) "Publish-Module should publish a module with lower version, $($psgetItemInfo.Name)"
    }

    It "PublishModuleWithoutForceAndLowerVersion" {
        $version = '2.0'
        $ManifestFilePath = Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1"
        New-ModuleManifest -Path $ManifestFilePath -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"

        Publish-Module -Path $script:PublishModuleBase -NuGetApiKey $script:ApiKey -WarningAction SilentlyContinue
        $psgetItemInfo = Find-Module $script:PublishModuleName -RequiredVersion $version
        Assert ($psgetItemInfo.Name -eq $script:PublishModuleName) "Publish-Module should publish a module with valid module path, $($psgetItemInfo.Name)"

        $version = '1.0'
        Update-ModuleManifest -Path $ManifestFilePath -ModuleVersion $version

        AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Module -Path $script:PublishModuleBase -NuGetApiKey $script:ApiKey -WarningAction SilentlyContinue}`
                                          -expectedFullyQualifiedErrorId 'ModuleVersionShouldBeGreaterThanGalleryVersion,Publish-Module'
    }

    
    
    
    
    
    
    It "PublishModuleWithFalseConfirm" {
        $version = "2.0"
        New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"
        Publish-Module -Path $script:PublishModuleBase -NuGetApiKey $script:ApiKey -ReleaseNotes "$script:PublishModuleName release notes" -Tags PSGet -LicenseUri "https://$script:PublishModuleName.com/license" -ProjectUri "https://$script:PublishModuleName.com" -Confirm:$false -WarningAction SilentlyContinue
        $psgetItemInfo = Find-Module $script:PublishModuleName -RequiredVersion $version
        Assert ($psgetItemInfo.Name -eq $script:PublishModuleName) "Publish-Module should publish a module with valid module path, $($psgetItemInfo.Name)"
    }

    It 'PublishModuleWithForceAndConfirm' {
        $version = "2.0"
        New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"
        Publish-Module -Path $script:PublishModuleBase -NuGetApiKey $script:ApiKey -ReleaseNotes "$script:PublishModuleName release notes" -Tags PSGet -LicenseUri "https://$script:PublishModuleName.com/license" -ProjectUri "https://$script:PublishModuleName.com" -Force -Confirm -WarningAction SilentlyContinue
        $psgetItemInfo = Find-Module $script:PublishModuleName -RequiredVersion $version
        Assert ($psgetItemInfo.Name -eq $script:PublishModuleName) "Publish-Module should publish a module with valid module path, $($psgetItemInfo.Name)"
    }

    It 'PublishModuleWithForceAndWhatIf' {
        $version = "2.0"
        New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"
        Publish-Module -Path $script:PublishModuleBase -NuGetApiKey $script:ApiKey -ReleaseNotes "$script:PublishModuleName release notes" -Tags PSGet -LicenseUri "https://$script:PublishModuleName.com/license" -ProjectUri "https://$script:PublishModuleName.com" -Force -WhatIf -WarningAction SilentlyContinue
        $psgetItemInfo = Find-Module $script:PublishModuleName -RequiredVersion $version
        Assert ($psgetItemInfo.Name -eq $script:PublishModuleName) "Publish-Module should publish a module with valid module path, $($psgetItemInfo.Name)"
    }

    It "PublishModuleWithoutNugetExeAndNoToPrompt" {
        try {
            
            Remove-NuGetExe

            $outputPath = $script:TempPath
            $guid = [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            
            $Global:proxy.UI.ChoiceToMake = 1
            $content = $null

            $version = "1.0"
            New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"

            
            Copy-Item $script:PublishModuleBase $script:ProgramFilesModulesPath -Recurse -Force
            $err = $null

            try {
                $result = ExecuteCommand $runspace "Publish-Module -Name $script:PublishModuleName"
            }
            catch {
                $err = $_
            }
            finally {
                $fileName = "PromptForChoice-0.txt"
                $path = join-path $outputFilePath $fileName
                if (Test-Path $path) {
                    $content = get-content $path
                }

                CloseRunSpace $runspace
                RemoveItem $outputFilePath
            }

            Assert ($err -and $err.Exception.Message.Contains('NuGet.exe')) "Prompt for installing nuget binaries is not working, $err"
            Assert ($content -and $content.Contains('NuGet.exe')) "Prompt for installing nuget binaries is not working, $content"

            AssertFullyQualifiedErrorIdEquals -Scriptblock {Find-Module $script:PublishModuleName -RequiredVersion $version}`
                -ExpectedFullyQualifiedErrorId 'NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.FindPackage'
        }
        finally {
            Install-NuGetBinaries
        }
    } `
    -Skip:$(($PSCulture -ne 'en-US') -or ($PSEdition -eq 'Core') -or ($env:APPVEYOR_TEST_PASS -eq 'True') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0"))

    It "PublishModuleWithoutNugetExeAndYesToPrompt" {
        try {
            
            Remove-NuGetExe

            $outputPath = $script:TempPath
            $guid = [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            
            $Global:proxy.UI.ChoiceToMake = 0
            $content = $null

            $version = "1.0.0"
            New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"

            
            Copy-Item $script:PublishModuleBase $script:ProgramFilesModulesPath -Recurse -Force
            try {
                $result = ExecuteCommand $runspace "Publish-Module -Name $script:PublishModuleName"
            }
            finally {
                $fileName = "PromptForChoice-0.txt"
                $path = join-path $outputFilePath $fileName
                if (Test-Path $path) {
                    $content = get-content $path
                }

                CloseRunSpace $runspace
                RemoveItem $outputFilePath
            }

            Assert ($content -and $content.Contains('NuGet.exe')) "Prompt for installing nuget binaries is not working, $content"
            $psgetItemInfo = Find-Module $script:PublishModuleName -RequiredVersion $version
            Assert (($psgetItemInfo.Name -eq $script:PublishModuleName) -and (($psgetItemInfo.Version.ToString() -eq $version))) "Publish-Module should publish a module with valid module name, $($psgetItemInfo.Name)"
        }
        finally {
            Install-NuGetBinaries
        }
    } `
    -Skip:$(($PSCulture -ne 'en-US') -or ($PSEdition -eq 'Core') -or ($env:APPVEYOR_TEST_PASS -eq 'True') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0"))

    
    
    
    
    
    
    It "PublishNotAvailableModule" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Module -Name NotAvailableModule -NuGetApiKey $script:ApiKey} `
                                          -expectedFullyQualifiedErrorId "ModuleNotAvailableLocallyToPublish,Publish-Module"
    }

    
    
    
    
    
    
    It PublishModuleToWebbasedGalleryWithoutNuGetApiKey {
        try {
            Register-PSRepository -Name '_TempTestRepo_' -SourceLocation 'https://www.poshtestgallery.com'

            $version = "1.0"
            New-ModuleManifest -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"  -NestedModules "$script:PublishModuleName.psm1"
            AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Module -Path $script:PublishModuleBase -Repository '_TempTestRepo_'} `
                                              -expectedFullyQualifiedErrorId 'NuGetApiKeyIsRequiredForNuGetBasedGalleryService,Publish-Module'
        }
        finally {
            Get-PSRepository -Name '_TempTestRepo_' -ErrorAction SilentlyContinue | Unregister-PSRepository
        }
    }

    
    
    
    
    
    
    It "PublishInvalidModule" {
        $tempmodulebase = Join-Path (Join-Path $script:TempPath "$(Get-Random)") "InvalidModule"
        $null = New-Item $tempmodulebase -Force -ItemType Directory

        try
        {
            AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Module -Path $tempmodulebase -NuGetApiKey $script:ApiKey} `
                                              -expectedFullyQualifiedErrorId 'InvalidModulePathToPublish,Publish-Module'

            Set-Content (Join-Path $tempmodulebase InvalidModule.psm1) -Value "function foo {'foo'}"

            if($PSVersionTable.PSVersion -ge '5.0.0')
            {
                $errorId = 'InvalidModuleToPublish,Publish-Module'
            }
            else
            {
                $errorId = 'InvalidModulePathToPublish,Publish-Module'
            }

            AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Module -Path $tempmodulebase -NuGetApiKey $script:ApiKey} `
                                              -expectedFullyQualifiedErrorId $errorId

        }
        finally
        {
            RemoveItem -path $tempmodulebase
        }
    }

    
    
    
    
    
    
    It "PublishInvalidModuleFilePath" {
        $tempmodulebase = Join-Path (Join-Path $script:TempPath "$(Get-Random)") "InvalidModule"
        $null = New-Item $tempmodulebase -Force -ItemType Directory
        $moduleFilePath = Join-Path $tempmodulebase "InvalidModule.psm1"
        Set-Content $moduleFilePath -Value "function foo {'foo'}"

        try
        {
            AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Module -Path $moduleFilePath -NuGetApiKey $script:ApiKey} `
                                              -expectedFullyQualifiedErrorId "PathIsNotADirectory,Publish-Module"
        }
        finally
        {
            RemoveItem -path $tempmodulebase
        }
    }

    
    
    
    
    
    
    It "PublishInvalidModuleFilePathToPSD1" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Module -Path (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psd1") -NuGetApiKey $script:ApiKey} `
                                          -expectedFullyQualifiedErrorId 'PathNotFound,Publish-Module'
    }

    
    
    
    
    
    
    It PublishModuleWithoutDescriptionAndAuthor {
        $ModuleName = "ModuleWithoutDescriptAndAuthor"
        $ModuleBase = Join-Path $script:TempModulesPath $ModuleName
        $null = New-Item -Path $ModuleBase -ItemType Directory -Force
        $version = "1.0"
        New-ModuleManifest -Path (Join-Path -Path $ModuleBase -ChildPath "$ModuleName.psd1") -ModuleVersion $version

        try
        {
            AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Module -Path $ModuleBase -NuGetApiKey $script:ApiKey} `
                                              -expectedFullyQualifiedErrorId "MissingRequiredModuleManifestKeys,Publish-Module"
        }
        catch
        {
            RemoveItem -path $ModuleBase
        }
    }

    
    
    
    
    
    
    It PublishModuleWithInvalidLicenseUri {
        $ModuleName = "TempModule"
        $ModuleBase = Join-Path $script:TempModulesPath $ModuleName
        $null = New-Item -Path $ModuleBase -ItemType Directory -Force
        $version = "1.0"
        New-ModuleManifest -Path (Join-Path -Path $ModuleBase -ChildPath "$ModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"

        try
        {
            AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Module -Path $ModuleBase -NuGetApiKey $script:ApiKey -LicenseUri "\\ma"} `
                                              -expectedFullyQualifiedErrorId "InvalidWebUri,Publish-Module"
        }
        catch
        {
            RemoveItem -path $ModuleBase
        }
    }

    
    
    
    
    
    
    It PublishModuleWithInvalidIconUri {
        $ModuleName = "TempModule"
        $ModuleBase = Join-Path $script:TempModulesPath $ModuleName
        $null = New-Item -Path $ModuleBase -ItemType Directory -Force
        $version = "1.0"
        New-ModuleManifest -Path (Join-Path -Path $ModuleBase -ChildPath "$ModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"

        try
        {
            AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Module -Path $ModuleBase -NuGetApiKey $script:ApiKey -IconUri "\\localmachine\MyIcon.png" -WarningAction SilentlyContinue} `
                                              -expectedFullyQualifiedErrorId "InvalidWebUri,Publish-Module"
        }
        catch
        {
            RemoveItem -path $ModuleBase
        }
    }

    
    
    
    
    
    
    It PublishModuleWithInvalidProjectUri {
        $ModuleName = "TempModule"
        $ModuleBase = Join-Path $script:TempModulesPath $ModuleName
        $null = New-Item -Path $ModuleBase -ItemType Directory -Force
        $version = "1.0"
        New-ModuleManifest -Path (Join-Path -Path $ModuleBase -ChildPath "$ModuleName.psd1") -ModuleVersion $version -Description "$script:PublishModuleName module"

        try
        {
            AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Module -Path $ModuleBase -NuGetApiKey $script:ApiKey -ProjectUri "MyProject.com" -WarningAction SilentlyContinue} `
                                              -expectedFullyQualifiedErrorId "InvalidWebUri,Publish-Module"
        }
        catch
        {
            RemoveItem -path $ModuleBase
        }
    }

    
    
    
    
    
    
    
    
    It ValidateIncompatiblePSGetFormatVersion2 {

        $PSGetFormatVersion = [Version]'2.1'
        $moduleName = "TestMod_$(Get-Random)"

        CreateAndPublishTestModuleWithVersionFormat -ModuleName $moduleName `
                                                    -NuGetApiKey $script:ApiKey `
                                                    -Repository "PSGallery" `
                                                    -Versions @('1.0.0','2.0.0') `
                                                    -PSGetFormatVersion $PSGetFormatVersion `
                                                    -ModulesPath $script:TempModulesPath

        $psgetItemInfo = Find-Module -Name $moduleName -RequiredVersion '1.0'
        AssertNotNull $psgetItemInfo "Module without PowerShellGetFormatVersion is not found"
        AssertEquals $psgetItemInfo.PowerShellGetFormatVersion $PSGetFormatVersion "PowerShellGetFormatVersion property is not null, $($psgetItemInfo.PowerShellGetFormatVersion)"

        AssertFullyQualifiedErrorIdEquals -scriptblock {$psgetItemInfo | Install-Module} `
                                            -expectedFullyQualifiedErrorId "NotSupportedPowerShellGetFormatVersion,Install-Module"
    }

    
    
    
    
    
    
    
    It PublishModuleWithoutExternalModuleDependenciesInPSDataSection {
        $repoName = "PSGallery"
        $ModuleName = "ModuleWithExternalDependencies1"
        $RequiredModuleDep = 'RequiredModuleDep'
        $NestedModuleDep = 'NestedModuleDep'
        $ExternalRequiredModuleDep = 'ExternalRequiredModuleDep'
        $ExternalNestedModuleDep = 'ExternalNestedModuleDep'

        try
        {
            
            CreateAndPublishTestModule -ModuleName $RequiredModuleDep `
                                       -NuGetApiKey $script:ApiKey `
                                       -Repository $repoName `
                                       -Versions 1.0

            
            CreateAndPublishTestModule -ModuleName $NestedModuleDep `
                                       -NuGetApiKey $script:ApiKey `
                                       -Repository $repoName `
                                       -Versions 1.0

            
            $ModuleBase = Join-Path $script:TempModulesPath $ModuleName
            $null = New-Item -Path $ModuleBase -ItemType Directory -Force
            $version = "1.0"

            
            $RequiredModuleDep, $NestedModuleDep, $ExternalRequiredModuleDep, $ExternalNestedModuleDep | Foreach-Object {
                $DepModuleBase = Join-Path $script:ProgramFilesModulesPath $_
                $null = New-Item -Path $DepModuleBase -ItemType Directory -Force
                New-ModuleManifest -Path (Join-Path $DepModuleBase "$_.psd1") `
                                   -ModuleVersion '1.0' `
                                   -Description "$_ module"
            }


            $psd1Text = @"
                @{
                    Author = 'PowerShell Community and Tools team'
                    CompanyName = 'Microsoft Corporation'
                    Copyright = '(c) 2015 Microsoft. All rights reserved.'
                    FunctionsToExport = '*'
                    CmdletsToExport = '*'
                    VariablesToExport = '*'
                    AliasesToExport = '*'
                    ModuleVersion = '__VERSION__'
                    GUID = '$([System.Guid]::NewGuid())'
                    Description = 'Test module for external module dependecies'
                    RequiredModules = @('$($RequiredModuleDep)','$($ExternalRequiredModuleDep)')
                    NestedModules = @('$($NestedModuleDep)','$($ExternalNestedModuleDep)')

                    PrivateData = @{
                        PSData = @{
                            Tags = 'Tag1', 'Tag2'
                            LicenseUri = 'https://contoso.com/license'
                            ProjectUri = 'https://contoso.com/'
                            IconUri = 'https://contoso.com/icon'
                            ReleaseNotes = 'Test module for external module dependecies'
    	                    ExternalModuleDependencies = @()
                        }
                    }
                }
"@

            ($psd1Text -replace '__VERSION__',$version) | Out-File -FilePath (Join-Path -Path $ModuleBase -ChildPath "$ModuleName.psd1") -Force

            AssertFullyQualifiedErrorIdEquals -scriptblock { Publish-Module -Path $ModuleBase -Repository $repoName -NuGetApiKey $script:ApiKey} `
                                              -expectedFullyQualifiedErrorId 'UnableToResolveModuleDependency,Publish-PSArtifactUtility'
        }
        finally
        {
            $ModuleName, $RequiredModuleDep, $NestedModuleDep, $ExternalRequiredModuleDep, $ExternalNestedModuleDep | Foreach-Object { PSGetTestUtils\Uninstall-Module -Name $_ }
        }
    }
}

Describe PowerShell.PSGet.PublishModuleTests.P2 -Tags 'P2','OuterLoop' {
    
    
    if($IsMacOS -or $IsLinux) {
        return
    }

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    BeforeEach {
        Set-Content (Join-Path -Path $script:PublishModuleBase -ChildPath "$script:PublishModuleName.psm1") -Value "function Get-$script:PublishModuleName { Get-Date }"
    }

    AfterEach {
        RemoveItem "$script:PSGalleryRepoPath\*"
        RemoveItem "$script:ProgramFilesModulesPath\$script:PublishModuleName"
        RemoveItem "$script:PublishModuleBase\*"
    }

    
    
    
    
    
    
    
    
    It PublishModuleWithDependencies {
        $repoName = "PSGallery"
        $ModuleName = "ModuleWithDependencies1"

        $DepencyModuleNames = @("RequiredModule1",
                                "RequiredModule2"
                                )

        $RequiredModules1 = @('RequiredModule1',
                              @{ModuleName = 'RequiredModule2'; ModuleVersion = '1.5'; })

        $RequiredModules2 = @('RequiredModule1',
                              @{ModuleName = 'RequiredModule2'; ModuleVersion = '2.0'; })

        $NestedRequiredModules1 = @('NestedRequiredModule1',
                                    @{ModuleName = 'NestedRequiredModule2'; ModuleVersion = '1.5'; })

        $NestedRequiredModules2 = @('NestedRequiredModule1',
                                    @{ModuleName = 'NestedRequiredModule2'; ModuleVersion = '2.0'; })

        if($PSVersionTable.PSVersion -ge '5.0.0')
        {
            $DepencyModuleNames += @("RequiredModule3",
                                     "RequiredModule4",
                                     "RequiredModule5"
                                     )

            $RequiredModules1 += @{ModuleName = 'RequiredModule3'; RequiredVersion = '2.0'; }
            $RequiredModules2 += @{ModuleName = 'RequiredModule3'; RequiredVersion = '2.5'; }

            $RequiredModules1 += @{ModuleName = 'RequiredModule4'; ModuleVersion = '0.1'; MaximumVersion = '1.*'; }
            $RequiredModules2 += @{ModuleName = 'RequiredModule4'; ModuleVersion = '0.1'; MaximumVersion = '2.0'; }

            $NestedRequiredModules1 += @{ModuleName = 'NestedRequiredModule3'; RequiredVersion = '2.0'; }
            $NestedRequiredModules2 += @{ModuleName = 'NestedRequiredModule3'; RequiredVersion = '2.5'; }

            $NestedRequiredModules1 += @{ModuleName = 'NestedRequiredModule4'; ModuleVersion = '0.1'; MaximumVersion = '1.*'; }
            $NestedRequiredModules2 += @{ModuleName = 'NestedRequiredModule4'; ModuleVersion = '0.1'; MaximumVersion = '2.0'; }

            $RequiredModules1 += @{ModuleName = 'RequiredModule5'; MaximumVersion = '1.*'; }
            $RequiredModules2 += @{ModuleName = 'RequiredModule5'; MaximumVersion = '1.5'; }

            $NestedRequiredModules1 += @{ModuleName = 'NestedRequiredModule5'; MaximumVersion = '1.*'; }
            $NestedRequiredModules2 += @{ModuleName = 'NestedRequiredModule5'; MaximumVersion = '1.6'; }
        }

        
        CreateAndPublishTestModule -ModuleName "NestedRequiredModule1" -NuGetApiKey $script:ApiKey -Repository $repoName
        CreateAndPublishTestModule -ModuleName "NestedRequiredModule2" -NuGetApiKey $script:ApiKey -Repository $repoName
        CreateAndPublishTestModule -ModuleName "NestedRequiredModule3" -NuGetApiKey $script:ApiKey -Repository $repoName
        CreateAndPublishTestModule -ModuleName "NestedRequiredModule4" -NuGetApiKey $script:ApiKey -Repository $repoName
        CreateAndPublishTestModule -ModuleName "NestedRequiredModule5" -NuGetApiKey $script:ApiKey -Repository $repoName

        
        CreateAndPublishTestModule -ModuleName "RequiredModule1" -NuGetApiKey $script:ApiKey -Repository $repoName
        CreateAndPublishTestModule -ModuleName "RequiredModule2" -NuGetApiKey $script:ApiKey -Repository $repoName
        CreateAndPublishTestModule -ModuleName "RequiredModule3" -NuGetApiKey $script:ApiKey -Repository $repoName
        CreateAndPublishTestModule -ModuleName "RequiredModule4" -NuGetApiKey $script:ApiKey -Repository $repoName
        CreateAndPublishTestModule -ModuleName "RequiredModule5" -NuGetApiKey $script:ApiKey -Repository $repoName

        
        CreateAndPublishTestModule -ModuleName $ModuleName `
                                   -Version "1.0" `
                                   -NuGetApiKey $script:ApiKey `
                                   -Repository $repoName `
                                   -RequiredModules $RequiredModules1 `
                                   -NestedModules @()

        $res1 = Find-Module -Name $ModuleName -RequiredVersion "1.0"
        AssertEquals $res1.Name $ModuleName "Find-Module didn't find the exact module which has dependencies, $res1"

        $res2 = Find-Module -Name $ModuleName -IncludeDependencies -RequiredVersion "1.0"
        Assert ($res2.Count -ge ($DepencyModuleNames.Count+1)) "Find-Module with -IncludeDependencies returned wrong results, $res2"

        
        CreateAndPublishTestModule -ModuleName $ModuleName `
                                   -Version "2.0" `
                                   -NuGetApiKey $script:ApiKey `
                                   -Repository $repoName `
                                   -RequiredModules $RequiredModules2 `
                                   -NestedModules @()

        $res3 = Find-Module -Name $ModuleName -RequiredVersion "2.0"
        AssertEquals $res3.Name $ModuleName "Find-Module didn't find the exact module which has dependencies, $res3"

        $res4 = Find-Module -Name $ModuleName -IncludeDependencies -RequiredVersion "2.0"
        Assert ($res4.Count -ge ($DepencyModuleNames.Count+1)) "Find-Module with -IncludeDependencies returned wrong results, $res4"
    }

    
    
    
    
    
    
    
    It PublishModuleWithExternalDependencies {
        $repoName = "PSGallery"
        $ModuleName = "ModuleWithExternalDependencies1"
        $RequiredModuleDep = 'RequiredModuleDep'
        $NestedModuleDep = 'NestedModuleDep'
        $ExternalRequiredModuleDep = 'ExternalRequiredModuleDep'
        $ExternalNestedModuleDep = 'ExternalNestedModuleDep'

        try
        {
            
            CreateAndPublishTestModule -ModuleName $RequiredModuleDep `
                                       -NuGetApiKey $script:ApiKey `
                                       -Repository $repoName `
                                       -Versions 1.0.0

            
            CreateAndPublishTestModule -ModuleName $NestedModuleDep `
                                       -NuGetApiKey $script:ApiKey `
                                       -Repository $repoName `
                                       -Versions 1.0.0

            
            $ModuleBase = Join-Path $script:TempModulesPath $ModuleName
            $null = New-Item -Path $ModuleBase -ItemType Directory -Force
            $version = "1.0.0"

            
            $RequiredModuleDep, $NestedModuleDep, $ExternalRequiredModuleDep, $ExternalNestedModuleDep | Foreach-Object {
                $DepModuleBase = Join-Path $script:ProgramFilesModulesPath $_
                $null = New-Item -Path $DepModuleBase -ItemType Directory -Force
                New-ModuleManifest -Path (Join-Path $DepModuleBase "$_.psd1") `
                                   -ModuleVersion '1.0.0' `
                                   -Description "$_ module"
            }

            $psd1Text = @"
                @{
                    Author = 'PowerShell Community and Tools team'
                    CompanyName = 'Microsoft Corporation'
                    Copyright = '(c) 2015 Microsoft. All rights reserved.'
                    FunctionsToExport = @()
                    CmdletsToExport = '*'
                    VariablesToExport = '*'
                    AliasesToExport = '*'
                    ModuleVersion = '__VERSION__'
                    GUID = '$([System.Guid]::NewGuid())'
                    Description = 'Test module for external module dependecies'
                    RequiredModules = @('$($RequiredModuleDep)','$($ExternalRequiredModuleDep)')
                    NestedModules = @('$($NestedModuleDep)','$($ExternalNestedModuleDep)')

                    PrivateData = @{
                        PSData = @{
                            Tags = 'Tag1', 'Tag2'
                            LicenseUri = 'https://contoso.com/license'
                            ProjectUri = 'https://contoso.com/'
                            IconUri = 'https://contoso.com/icon'
                            ReleaseNotes = 'Test module for external module dependecies'
    	                    ExternalModuleDependencies = @('$($ExternalRequiredModuleDep)', '$($ExternalNestedModuleDep)')
                        }
                    }
                }
"@

            ($psd1Text -replace '__VERSION__',$version) | Out-File -FilePath (Join-Path -Path $ModuleBase -ChildPath "$ModuleName.psd1") -Force

            Publish-Module -Path $ModuleBase -Repository $repoName -NuGetApiKey $script:ApiKey

            $res1 = Find-Module -Name $ModuleName -RequiredVersion $version -Repository $repoName
            AssertEquals $res1.Name $ModuleName "Find-Module didn't find the exact module which has dependencies, $res1"

            
            $version = '2.0.0'
            ($psd1Text -replace '__VERSION__',$version) | Out-File -FilePath (Join-Path -Path $ModuleBase -ChildPath "$ModuleName.psd1") -Force
            Publish-Module -Path $ModuleBase -Repository $repoName -NuGetApiKey $script:ApiKey

            $res2 = Find-Module -Name $ModuleName -RequiredVersion $version -Repository $repoName
            AssertEquals $res2.Name $ModuleName "Find-Module didn't find the exact module which has dependencies, $res2"
        }
        finally
        {
            $ModuleName, $RequiredModuleDep, $NestedModuleDep | Foreach-Object { PSGetTestUtils\Uninstall-Module -Name $_ }
        }

        try
        {
            
            $version = '1.0.0'
            $wa = $null
            Install-Module -Name $ModuleName -RequiredVersion $version -Repository $repoName -WarningVariable wa -WarningAction SilentlyContinue
            AssertEquals $wa.Count 0 "No warning messages are expected when installing a module whose external dependencies are pre-installed. $wa"

            $module1 = Get-InstalledModule -Name $ModuleName -RequiredVersion $version
            Assert ($module1 -and ($module1.Name -eq $ModuleName)) "$ModuleName is not installed properly when it's external dependencies are pre-installed. $module1"

            $wa = $null
            $version = '2.0.0'
            Update-Module -Name $ModuleName -RequiredVersion $version -WarningVariable wa -WarningAction SilentlyContinue
            AssertEquals $wa.Count 0 "No warning messages are expected when updating a module whose external dependencies are pre-installed. $wa"

            $module2 = Get-InstalledModule -Name $ModuleName -RequiredVersion $version
            Assert ($module2 -and ($module2.Name -eq $ModuleName)) "$ModuleName is not updated properly when it's external dependencies are pre-installed. $module2"
        }
        finally
        {
            $ModuleName, $RequiredModuleDep, $NestedModuleDep, $ExternalRequiredModuleDep, $ExternalNestedModuleDep | Foreach-Object { PSGetTestUtils\Uninstall-Module -Name $_ }
        }

        
        if($PSVersionTable.PSVersion -ge '5.0.0')
        {
            try
            {
                
                $version = '1.0.0'
                Install-Module -Name $ModuleName -RequiredVersion $version -Repository $repoName -WarningVariable wa -WarningAction SilentlyContinue
                Assert ($wa.Count -ge 2) "Two warning messages are expected (Actual count: $($wa.Count)) when installing a module whose external dependencies are not preinstalled. $wa"
                Assert ("$wa".Contains($ExternalRequiredModuleDep)) "Warning message for $ExternalRequiredModuleDep is not returned, $wa"
                Assert ("$wa".Contains($ExternalNestedModuleDep)) "Warning message for $ExternalNestedModuleDep is not returned, $wa"

                $module1 = Get-InstalledModule -Name $ModuleName -RequiredVersion $version
                Assert ($module1 -and ($module1.Name -eq $ModuleName)) "$ModuleName is not installed properly when it's external dependencies are not pre-installed. $module1"

                $wa = $null
                $version = '2.0.0'
                Update-Module -Name $ModuleName -RequiredVersion $version -WarningVariable wa -WarningAction SilentlyContinue
                Assert ($wa.Count -ge 2) "Two warning messages are expected (Actual count: $($wa.Count)) when updating a module whose external dependencies are not preinstalled. $wa"
                Assert ("$wa".Contains($ExternalRequiredModuleDep)) "During update module, warning message for $ExternalRequiredModuleDep is not returned, $wa"
                Assert ("$wa".Contains($ExternalNestedModuleDep)) "During update module, warning message for $ExternalNestedModuleDep is not returned, $wa"

                $module2 = Get-InstalledModule -Name $ModuleName -RequiredVersion $version
                Assert ($module2 -and ($module2.Name -eq $ModuleName)) "$ModuleName is not updated properly when it's external dependencies are pre-installed. $module2"
            }
            finally
            {
                $ModuleName, $RequiredModuleDep, $NestedModuleDep, $ExternalRequiredModuleDep, $ExternalNestedModuleDep | Foreach-Object { PSGetTestUtils\Uninstall-Module -Name $_ }
            }
        }
    }
}
