



function SuiteSetup {
    Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue
    Import-Module "$PSScriptRoot\Asserts.psm1" -WarningAction SilentlyContinue

    $script:PSGetLocalAppDataPath = Get-PSGetLocalAppDataPath
    $script:DscTestScript = "DscTestScript"

    
    Install-NuGetBinaries

    $psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
    Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $psgetModuleInfo.ModuleBase

    $script:moduleSourcesFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml"
    $script:moduleSourcesBackupFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml_$(get-random)_backup"
    if (Test-Path $script:moduleSourcesFilePath) {
        Rename-Item $script:moduleSourcesFilePath $script:moduleSourcesBackupFilePath -Force
    }

    GetAndSet-PSGetTestGalleryDetails -IsScriptSuite -SetPSGallery
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

Describe PowerShell.PSGet.FindScriptTests -Tags 'BVT', 'InnerLoop' {

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    
    
    
    
    
    
    
    
    
    It "FindScriptWithoutAnyParameterValues" {
        $psgetItemInfo = Find-Script
        Assert ($psgetItemInfo.Count -ge 1) "Find-Script did not return any scripts."
    }

    
    
    
    
    
    
    It "FindASpecificScript" {
        $res = Find-Script Fabrikam-ServerScript
        Assert ($res -and ($res.Name -eq "Fabrikam-ServerScript")) "Find-Script failed to find a specific script"
    }

    
    
    
    
    
    
    It "FindScriptWithRangeWildCards" {
        $res = Find-Script -Name "Fab[rR]ikam?Ser[a-z]erScr?pt"
        Assert ($res -and ($res.Name -eq "Fabrikam-ServerScript")) "Find-Script failed to get a script with wild card in script name"
    }

    
    
    
    
    
    
    It "FindNotAvaialableScriptWithWildCards" {
        $res = Find-Script -Name "Fab[rR]ikam?Ser[a-z]erScr?ptW"
        Assert (-not $res) "Find-Script should not find a not available script with wild card in script name"
    }

    
    
    
    
    
    
    It "FindScriptNonExistentScript" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script NonExistentScript} `
            -expectedFullyQualifiedErrorId 'NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.FindPackage'
    }

    
    
    
    
    
    
    It "FindModuleNotScript" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script ContosoServer} `
            -expectedFullyQualifiedErrorId 'MatchInvalidType,Find-Script'
    }

    
    
    
    
    
    
    It "FindModuleNotScriptWildcard" {
        $res = Find-Script ContosoServer*
        Assert (-not $res) "Find-Script returned a module"
    }

    
    
    
    
    
    
    It "FindScriptWithMinVersion" {
        $res = Find-Script Fabrikam-ServerScript -MinimumVersion 1.0
        Assert ($res.Name -eq "Fabrikam-ServerScript" -and $res.Version -ge [Version]"1.0" ) "Find-Script failed to find a script using MinimumVersion"
    }

    
    
    
    
    
    
    It "FindScriptWithRequiredVersion" {
        $res = Find-Script Fabrikam-ServerScript -RequiredVersion 2.0
        Assert ($res -and ($res.Name -eq "Fabrikam-ServerScript") -and $res.Version -eq [Version]"2.0") "Find-Script failed to find a script using RequiredVersion, $res"
    }

    
    
    
    
    
    
    It "FindScriptWithMultiNames" {
        $res = Find-Script Fabrikam-ClientScript, Fabrikam-ServerScript -Repository PSGallery
        Assert ($res.Count -eq 2) "Find-Script with multiple names should not fail, $res"
    }

    
    
    
    
    
    
    It FindScriptWithAllVersions {
        $res = Find-Script Fabrikam-ClientScript -Repository PSGallery -AllVersions
        Assert ($res.Count -gt 1) "Find-Script with -AllVersions should return more than one version, $res"
    }

    
    
    
    
    
    
    It FindScriptUsingFilter {
        $psgetItemInfo = Find-Script -Filter Fabrikam-ClientScript
        AssertEquals $psgetItemInfo.Name Fabrikam-ClientScript "Find-Script with filter is not working, $psgetItemInfo"
    }

    
    
    
    
    
    
    It FindScriptUsingIncludesWorkflow {
        $psgetScriptInfo = Find-Script -Includes Workflow | Where-Object {$_.Name -eq 'Fabrikam-ClientScript'}
        AssertNotNull $psgetScriptInfo.Includes "Includes is missing on PSGetScriptInfo, $($psgetScriptInfo.Includes)"
        Assert (-not $psgetScriptInfo.Includes.DscResource.Count) "Script should not have any DscResources, $($psgetScriptInfo.Includes.DscResource)"
        Assert $psgetScriptInfo.Includes.Workflow.Count "Workflows are missing on PSGetScriptInfo, $($psgetScriptInfo.Includes.Workflow)"
        AssertEquals $psgetScriptInfo.Includes.Workflow 'Test-WorkflowFromScript_Fabrikam-ClientScript' "Test-WorkflowFromScript_Fabrikam-ClientScript Workflow is missing on PSGetScriptInfo, $($psgetScriptInfo.Includes.Workflow)"
        Assert $psgetScriptInfo.Includes.Command.Count "Commands are missing on PSGetScriptInfo, $($psgetScriptInfo.Includes.Command)"
        Assert $psgetScriptInfo.Includes.Function.Count "Functions are missing on PSGetScriptInfo, $($psgetScriptInfo.Includes.Function)"
        Assert (-not $psgetScriptInfo.Includes.Cmdlet.Count) "Script should not have any cmdlets, $($psgetScriptInfo.Includes.Cmdlet)"
    }

    
    
    
    
    
    
    It FindScriptUsingIncludesFunction {
        $psgetScriptInfo = Find-Script -Includes Function -Tag Tag1 | Where-Object {$_.Name -eq 'Fabrikam-ServerScript'}
        AssertNotNull $psgetScriptInfo.Includes "Includes is missing on PSGetScriptInfo, $($psgetScriptInfo.Includes)"
        Assert (-not $psgetScriptInfo.Includes.DscResource.Count) "Script should not have any DscResources, $($psgetScriptInfo.Includes.DscResource)"
        Assert $psgetScriptInfo.Includes.Workflow.Count "Workflows are missing on PSGetScriptInfo, $($psgetScriptInfo.Includes.Workflow)"
        Assert $psgetScriptInfo.Includes.Command.Count "Commands are missing on PSGetScriptInfo, $($psgetScriptInfo.Includes.Command)"
        Assert $psgetScriptInfo.Includes.Function.Count "Functions are missing on PSGetScriptInfo, $($psgetScriptInfo.Includes.Function)"
        AssertEquals $psgetScriptInfo.Includes.Function 'Test-FunctionFromScript_Fabrikam-ServerScript' "Test-FunctionFromScript_Fabrikam-ServerScript function is missing on PSGetScriptInfo, $($psgetScriptInfo.Includes.Function)"
        Assert (-not $psgetScriptInfo.Includes.Cmdlet.Count) "Script should not have any cmdlets, $($psgetScriptInfo.Includes.Cmdlet)"
    }

    
    
    
    
    
    
    It FindScriptUsingTag {
        $tagValue = 'Tag-Fabrikam-Script-2.5'
        $psgetScriptInfo = Find-Script -Tag $tagValue
        AssertNotNull $psgetScriptInfo.Tags "Tags is missing on PSGetScriptInfo, $($psgetScriptInfo.Tags)"
        Assert ($psgetScriptInfo.Tags -contains $tagValue) "$tagValue is missing in Tags, $($psgetScriptInfo.Tags)"
    }

    
    
    
    
    
    
    It FindScriptUsingCommand {
        $commandName = 'Test-FunctionFromScript_Fabrikam-Script'
        $psgetScriptInfo = Find-Script -Command $commandName
        AssertNotNull $psgetScriptInfo.Includes.Command "Command list is missing on PSGetScriptInfo, $($psgetScriptInfo.Includes.Command)"
        Assert ($psgetScriptInfo.Includes.Command -contains $commandName) "$commandName is missing in Command, $($psgetScriptInfo.Includes.Command)"
    }
}

