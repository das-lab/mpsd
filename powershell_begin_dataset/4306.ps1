



function SuiteSetup {
    Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue
    Import-Module "$PSScriptRoot\Asserts.psm1" -WarningAction SilentlyContinue

    $script:MyDocumentsModulesPath = Get-CurrentUserModulesPath
    $script:PSGetLocalAppDataPath = Get-PSGetLocalAppDataPath
    $script:TempPath = Get-TempPath

    
    Install-NuGetBinaries

    $psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
    Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $psgetModuleInfo.ModuleBase

    $script:moduleSourcesFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml"
    $script:moduleSourcesBackupFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml_$(get-random)_backup"
    if (Test-Path $script:moduleSourcesFilePath) {
        Rename-Item $script:moduleSourcesFilePath $script:moduleSourcesBackupFilePath -Force
    }

    GetAndSet-PSGetTestGalleryDetails -SetPSGallery

    PSGetTestUtils\Uninstall-Module ContosoServer
    PSGetTestUtils\Uninstall-Module ContosoClient

}

function SuiteCleanup {
    if (Test-Path $script:moduleSourcesBackupFilePath) {
        Move-Item $script:moduleSourcesBackupFilePath $script:moduleSourcesFilePath -Force
    }
    else {
        RemoveItem $script:moduleSourcesFilePath
    }

    
    $null = Import-PackageProvider -Name PowerShellGet -Force
}

Describe UpdateModuleFromAlternateRepo -Tags 'BVT' {
    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    AfterEach {
        PSGetTestUtils\Uninstall-Module ContosoServer
        PSGetTestUtils\Uninstall-Module ContosoClient
    }

    It "Check that removing a slash from a repo doesn't break update" {
        $withSlash = "https://www.poshtestgallery.com/api/v2/"
        $noSlash = "https://www.poshtestgallery.com/api/v2"
        
        (Get-PSRepository PSGallery).SourceLocation | Should Be $withSlash

        Install-Module ContosoServer -RequiredVersion 1.0
        (Get-InstalledModule ContosoServer).RepositorySourceLocation | Should Be $withSlash
        

        
        Set-PSGallerySourceLocation -Location $noSlash
        
        (Get-PSRepository PSGallery).SourceLocation | Should Be $noSlash

        
        Import-Module PowerShellGet -Force

        
        Update-Module ContosoServer -RequiredVersion 2.0 -ErrorAction Stop
        
        (Get-InstalledModule ContosoServer).RepositorySourceLocation | Should Be $noSlash
        (Get-InstalledModule ContosoServer).Version | Should Be 2.0
    }

    It "Check that adding a slash to a repo doesn't break update" {
        $withSlash = "https://www.poshtestgallery.com/api/v2/"
        $noSlash = "https://www.poshtestgallery.com/api/v2"
        

        Set-PSGallerySourceLocation -Location $noSlash

        (Get-PSRepository PSGallery).SourceLocation | Should Be $noSlash

        Install-Module ContosoServer -RequiredVersion 1.0
        (Get-InstalledModule ContosoServer).RepositorySourceLocation | Should Be $noSlash
        

        
        Set-PSGallerySourceLocation -Location $withSlash
        
        (Get-PSRepository PSGallery).SourceLocation | Should Be $withSlash

        
        Import-Module PowerShellGet -Force

        
        Update-Module ContosoServer -RequiredVersion 2.0 -ErrorAction Stop
        
        (Get-InstalledModule ContosoServer).RepositorySourceLocation | Should Be $withSlash
        (Get-InstalledModule ContosoServer).Version | Should Be 2.0
    }
}

