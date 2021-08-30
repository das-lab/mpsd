



function SuiteSetup {
    Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue
    Import-Module "$PSScriptRoot\Asserts.psm1" -WarningAction SilentlyContinue

    $script:ProgramFilesScriptsPath = Get-AllUsersScriptsPath
    $script:MyDocumentsScriptsPath = Get-CurrentUserScriptsPath
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

    GetAndSet-PSGetTestGalleryDetails -IsScriptSuite -SetPSGallery

    Get-InstalledScript -Name Fabrikam-ServerScript -ErrorAction SilentlyContinue | Uninstall-Script -Force
    Get-InstalledScript -Name Fabrikam-ClientScript -ErrorAction SilentlyContinue | Uninstall-Script -Force

    
    $script:TempSavePath = Join-Path -Path $script:TempPath -ChildPath "PSGet_$(Get-Random)"
    $null = New-Item -Path $script:TempSavePath -ItemType Directory -Force

    $script:AddedAllUsersInstallPath = Set-PATHVariableForScriptsInstallLocation -Scope AllUsers
    $script:AddedCurrentUserInstallPath = Set-PATHVariableForScriptsInstallLocation -Scope CurrentUser
}

function SuiteCleanup {
    if (Test-Path $script:moduleSourcesBackupFilePath) {
        Move-Item $script:moduleSourcesBackupFilePath $script:moduleSourcesFilePath -Force
    }
    else {
        RemoveItem $script:moduleSourcesFilePath
    }

    
    $null = Import-PackageProvider -Name PowerShellGet -Force

    RemoveItem $script:TempSavePath


    if ($script:AddedAllUsersInstallPath) {
        Reset-PATHVariableForScriptsInstallLocation -Scope AllUsers
    }

    if ($script:AddedCurrentUserInstallPath) {
        Reset-PATHVariableForScriptsInstallLocation -Scope CurrentUser
    }
}