Describe PowerShell.PSGet.FindScriptTests.P1 -Tags 'P1', 'OuterLoop' {

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    
    
    
    
    
    
    It "FindScriptWithPostfixWildcard" {
        $res = Find-Script Fabrikam-Serve*
        Assert ($res -and ($res.Name -eq "Fabrikam-ServerScript")) "Find-Script failed to get a script with postfix wild card search"
    }

    
    
    
    
    
    
    It "FindScriptWithPrefixWildcard" {
        $res = Find-Script *ServerScript
        Assert ($res -and ($res.Name -eq "Fabrikam-ServerScript")) "Find-Script failed to get a script with wild card"
    }

    
    
    
    
    
    
    It "FindMultipleScriptsWithWildcard" {
        $res = Find-Script Fabrikam*
        Assert ($res.Count -ge 3) "Find-Script failed to multiple scripts with wild card"
    }

    
    
    
    
    
    
    It "FindScriptWithWildcards" {
        $res = Find-Script *rikam-ServerScr*
        Assert ($res -and ($res.Name -eq "Fabrikam-ServerScript")) "Find-Script failed to find script using wild cards"
    }

    
    
    
    
    
    
    It "FindScriptWithVersionParams" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script Fabrikam-ServerScript -MinimumVersion 1.0 -RequiredVersion 5.0} `
            -expectedFullyQualifiedErrorId "VersionRangeAndRequiredVersionCannotBeSpecifiedTogether,Find-Script"
    }

    
    
    
    
    
    
    It "FindScriptWithMinVersionNotAvailable" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script Fabrikam-ServerScript -MinimumVersion 10.0} `
            -expectedFullyQualifiedErrorId "NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.FindPackage"
    }

    
    
    
    
    
    
    It "FindScriptWithReqVersionNotAvailable" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script Fabrikam-ServerScript -RequiredVersion 10.0} `
            -expectedFullyQualifiedErrorId "NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.FindPackage"
    }

    
    
    
    
    
    
    It "FindScriptWithMultipleScriptNamesAndReqVersion" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script Fabrikam-ServerScript, Fabrikam-ClientScript -RequiredVersion 1.0} `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Find-Script"
    }

    
    
    
    
    
    
    It "FindScriptWithMultipleScriptNamesAndMinVersion" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script Fabrikam-ServerScript, Fabrikam-ClientScript -MinimumVersion 1.0} `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Find-Script"
    }

    
    
    
    
    
    
    It "FindScriptWithWildcardNameAndReqVersion" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script Fabrikam-Ser*er -RequiredVersion 1.0} `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Find-Script"
    }

    
    
    
    
    
    
    It "FindScriptWithWildcardNameAndMinVersion" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script Fabrikam-Ser*er -MinimumVersion 1.0} `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Find-Script"
    }

    
    
    
    
    
    
    It FindScriptWithAllVersionsAndMinimumVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script Fabrikam-ClientScript -MinimumVersion 2.0 -Repository PSGallery -AllVersions} `
            -expectedFullyQualifiedErrorId 'AllVersionsCannotBeUsedWithOtherVersionParameters,Find-Script'
    }

    
    
    
    
    
    
    It FindScriptWithAllVersionsAndRequiredVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Find-Script Fabrikam-ClientScript -RequiredVersion 2.0 -Repository PSGallery -AllVersions} `
            -expectedFullyQualifiedErrorId 'AllVersionsCannotBeUsedWithOtherVersionParameters,Find-Script'
    }

    
    
    
    
    
    
    It FindScriptUsingFilterKeyWordNotExists {
        $psgetItemInfo = Find-Script -Filter KeyWordNotExists
        AssertNull $psgetItemInfo "Find-Script with filter is not working for KeyWordNotExists, $psgetItemInfo"
    }

    
    
    
    
    
    
    It FindScriptWithIncludeDependencies {
        $ScriptName = "Script-WithDependencies1"

        $res1 = Find-Script -Name $ScriptName -MaximumVersion "1.0" -MinimumVersion "0.1"
        AssertEquals $res1.Name $ScriptName "Find-Script didn't find the exact script which has dependencies, $res1"

        $DepencyScriptNames = $res1.Dependencies.Name

        $res2 = Find-Script -Name $ScriptName -IncludeDependencies -MaximumVersion "1.0" -MinimumVersion "0.1"
        Assert ($res2.Count -ge ($DepencyScriptNames.Count + 1)) "Find-Script with -IncludeDependencies returned wrong results, $res2"

        $DepencyScriptNames | ForEach-Object { Assert ($res2.Name -Contains $_) "Find-Script with -IncludeDependencies didn't return the $_ script, $($res2.Name)"}
    }
}