Describe UpdateModuleFromAlternateRepo -Tags 'BVT' {
    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    AfterEach {
        PSGetTestUtils\Uninstall-Module ContosoServer
        PSGetTestUtils\Uninstall-Module ContosoClient
    }

    It "Check that removing a slash from a repo doesn't break update" {
        $withSlash = "https://www.poshtestgallery.com/api/v2/"
        $noSlash = "https://www.poshtestgallery.com/api/v2"
        
        (Get-PSRepository PSGallery).SourceLocation | Should Be $withSlash

        Install-Module ContosoServer -RequiredVersion 1.0
        (Get-InstalledModule ContosoServer).RepositorySourceLocation | Should Be $withSlash
        

        
        Set-PSGallerySourceLocation -Location $noSlash
        
        (Get-PSRepository PSGallery).SourceLocation | Should Be $noSlash

        
        Import-Module PowerShellGet -Force

        
        Update-Module ContosoServer -RequiredVersion 2.0 -ErrorAction Stop
        
        (Get-InstalledModule ContosoServer).RepositorySourceLocation | Should Be $noSlash
        (Get-InstalledModule ContosoServer).Version | Should Be 2.0
    }

    It "Check that adding a slash to a repo doesn't break update" {
        $withSlash = "https://www.poshtestgallery.com/api/v2/"
        $noSlash = "https://www.poshtestgallery.com/api/v2"
        

        Set-PSGallerySourceLocation -Location $noSlash

        (Get-PSRepository PSGallery).SourceLocation | Should Be $noSlash

        Install-Module ContosoServer -RequiredVersion 1.0
        (Get-InstalledModule ContosoServer).RepositorySourceLocation | Should Be $noSlash
        

        
        Set-PSGallerySourceLocation -Location $withSlash
        
        (Get-PSRepository PSGallery).SourceLocation | Should Be $withSlash

        
        Import-Module PowerShellGet -Force

        
        Update-Module ContosoServer -RequiredVersion 2.0 -ErrorAction Stop
        
        (Get-InstalledModule ContosoServer).RepositorySourceLocation | Should Be $withSlash
        (Get-InstalledModule ContosoServer).Version | Should Be 2.0
    }
}