Describe PowerShell.PSGet.UpdateScriptTests -Tags 'BVT', 'InnerLoop' {

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

    
    
    
    
    
    
    It "UpdateScriptWithConfirmAndNoToPrompt" {
        $installedVersion = "1.0"
        Install-Script Fabrikam-ServerScript -RequiredVersion $installedVersion
        $outputPath = $script:TempPath
        $guid = [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        
        $Global:proxy.UI.ChoiceToMake = 2
        $content = $null

        try {
            $result = ExecuteCommand $runspace 'Update-Script Fabrikam-ServerScript -Confirm'
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

        $itemInfo = Find-Script Fabrikam-ServerScript -Repository PSGallery
        $shouldProcessMessage = ($LocalizedData.UpdateScriptwhatIfMessage -replace "__OLDVERSION__", $installedVersion)
        $shouldProcessMessage = ($shouldProcessMessage -f ($itemInfo.Name, $itemInfo.Version))
        Assert ($content -and ($content -match $shouldProcessMessage)) "update script confirm prompt is not working, Expected:$shouldProcessMessage, Actual:$content"

        $res = Get-InstalledScript Fabrikam-ServerScript
        AssertEquals $res.Name 'Fabrikam-ServerScript' "Update-Script should not update the Fabrikam-ServerScript script when pressed NO to Confirm."
        AssertEquals $res.Version $installedVersion "Update-Script should not update the Fabrikam-ServerScript script when pressed NO to Confirm."
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ($PSCulture -ne 'en-US') -or ([System.Environment]::OSVersion.Version -lt '6.2.9200.0'))

    
    
    
    
    
    
    It "UpdateScriptWithConfirmAndYesToPrompt" {
        $installedVersion = '1.0'
        Install-Script Fabrikam-ServerScript -RequiredVersion $installedVersion
        $outputPath = $script:TempPath
        $guid = [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        
        $Global:proxy.UI.ChoiceToMake = 0
        $content = $null

        try {
            $result = ExecuteCommand $runspace 'Update-Script Fabrikam-ServerScript -Confirm'
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

        $itemInfo = Find-Script Fabrikam-ServerScript -Repository PSGallery
        $shouldProcessMessage = ($LocalizedData.UpdateScriptwhatIfMessage -replace "__OLDVERSION__", $installedVersion)
        $shouldProcessMessage = ($shouldProcessMessage -f ($itemInfo.Name, $itemInfo.Version))
        Assert ($content -and ($content -match $shouldProcessMessage)) "update script confirm prompt is not working, Expected:$shouldProcessMessage, Actual:$content"

        $res = Get-InstalledScript Fabrikam-ServerScript
        AssertEquals $res.Name 'Fabrikam-ServerScript' "Update-Script should not update the Fabrikam-ServerScript script when pressed NO to Confirm, $res"
        Assert ($res.Version -gt [Version]"1.0") "Update-Script should not update the Fabrikam-ServerScript script when pressed NO to Confirm, $res"
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ($PSCulture -ne 'en-US') -or ([System.Environment]::OSVersion.Version -lt '6.2.9200.0'))

    
    
    
    
    
    
    It "UpdateScriptWithWhatIf" {
        $installedVersion = "1.0"
        Install-Script Fabrikam-ServerScript -RequiredVersion $installedVersion

        $outputPath = $script:TempPath
        $guid = [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1
        $content = $null

        try {
            $result = ExecuteCommand $runspace 'Update-Script Fabrikam-ServerScript -WhatIf'
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

        $itemInfo = Find-Script Fabrikam-ServerScript -Repository PSGallery
        $shouldProcessMessage = ($LocalizedData.UpdateScriptwhatIfMessage -replace "__OLDVERSION__", $installedVersion)
        $shouldProcessMessage = ($shouldProcessMessage -f ($itemInfo.Name, $itemInfo.Version))
        Assert ($content -and ($content -match $shouldProcessMessage)) "update script whatif message is missing, Expected:$shouldProcessMessage, Actual:$content"

        $res = Get-InstalledScript Fabrikam-ServerScript
        AssertEquals $res.Name 'Fabrikam-ServerScript' "Update-Script should not update the script with -WhatIf option, $res"
        Assert ($res.Version -eq [Version]"1.0") "Update-Script should not update the script with -WhatIf option, $res"
    } `
        -Skip:$(($PSEdition -eq 'Core') -or ($PSCulture -ne 'en-US') -or ([System.Environment]::OSVersion.Version -lt '6.2.9200.0'))

    
    
    
    
    
    
    It "UpdateScriptWithFalseConfirm" {
        $scriptName = 'Fabrikam-ServerScript'
        Install-Script -Name $scriptName -RequiredVersion 1.0
        Update-Script $scriptName -Confirm:$false

        $res = Get-InstalledScript $scriptName
        AssertEquals $res.Name $scriptName "Update-Script should update the script if -Confirm option is false, $res"
        Assert ($res.Version -gt [Version]"1.0") "Update-Script should update the script if -Confirm option is false, $res"
    }


    
    
    
    
    
    
    It "UpdateScriptWithForce" {
        $scriptName = 'Fabrikam-ServerScript'
        Install-Script -Name $scriptName
        $res1 = Get-InstalledScript $scriptName

        $MyError = $null
        Update-Script $scriptName -Force -ErrorVariable MyError
        Assert ($MyError.Count -eq 0) "There should not be any error from force update, $MyError"

        $res2 = Get-InstalledScript $scriptName
        Assert (($res1.Name -eq $res2.Name) -and ($res1.Version -eq $res2.Version)) "Update-Script with force should not change the version"
    }


    
    
    
    
    
    
    It "UpdateMultipleScriptsWithReqVersion" {
        Install-Script Fabrikam-ClientScript, Fabrikam-ServerScript

        AssertFullyQualifiedErrorIdEquals -scriptblock { Update-Script Fabrikam-ClientScript, Fabrikam-ServerScript -RequiredVersion 3.0 } `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Update-Script"
    }


    
    
    
    
    
    
    It "UpdateScriptsWithReqVersionAndWildcard" {
        Install-Script Fabrikam-ServerScript

        AssertFullyQualifiedErrorIdEquals -scriptblock { Update-Script Fabrikam-*rScript -RequiredVersion 3.0 } `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Update-Script"
    }


    
    
    
    
    
    
    It "UpdateScriptWithWildcardName" {
        Install-Script Fabrikam-ServerScript -RequiredVersion 1.0
        Update-Script Fab[rR]ikam?Ser[a-z]erScr?pt

        $res = Get-InstalledScript Fabrikam-ServerScript
        Assert ($res.Name -eq "Fabrikam-ServerScript" -and $res.Version -gt [Version]"1.0")  "Update-Script with wildcard name should update the script, $res"
    }

    
    
    
    
    
    
    It "UpdateMultipleScriptsWithWildcard" {
        Install-Script Fabrikam-ClientScript -RequiredVersion 1.0
        $ClientScriptDetails = Get-InstalledScript -Name Fabrikam-ClientScript

        Install-Script Fabrikam-ServerScript -RequiredVersion 1.0
        $MyError = $null
        $DateTimeBeforeUpdate = Get-Date
        Update-Script Fabrikam-* -Force -ErrorVariable MyError
        Assert ($MyError.Count -eq 0) "There should not be any error when updating multiple scripts with wildcard in name, $MyError"

        $res = Get-InstalledScript -Name Fabrikam-ServerScript -MinimumVersion '1.1'
        Assert ($res -and ($res.Name -eq "Fabrikam-ServerScript") -and ($res.Version -gt [Version]"1.0")) "Update-Script should update when wildcard specified in name"

        $res = Get-InstalledScript -Name Fabrikam-ClientScript -MinimumVersion '1.1'
        Assert ($res -and ($res.Name -eq 'Fabrikam-ClientScript') -and ($res.Version -gt [Version]"1.0")) "Update-Script should update when wildcard specified in name"

        AssertEquals $res.InstalledDate $ClientScriptDetails.InstalledDate "InstalledDate should be same for the updated version"
        Assert ($res.UpdatedDate.AddSeconds(1) -ge $DateTimeBeforeUpdate) "Get-InstalledScript results are not expected, UpdatedDate $($res.UpdatedDate.Ticks) should be after $($DateTimeBeforeUpdate.Ticks)"
    }

    
    
    
    
    
    
    It "UpdateNotInstalledScript" {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Update-Script ScriptNotInstalled } `
            -expectedFullyQualifiedErrorId "ScriptNotInstalledOnThisMachine,Update-Script"
    }

    
    
    
    
    
    
    It "Update-Script should be silent" {
        $scriptName = 'Fabrikam-ServerScript'
        Install-Script $scriptName -RequiredVersion 1.0

        $result = Update-Script $scriptName
        $result | Should -BeNullOrEmpty
    }

    
    
    
    
    
    
    It "Update-Script should return output" {
        $scriptName = 'Fabrikam-ServerScript'
        Install-Script $scriptName -RequiredVersion 1.0

        $result = Update-Script $scriptName -PassThru
        $result | Should -Not -BeNullOrEmpty
    }

    
    
    
    
    
    
    It "UpdateScriptWithReqVersion" {
        $scriptName = 'Fabrikam-ServerScript'
        Install-Script $scriptName -RequiredVersion 1.0
        Update-Script $scriptName -RequiredVersion 2.0

        $res = Get-InstalledScript $scriptName
        Assert ($res.Name -eq "Fabrikam-ServerScript" -and $res.Version -eq [Version]"2.0")  "Update-Script should update the script with RequiredVersion, $res"
    }

    
    
    
    
    
    
    It "UpdateScriptWithNotAvailableReqVersion" {
        Install-Script Fabrikam-ServerScript -RequiredVersion 1.0

        $expectedFullyQualifiedErrorId = 'NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'

        AssertFullyQualifiedErrorIdEquals -scriptblock { Update-Script Fabrikam-ServerScript -RequiredVersion 10.0 } `
            -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }


    
    
    
    
    
    
    It "UpdateScriptWithReqVersionAndForceToDowngradeVersion" {
        $scriptName = 'Fabrikam-ServerScript'
        Install-Script $scriptName
        Update-Script $scriptName -RequiredVersion 1.0 -Force

        $res = Get-InstalledScript $scriptName
        Assert ($res.Name -eq $scriptName -and $res.Version -eq [Version]"1.0")  "Update-Script should downgrade the script version with -RequiredVersion and -Force, $res"
    }

    
    
    
    
    
    
    It "AdminPrivilegesAreNotRequiredForUpdatingAllUsersScript" {
        Install-Script -Name Fabrikam-ServerScript -RequiredVersion 1.0 -Scope AllUsers
        $content = Invoke-WithoutAdminPrivileges (@'
        Import-Module "{0}\PowerShellGet.psd1" -Force -Passthru | select ModuleBase
        Update-Script -Name Fabrikam-ServerScript
'@ -f (Get-Module PowerShellGet).ModuleBase)

        $updatedScript = Get-InstalledScript Fabrikam-ServerScript
        Assert ($updatedScript.Version -gt 1.0) "Update-Script failed to updated script running as non-admin: $content"
    } `
        -Skip:$(
        $whoamiValue = (whoami)
        ($whoamiValue -eq "NT AUTHORITY\SYSTEM") -or
        ($whoamiValue -eq "NT AUTHORITY\LOCAL SERVICE") -or
        ($whoamiValue -eq "NT AUTHORITY\NETWORK SERVICE") -or
        ($env:APPVEYOR_TEST_PASS -eq 'True') -or
        ($PSVersionTable.PSVersion -lt '4.0.0')
    )

    
    
    
    
    
    
    It "UpdateScriptWithLowerReqVersionShouldNotUpdate" {
        Install-Script Fabrikam-ServerScript -Force
        Update-Script Fabrikam-ServerScript -RequiredVersion 1.0
        $res = Get-InstalledScript Fabrikam-ServerScript
        Assert ($res.Name -eq "Fabrikam-ServerScript" -and $res.Version -gt [Version]"1.0")  "Update-Script should not downgrade the script version with -RequiredVersion, Name: $($res.Name), Version: $($res.Version)"
    }

    
    
    
    
    
    
    It "UpdateMultipleScripts" {
        Install-Script Fabrikam-ClientScript -RequiredVersion 1.0
        Install-Script Fabrikam-ServerScript -RequiredVersion 1.0
        Update-Script Fabrikam-ClientScript, Fabrikam-ServerScript

        $res = Get-InstalledScript -Name Fabrikam-ServerScript, Fabrikam-ClientScript
        Assert (($res.Count -eq 2) -and ($res[0].Version -gt [Version]"1.0") -and ($res[1].Version -gt [Version]"1.0")) "Multiple script should be updated"
    }


    
    
    
    
    
    
    
    It "UpdateAllScripts" {
        Install-Script Fabrikam-ClientScript -RequiredVersion 1.0
        Install-Script Fabrikam-ServerScript -RequiredVersion 1.0
        Update-Script -ErrorAction SilentlyContinue -ErrorVariable err
        $err | ? { $_.FullyQualifiedErrorId -notmatch "NoMatchFoundForCriteria" } | % { Write-Error $_ }

        $res = Get-InstalledScript -Name Fabrikam-ServerScript, Fabrikam-ClientScript
        Assert (($res.Count -eq 2) -and ($res[0].Version -gt [Version]"1.0") -and ($res[1].Version -gt [Version]"1.0")) "Multiple script should be updated"
    }


    
    
    
    
    
    
    It "UpdateMultipleScriptsWithForce" {
        Install-Script Fabrikam-ClientScript, Fabrikam-ServerScript

        $MyError = $null
        Update-Script Fabrikam-ClientScript, Fabrikam-ServerScript -Force -ErrorVariable MyError
        Assert ($MyError.Count -eq 0) "There should not be any error from force update for multiple scripts, $MyError"

        $res = Get-InstalledScript Fabrikam-ServerScript
        Assert (($res.Name -eq 'Fabrikam-ServerScript') -and ($res.Version -gt [Version]"1.0")) "Update-Script should update when multiple scripts are specified"

        $res = Get-InstalledScript Fabrikam-ClientScript
        Assert (($res.Name -eq 'Fabrikam-ClientScript') -and ($res.Version -gt [Version]"1.0")) "Update-Script should update when multiple scripts are specified"
    }

    
    
    
    
    
    
    It "UpdateScriptUnderCurrentUserScope" {
        $scriptName = 'Fabrikam-ServerScript'

        Install-Script $scriptName -Scope CurrentUser -RequiredVersion 1.0
        Update-Script $scriptName

        $res = Get-InstalledScript $scriptName

        Assert (($res.Name -eq $scriptName) -and ($res.Version -gt [Version]"1.0")) "Update-Script should update the script installed to current user scope, $res"
        AssertEquals $res.InstalledLocation $script:MyDocumentsScriptsPath "Update-Script should update the script installed to current user scope, updated script base: $($res.InstalledLocation)"
    }

    
    
    
    
    
    
    It "UpdateScriptUnderAllUsersScope" {
        $scriptName = 'Fabrikam-ServerScript'
        $shouldBeInAllUsers = ($PSVersionTable.PSVersion -lt "5.0" -or $PSEdition -eq 'Desktop') 
        Install-Script $scriptName -Scope AllUsers -RequiredVersion 1.0
        Update-Script $scriptName

        $res = Get-InstalledScript $scriptName

        Assert (($res.Name -eq $scriptName) -and ($res.Version -gt [Version]"1.0")) "Update-Script should update the script, $res"
        if ($shouldBeInAllUsers) {
            AssertEquals $res.InstalledLocation $script:ProgramFilesScriptsPath "Update-Script should put update in all users scope, but updated script base: $($res.InstalledLocation)"
        }
        else {
            AssertEquals $res.InstalledLocation $script:MyDocumentsScriptsPath "Update-Script should put update in current user scope, updated script base: $($res.InstalledLocation)"
        }
    }
}

Describe PowerShell.PSGet.UpdateScriptTests.P1 -Tags 'P1', 'OuterLoop' {

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

    
    
    
    
    
    
    It UpdateScriptWithIncludeDependencies {
        $ScriptName = 'Script-WithDependencies2'
        $NamesToUninstall = @()

        try {
            $res1 = Find-Script -Name $ScriptName -MaximumVersion "1.0" -MinimumVersion "0.1"
            AssertEquals $res1.Name $ScriptName "Find-Script didn't find the exact script which has dependencies, $res1"

            $DepencyNames = $res1.Dependencies.Name
            $res2 = Find-Script -Name $ScriptName -IncludeDependencies -MaximumVersion "1.0" -MinimumVersion "0.1"
            Assert ($res2.Count -ge ($DepencyNames.Count + 1)) "Find-Script with -IncludeDependencies returned wrong results, $res2"

            Install-Script -Name $ScriptName -MaximumVersion "1.0" -MinimumVersion "0.1"
            $ActualScriptDetails = Get-InstalledScript -Name $ScriptName -RequiredVersion $res1.Version
            AssertNotNull $ActualScriptDetails "$ScriptName script with dependencies is not installed properly"

            $NamesToUninstall += $res2.Name

            $res2 | ForEach-Object {
                if (-not (Get-InstalledScript -Name $_.Name -MaximumVersion $_.Version -ErrorAction SilentlyContinue) -and
                    -not (Get-InstalledModule -Name $_.Name -MaximumVersion $_.Version -ErrorAction SilentlyContinue)) {
                    Assert $false "Script dependency $_ is not installed"
                }
            }

            
            $res3 = Find-Script -Name $ScriptName -IncludeDependencies

            Update-Script -Name $ScriptName

            $NamesToUninstall += $res3.Name

            $res3 | ForEach-Object {
                if (-not (Get-InstalledScript -Name $_.Name -MaximumVersion $_.Version -ErrorAction SilentlyContinue) -and
                    -not (Get-InstalledModule -Name $_.Name -MaximumVersion $_.Version -ErrorAction SilentlyContinue)) {
                    Assert $false "Script dependency $_ is not updated properly"
                }
            }
        }
        finally {
            
            $NamesToUninstall | ForEach-Object {
                PowerShellGet\Uninstall-Script $_ -Force -ErrorAction SilentlyContinue
                PowerShellGet\Uninstall-Module $_ -Force -ErrorAction SilentlyContinue
            }
        }
    }  -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')
}