Describe PowerShell.PSGet.UpdateModuleTests -Tags 'BVT', 'InnerLoop' {

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    AfterEach {
        PSGetTestUtils\Uninstall-Module ContosoServer
        PSGetTestUtils\Uninstall-Module ContosoClient
    }

    
    
    
    
    
    
    It "UpdateModuleWithWhatIf" {
        $installedVersion = "1.0"
        Install-Module ContosoServer -RequiredVersion $installedVersion

        $outputPath = $script:TempPath
        $guid = [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1
        $content = $null

        try {
            $result = ExecuteCommand $runspace 'Import-Module PowerShellGet -Global -Force; Update-Module ContosoServer -WhatIf'
        }
        finally {
            $fileName = "WriteLine-0.txt"
            $path = join-path $outputFilePath $fileName
            if (Test-Path $path) {
                $content = get-content $path
            }

            CloseRunSpace $runspace
            RemoveItem $outputFilePath
        }

        $itemInfo = Find-Module ContosoServer -Repository PSGallery
        $shouldProcessMessage = ($LocalizedData.UpdateModulewhatIfMessage -replace "__OLDVERSION__", $installedVersion)
        $shouldProcessMessage = ($shouldProcessMessage -f ($itemInfo.Name, $itemInfo.Version))
        Assert ($content -and ($content -match $shouldProcessMessage)) "update module whatif message is missing, Expected:$shouldProcessMessage, Actual:$content"

        $res = Get-Module ContosoServer -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ContosoServer") -and ($res.Version -eq [Version]"1.0")) "Update-Module should not update the module with -WhatIf option"
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ($PSCulture -ne 'en-US') -or ([System.Environment]::OSVersion.Version -lt '6.2.9200.0'))

    
    
    
    
    
    
    It "UpdateModuleWithFalseConfirm" {
        Install-Module -Name ContosoServer -RequiredVersion 1.0
        Update-Module ContosoServer -Confirm:$false

        if (Test-ModuleSxSVersionSupport) {
            $res = Get-Module -FullyQualifiedName @{ModuleName = 'ContosoServer'; ModuleVersion = '1.1' } -ListAvailable
        }
        else {
            $res = Get-Module ContosoServer -ListAvailable
        }

        Assert (($res.Count -eq 1) -and ($res.Name -eq "ContosoServer") -and ($res.Version -gt [Version]"1.0")) "Update-Module should update the module if -Confirm option is false"
    }


    
    
    
    
    
    
    It "UpdateModuleWithForce" {
        Install-Module -Name ContosoServer
        $res1 = Get-Module Contososerver -ListAvailable

        $MyError = $null
        Update-Module ContosoSeRVer -Force -ErrorVariable MyError
        Assert ($MyError.Count -eq 0) "There should not be any error from force update, $MyError"

        $res2 = Get-Module ContosoServer -ListAvailable
        Assert (($res1.Name -eq $res2.Name) -and ($res1.Version -eq $res2.Version)) "Update-Module with force should not change the version"
    }


    
    
    
    
    
    
    It "UpdateMultipleModulesWithReqVersion" {
        Install-Module ContosoClient, ContosoServer

        AssertFullyQualifiedErrorIdEquals -scriptblock { Update-Module ContosoClient, ContosoServer -RequiredVersion 3.0 } `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Update-Module"
    }


    
    
    
    
    
    
    It "UpdateModulesWithReqVersionAndWildcard" {
        Install-Module ContosoServer

        AssertFullyQualifiedErrorIdEquals -scriptblock { Update-Module Conto*erver -RequiredVersion 3.0 } `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Update-Module"
    }


    
    
    
    
    
    
    It "UpdateModuleWithWildcardName" {
        Install-Module ContosoServer -RequiredVersion 1.0
        Update-Module "Co[nN]t?soS[a-z]r?er"

        $res = Get-Module ContosoServer -ListAvailable
        Assert ($res.Name -eq "ContosoServer" -and $res.Version -gt [Version]"1.0")  "Update-Module with wildcard name should update the module"
    }

    
    
    
    
    
    
    It "UpdateNotInstalledModule" {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Update-Module ModuleNotInstalled } `
            -expectedFullyQualifiedErrorId "ModuleNotInstalledOnThisMachine,Update-Module"
    }


    
    
    
    
    
    
    It "UpdateAModuleNotInstalledUsingPSGet" {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Update-Module PSWorkflow } `
            -expectedFullyQualifiedErrorId "ModuleNotInstalledUsingInstallModuleCmdlet,Update-Module"
    }


    
    
    
    
    
    
    It "Update-Module should be silent" {
        Install-Module ContosoServer -RequiredVersion 1.0
        $result = Update-Module ContosoServer
        $result | Should -BeNullOrEmpty
    }


    
    
    
    
    
    
    It "Update-Module should return output" {
        Install-Module ContosoServer -RequiredVersion 1.0
        $result = Update-Module ContosoServer -PassThru
        $result | Should -Not -BeNullOrEmpty
    }


    
    
    
    
    
    
    It "UpdateModuleWithReqVersion" {
        Install-Module ContosoServer -RequiredVersion 1.0
        Update-Module ContosoServer -RequiredVersion 2.0

        if (Test-ModuleSxSVersionSupport) {
            $res = Get-Module -FullyQualifiedName @{ModuleName = 'ContosoServer'; RequiredVersion = '2.0' } -ListAvailable
        }
        else {
            $res = Get-Module ContosoServer -ListAvailable
        }

        Assert ($res.Name -eq "ContosoServer" -and $res.Version -eq [Version]"2.0")  "Update-Module should update the module with RequiredVersion"
    }

    
    
    
    
    
    
    It "UpdateModuleWithReqVersionAndForceToDowngradeVersion" {
        Install-Module ContosoServer
        Update-Module ContosoServer -RequiredVersion 1.0 -Force

        if (Test-ModuleSxSVersionSupport) {
            $res = Get-Module -FullyQualifiedName @{ModuleName = 'ContosoServer'; RequiredVersion = '1.0' } -ListAvailable
        }
        else {
            $res = Get-Module ContosoServer -ListAvailable
        }

        Assert ($res.Name -eq "ContosoServer" -and $res.Version -eq [Version]"1.0")  "Update-Module should downgrade the module version with -RequiredVersion and -Force"
    }

    
    
    
    
    
    
    It "UpdateModuleWithLowerReqVersionShouldNotUpdate" {
        Install-Module ContosoServer
        Update-Module ContosoServer -RequiredVersion 1.0
        $res = Get-Module ContosoServer -ListAvailable
        Assert ($res.Name -eq "ContosoServer" -and $res.Version -gt [Version]"1.0")  "Update-Module should not downgrade the module version with -RequiredVersion, Name: $($res.Name), Version: $($res.Version)"
    }

    
    
    
    
    
    
    It "UpdateMultipleModules" {
        Install-Module ContosoClient -RequiredVersion 1.0
        Install-Module ContosoServer -RequiredVersion 1.0
        Update-Module ContosoClient, ContosoServer

        if (Test-ModuleSxSVersionSupport) {
            $res = Get-Module -ListAvailable -FullyQualifiedName @{ModuleName = "ContosoServer"; ModuleVersion = "1.1" }, @{ModuleName = "ContosoClient"; ModuleVersion = "1.1" }
        }
        else {
            $res = Get-Module -ListAvailable -Name ContosoServer, ContosoClient
        }

        Assert (($res.Count -eq 2) -and ($res[0].Version -gt [Version]"1.0") -and ($res[1].Version -gt [Version]"1.0")) "Multiple module should be updated"
    }


    
    
    
    
    
    
    
    It "UpdateAllModules" {
        Install-Module ContosoClient -RequiredVersion 1.0
        Install-Module ContosoServer -RequiredVersion 1.0
        Update-Module -ErrorVariable err -ErrorAction SilentlyContinue
        
        $err | ? { $_.FullyQualifiedErrorId -notmatch "SourceNotFound" } | % { Write-Error $_ }

        if (Test-ModuleSxSVersionSupport) {
            $res = Get-Module -ListAvailable -FullyQualifiedName @{ModuleName = "ContosoServer"; ModuleVersion = "1.1" }, @{ModuleName = "ContosoClient"; ModuleVersion = "1.1" }
        }
        else {
            $res = Get-Module -ListAvailable -Name ContosoServer, ContosoClient
        }

        Assert (($res.Count -eq 2) -and ($res[0].Version -gt [Version]"1.0") -and ($res[1].Version -gt [Version]"1.0")) "Multiple module should be updated"
    }
}

Describe PowerShell.PSGet.UpdateModuleTests.P1 -Tags 'P1', 'OuterLoop' {
    
    
    if ($IsMacOS) {
        return
    }

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    AfterEach {
        PSGetTestUtils\Uninstall-Module ContosoServer
        PSGetTestUtils\Uninstall-Module ContosoClient
    }

    
    
    
    
    
    
    It "UpdateMultipleModulesWithWildcard" {

        Install-Module ContosoClient -RequiredVersion 1.0

        $contosoClientDetails = Get-InstalledModule -Name ContosoClient

        Install-Module ContosoServer -RequiredVersion 1.0

        $MyError = $null
        $DateTimeBeforeUpdate = Get-Date

        Update-Module Contoso* -Force -ErrorVariable MyError

        Assert ($MyError.Count -eq 0) "There should not be any error when updating multiple modules with wildcard in name, $MyError"
        $res = Get-InstalledModule -Name ContosoServer -MinimumVersion "1.1"
        Assert ($res -and ($res.Name -eq "ContosoServer") -and ($res.Version -gt [Version]"1.0")) "Update-Module should update when wildcard specified in name"

        $res = Get-InstalledModule -Name ContosoClient -MinimumVersion "1.1"
        Assert ($res -and ($res.Name -eq "ContosoClient") -and ($res.Version -gt [Version]"1.0")) "Update-Module should update when wildcard specified in name"

        AssertEquals $res.InstalledDate $contosoClientDetails.InstalledDate "InstalledDate should be same for the updated version"
        Assert ($res.UpdatedDate.AddSeconds(1) -ge $DateTimeBeforeUpdate) "Get-InstalledModule results are not expected, UpdatedDate $($res.UpdatedDate.Ticks) should be after $($DateTimeBeforeUpdate.Ticks)"
    }

    
    
    
    
    
    
    It "UpdateModuleWithNotAvailableReqVersion" {
        Install-Module ContosoServer -RequiredVersion 1.0

        $expectedFullyQualifiedErrorId = 'NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'

        AssertFullyQualifiedErrorIdEquals -scriptblock { Update-Module ContosoServer -RequiredVersion 10.0 } `
            -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }

    
    
    
    
    
    
    It "UpdateMultipleModulesWithForce" {
        Install-Module ContosoClient, ContosoServer
        $MyError = $null
        Update-Module ContosoClient, ContosoServer -Force -ErrorVariable MyError
        Assert ($MyError.Count -eq 0) "There should not be any error from force update for multiple modules, $MyError"
        $res = Get-Module ContosoServer -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ContosoServer") -and ($res.Version -gt [Version]"1.0")) "Update-Module should update when multiple modules are specified"
        $res = Get-Module ContosoClient -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ContosoClient") -and ($res.Version -gt [Version]"1.0")) "Update-Module should update when multiple modules are specified"
    }

    
    
    
    
    
    
    It "UpdateModuleUnderCurrentUserScope" {
        Install-Module ContosoServer -Scope CurrentUser -RequiredVersion 1.0
        Update-Module ContosoServer

        if (Test-ModuleSxSVersionSupport) {
            $res = Get-Module -ListAvailable -FullyQualifiedName @{ModuleName = "ContosoServer"; ModuleVersion = "1.1" }
        }
        else {
            $res = Get-Module ContosoServer -ListAvailable
        }

        Assert (($res.Count -eq 1) -and ($res.Name -eq "ContosoServer") -and ($res.Version -gt [Version]"1.0")) "Update-Module should update the module installed to current user scope, $res"
        Assert $res.ModuleBase.StartsWith($script:MyDocumentsModulesPath) "Update-Module should update the module installed to current user scope, updated module base: $($res.ModuleBase)"
    }
}

Describe PowerShell.PSGet.UpdateModuleTests.P2 -Tags 'P2', 'OuterLoop' {

    
    
    if ($IsMacOS) {
        return
    }

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    AfterEach {
        PSGetTestUtils\Uninstall-Module ContosoServer
        PSGetTestUtils\Uninstall-Module ContosoClient
    }

    
    
    
    
    
    
    It "UpdateModuleWithConfirmAndNoToPrompt" {
        $installedVersion = "1.0"
        Install-Module ContosoServer -RequiredVersion $installedVersion
        $installedVersion = "1.5"
        Install-Module ContosoServer -RequiredVersion $installedVersion -Force
        $outputPath = $script:TempPath
        $guid = [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        
        $Global:proxy.UI.ChoiceToMake = 2
        $content = $null

        try {
            $result = ExecuteCommand $runspace 'Import-Module PowerShellGet -Global -Force; Update-Module ContosoServer -Confirm'
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

        $itemInfo = Find-Module ContosoServer -Repository PSGallery
        $shouldProcessMessage = ($LocalizedData.UpdateModulewhatIfMessage -replace "__OLDVERSION__", $installedVersion)
        $shouldProcessMessage = ($shouldProcessMessage -f ($itemInfo.Name, $itemInfo.Version))
        Assert ($content -and ($content -match $shouldProcessMessage)) "update module confirm prompt is not working, Expected:$shouldProcessMessage, Actual:$content"

        $res = Get-InstalledModule -Name ContosoServer
        Assert (($res.Name -eq "ContosoServer") -and ($res.Version -eq ([Version]$installedVersion))) "Update-Module should not update the ContosoServer module when pressed NO to Confirm."
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ($PSCulture -ne 'en-US') -or ([System.Environment]::OSVersion.Version -lt '6.2.9200.0'))

    
    
    
    
    
    
    It "UpdateModuleWithConfirmAndYesToPrompt" {
        $installedVersion = "1.0"
        Install-Module ContosoServer -RequiredVersion $installedVersion
        $outputPath = $script:TempPath
        $guid = [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        
        $Global:proxy.UI.ChoiceToMake = 0
        $content = $null

        try {
            $result = ExecuteCommand $runspace 'Import-Module PowerShellGet -Global -Force; Update-Module ContosoServer -Confirm'
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

        $itemInfo = Find-Module ContosoServer -Repository PSGallery
        $shouldProcessMessage = ($LocalizedData.UpdateModulewhatIfMessage -replace "__OLDVERSION__", $installedVersion)
        $shouldProcessMessage = ($shouldProcessMessage -f ($itemInfo.Name, $itemInfo.Version))
        Assert ($content -and ($content -match $shouldProcessMessage)) "update module confirm prompt is not working, Expected:$shouldProcessMessage, Actual:$content"

        if (Test-ModuleSxSVersionSupport) {
            $res = Get-Module -FullyQualifiedName @{ModuleName = 'ContosoServer'; ModuleVersion = '1.1' } -ListAvailable
        }
        else {
            $res = Get-Module ContosoServer -ListAvailable
        }

        Assert (($res.Count -eq 1) -and ($res.Name -eq "ContosoServer") -and ($res.Version -gt [Version]"1.0")) "Update-Module should not update the ContosoServer module when pressed NO to Confirm."
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ($PSCulture -ne 'en-US') -or ([System.Environment]::OSVersion.Version -lt '6.2.9200.0'))

    
    
    
    
    
    
    It "AdminPrivilegesAreNotRequiredForUpdatingAllUsersModule" {
        Install-Module -Name ContosoServer -RequiredVersion 1.0
        $content = Invoke-WithoutAdminPrivileges (@'
Import-Module "{0}\PowerShellGet.psd1" -Force
Update-Module -Name ContosoServer
'@ -f (Get-Module PowerShellGet).ModuleBase)

        $updatedModule = Get-InstalledModule ContosoServer
        Assert ($updatedModule.Version -gt 1.0) "Module wasn't updated"
    } `
        -Skip:$(
        $whoamiValue = (whoami)

        ($whoamiValue -eq "NT AUTHORITY\SYSTEM") -or
        ($whoamiValue -eq "NT AUTHORITY\LOCAL SERVICE") -or
        ($whoamiValue -eq "NT AUTHORITY\NETWORK SERVICE") -or
        ($env:APPVEYOR_TEST_PASS -eq 'True') -or
        ($PSVersionTable.PSVersion -lt '4.0.0')
    )

    
    
    
    
    
    
    It UpdateModuleWithIncludeDependencies {
        $ModuleName = "ModuleWithDependencies2"
        $DepencyModuleNames = @()

        try {
            $res1 = Find-Module -Name $ModuleName -RequiredVersion "1.0"
            AssertEquals $res1.Name $ModuleName "Find-Module didn't find the exact module which has dependencies, $res1"

            $DepencyModuleNames = $res1.Dependencies.Name

            $res2 = Find-Module -Name $ModuleName -IncludeDependencies -RequiredVersion "1.0"
            Assert ($res2.Count -ge ($DepencyModuleNames.Count + 1)) "Find-Module with -IncludeDependencies returned wrong results, $res2"

            Install-Module -Name $ModuleName -RequiredVersion "1.0" -AllowClobber
            $ActualModuleDetails = Get-InstalledModule -Name $ModuleName -RequiredVersion $res1.Version
            AssertNotNull $ActualModuleDetails "$ModuleName module with dependencies is not installed properly"

            $DepModuleDetails = Get-Module -Name $DepencyModuleNames -ListAvailable
            AssertNotNull $DepModuleDetails "$DepencyModuleNames dependencies is not installed properly"
            Assert ($DepModuleDetails.Count -ge $DepencyModuleNames.Count)  "$DepencyModuleNames dependencies is not installed properly"


            if ($PSVersionTable.PSVersion -ge '5.0.0') {
                $res2 | ForEach-Object {
                    $mod = Get-InstalledModule -Name $_.Name -MinimumVersion $_.Version
                    AssertNotNull $mod "$($_.Name) module is not installed properly"
                }

                $depModuleDetails = $res1.Dependencies | Where-Object { $_.Name -eq 'NestedRequiredModule2' }
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                    -MinimumVersion $depModuleDetails.MinimumVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with MinimumVersion is not installed properly"

                $depModuleDetails = $res1.Dependencies | Where-Object { $_.Name -eq 'RequiredModule2' }
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                    -MinimumVersion $depModuleDetails.MinimumVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with MinimumVersion is not installed properly"

                $depModuleDetails = $res1.Dependencies | Where-Object { $_.Name -eq 'NestedRequiredModule3' }
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                    -RequiredVersion $depModuleDetails.RequiredVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with exact version is not installed properly"
                AssertEquals $depModuleDetails.RequiredVersion '2.0' "Dependencies details in Find-module output is not proper for $($depModuleDetails.Name)"

                $depModuleDetails = $res1.Dependencies | Where-Object { $_.Name -eq 'RequiredModule3' }
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                    -RequiredVersion $depModuleDetails.RequiredVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with exact version is not installed properly"
                AssertEquals $depModuleDetails.RequiredVersion '2.0' "Dependencies details in Find-module output is not proper for $($depModuleDetails.Name)"

                $depModuleDetails = $res1.Dependencies | Where-Object { $_.Name -eq 'NestedRequiredModule4' }
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                    -MinimumVersion $depModuleDetails.MinimumVersion `
                    -MaximumVersion $depModuleDetails.MaximumVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with version range is not installed properly"


                $depModuleDetails = $res1.Dependencies | Where-Object { $_.Name -eq 'RequiredModule4' }
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                    -MinimumVersion $depModuleDetails.MinimumVersion `
                    -MaximumVersion $depModuleDetails.MaximumVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with version range is not installed properly"

                $depModuleDetails = $res1.Dependencies | Where-Object { $_.Name -eq 'NestedRequiredModule5' }
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                    -MaximumVersion $depModuleDetails.MaximumVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with maximum version is not installed properly"

                $depModuleDetails = $res1.Dependencies | Where-Object { $_.Name -eq 'RequiredModule5' }
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                    -MaximumVersion $depModuleDetails.MaximumVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with maximum version is not installed properly"
            }

            
            $res3 = Find-Module -Name $ModuleName -RequiredVersion "2.0"
            AssertEquals $res3.Name $ModuleName "Find-Module didn't find the exact module which has dependencies, $res3"

            $res4 = Find-Module -Name $ModuleName -IncludeDependencies -RequiredVersion "2.0"
            Assert ($res4.Count -ge ($DepencyModuleNames.Count + 1)) "Find-Module with -IncludeDependencies returned wrong results, $res4"

            Update-Module -Name $ModuleName
            $ActualModuleDetails = Get-InstalledModule -Name $ModuleName -RequiredVersion $res3.Version
            AssertNotNull $ActualModuleDetails "$ModuleName module with dependencies is not updated properly"

            $DepModuleDetails = Get-Module -Name $DepencyModuleNames -ListAvailable
            AssertNotNull $DepModuleDetails "$DepencyModuleNames dependencies is not updated properly"
            Assert ($DepModuleDetails.Count -ge $DepencyModuleNames.Count)  "$DepencyModuleNames dependencies is not installed properly"

            if ($PSVersionTable.PSVersion -ge '5.0.0') {
                $depModuleDetails = $res3.Dependencies | Where-Object { $_.Name -eq 'NestedRequiredModule2' }
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                    -MinimumVersion $depModuleDetails.MinimumVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with MinimumVersion is not installed properly"

                $depModuleDetails = $res3.Dependencies | Where-Object { $_.Name -eq 'RequiredModule2' }
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                    -MinimumVersion $depModuleDetails.MinimumVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with MinimumVersion is not installed properly"

                $depModuleDetails = $res3.Dependencies | Where-Object { $_.Name -eq 'NestedRequiredModule3' }
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                    -RequiredVersion $depModuleDetails.RequiredVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with exact version is not updated properly"

                $depModuleDetails = $res3.Dependencies | Where-Object { $_.Name -eq 'RequiredModule3' }
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                    -RequiredVersion $depModuleDetails.RequiredVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with exact version is not updated properly"

                $depModuleDetails = $res3.Dependencies | Where-Object { $_.Name -eq 'NestedRequiredModule4' }
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                    -MinimumVersion $depModuleDetails.MinimumVersion `
                    -MaximumVersion $depModuleDetails.MaximumVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with version range is not updated properly"

                $depModuleDetails = $res3.Dependencies | Where-Object { $_.Name -eq 'RequiredModule4' }
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                    -MinimumVersion $depModuleDetails.MinimumVersion `
                    -MaximumVersion $depModuleDetails.MaximumVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with version range is not updated properly"

                $depModuleDetails = $res3.Dependencies | Where-Object { $_.Name -eq 'NestedRequiredModule5' }
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                    -MaximumVersion $depModuleDetails.MaximumVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with maximum version is not updated properly"

                $depModuleDetails = $res3.Dependencies | Where-Object { $_.Name -eq 'RequiredModule5' }
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                    -MaximumVersion $depModuleDetails.MaximumVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with maximum version is not updated properly"
            }
        }
        finally {
            Get-InstalledModule -Name $ModuleName -AllVersions | PowerShellGet\Uninstall-Module -Force
            $DepencyModuleNames | ForEach-Object { Get-InstalledModule -Name $_ -AllVersions | PowerShellGet\Uninstall-Module -Force }
        }
    }
}
