


. "$PSScriptRoot\PSGetFindModuleTests.Manifests.ps1"
. "$PSScriptRoot\PSGetTests.Generators.ps1"

function SuiteSetup {
    Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue
    Import-Module "$PSScriptRoot\Asserts.psm1" -WarningAction SilentlyContinue

    $script:MyDocumentsModulesPath = Get-CurrentUserModulesPath
    $script:PSGetLocalAppDataPath = Get-PSGetLocalAppDataPath
    $script:DscTestModule = "DscTestModule"

    
    Install-NuGetBinaries

    $psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
    Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $psgetModuleInfo.ModuleBase

    $script:moduleSourcesFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml"
    $script:moduleSourcesBackupFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml_$(get-random)_backup"
    if (Test-Path $script:moduleSourcesFilePath) {
        Rename-Item $script:moduleSourcesFilePath $script:moduleSourcesBackupFilePath -Force
    }

    GetAndSet-PSGetTestGalleryDetails -SetPSGallery
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

Describe PowerShell.PSGet.FindModuleTests -Tags 'BVT', 'InnerLoop' {

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    
    
    
    
    
    
    
    
    
    It "FindModuleWithoutAnyParameterValues" {
        $psgetItemInfo = Find-Module
        Assert ($psgetItemInfo.Count -ge 1) "Find-Module did not return any modules."
    }

    
    
    
    
    
    
    It "FindASpecificModule" {
        $res = Find-Module ContosoServer
        Assert ($res -and ($res.Name -eq "ContosoServer")) "Find-Module failed to find a specific module"
    }

    
    
    
    
    
    
    It "FindModuleWithRangeWildCards" {
        $res = Find-Module -Name "Co[nN]t?soS[a-z]r?er"
        Assert ($res -and ($res.Name -eq "ContosoServer")) "Find-Module failed to get a module with wild card in module name"
    }

    
    
    
    
    
    
    It "FindNotAvaialableModuleWithWildCards" {
        $res = Find-Module -Name "Co[nN]t?soS[a-z]r?eW"
        Assert (-not $res) "Find-Module should not find a not available module with wild card in module name"
    }

    
    
    
    
    
    
    It "FindModuleNonExistentModule" {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Find-Module NonExistentModule } `
            -expectedFullyQualifiedErrorId "NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.FindPackage"
    }

    
    
    
    
    
    
    It "FindScriptNotModule" {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Find-Module Fabrikam-ServerScript } `
            -expectedFullyQualifiedErrorId 'MatchInvalidType,Find-Module'
    }

    
    
    
    
    
    
    It "FindScriptNotModuleWildcard" {
        $res = Find-Module Fabrikam-ServerScript*
        Assert (-not $res) "Find-Module returned a script"
    }

    
    
    
    
    
    
    It "FindModuleWithVersionParams" {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Find-Module ContosoServer -MinimumVersion 1.0 -RequiredVersion 5.0 } `
            -expectedFullyQualifiedErrorId "VersionRangeAndRequiredVersionCannotBeSpecifiedTogether,Find-Module"
    }

    
    
    
    
    
    
    It "FindModuleWithMinVersion" {
        $res = Find-Module coNTososeRVer -MinimumVersion 1.0
        Assert ($res.Name -eq "ContosoServer" -and $res.Version -ge [Version]"1.0" ) "Find-Module failed to find a module using MinimumVersion"
    }

    
    
    
    
    
    
    It "FindModuleWithMinVersionNotAvailable" {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Find-Module ContosoServer -MinimumVersion 10.0 } `
            -expectedFullyQualifiedErrorId "NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.FindPackage"
    }

    
    
    
    
    
    
    It "FindModuleWithReqVersionNotAvailable" {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Find-Module ContosoServer -RequiredVersion 10.0 } `
            -expectedFullyQualifiedErrorId "NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.FindPackage"
    }

    
    
    
    
    
    
    It "FindModuleWithRequiredVersion" {
        $res = Find-Module ContosoServer -RequiredVersion 2.0
        Assert ($res -and ($res.Name -eq "ContosoServer") -and $res.Version -eq [Version]"2.0") "Find-Module failed to find a module using RequiredVersion, $res"
    }

    
    
    
    
    
    
    It "FindModuleWithMultipleModuleNamesAndReqVersion" {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Find-Module ContosoServer, ContosoClient -RequiredVersion 1.0 } `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Find-Module"
    }

    
    
    
    
    
    
    It "FindModuleWithMultipleModuleNamesAndMinVersion" {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Find-Module ContosoServer, ContosoClient -MinimumVersion 1.0 } `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Find-Module"
    }

    
    
    
    
    
    
    It "FindModuleWithWildcardNameAndReqVersion" {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Find-Module Contoso*er -RequiredVersion 1.0 } `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Find-Module"
    }

    
    
    
    
    
    
    It "FindModuleWithWildcardNameAndMinVersion" {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Find-Module Contoso*er -MinimumVersion 1.0 } `
            -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Find-Module"
    }

    
    
    
    
    
    
    It "FindModuleWithMultiNames" {
        $res = Find-Module ContosoClient, ContosoServer -Repository PSGallery
        Assert ($res.Count -eq 2) "Find-Module with multiple names should not fail, $res"
    }

    
    
    
    
    
    
    It FindModuleWithAllVersions {
        $res = Find-Module ContosoClient -Repository PSGallery -AllVersions
        Assert ($res.Count -gt 1) "Find-Module with -AllVersions should return more than one version, $res"
    }

    
    
    
    
    
    
    It FindModuleUsingFilter {
        $psgetItemInfo = Find-Module -Filter KeyWord1
        AssertEquals $psgetItemInfo.Name $script:DscTestModule "Find-Module with filter is not working, $psgetItemInfo"
    }

    
    
    
    
    
    
    It FindModuleUsingIncludesRoleCapability {
        $psgetModuleInfo = Find-Module -Includes RoleCapability | Where-Object { $_.Name -eq "DscTestModule" }
        AssertNotNull $psgetModuleInfo.Includes "Includes is missing on PSGetModuleInfo, $($psgetModuleInfo.Includes)"
        Assert $psgetModuleInfo.Includes.RoleCapability.Count "RoleCapability are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.RoleCapability)"
        Assert $psgetModuleInfo.Includes.DscResource.Count "DscResource are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.DscResource)"
        Assert $psgetModuleInfo.Includes.Command.Count "Commands are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Command)"
        Assert $psgetModuleInfo.Includes.Function.Count "Functions are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Function)"
        Assert $psgetModuleInfo.Includes.Cmdlet.Count "Cmdlets are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Cmdlet)"
    }

    
    
    
    
    
    
    It FindModuleUsingIncludesDscResource {
        $psgetModuleInfo = Find-Module -Includes DscResource | Where-Object { $_.Name -eq "DscTestModule" }
        AssertNotNull $psgetModuleInfo.Includes "Includes is missing on PSGetModuleInfo, $($psgetModuleInfo.Includes)"
        Assert $psgetModuleInfo.Includes.DscResource.Count "DscResource are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.DscResource)"
        Assert $psgetModuleInfo.Includes.Command.Count "Commands are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Command)"
        Assert $psgetModuleInfo.Includes.Function.Count "Functions are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Function)"
        Assert $psgetModuleInfo.Includes.Cmdlet.Count "Cmdlets are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Cmdlet)"
    }

    
    
    
    
    
    
    It FindModuleUsingIncludesCmdlet {
        $psgetModuleInfo = Find-Module -Includes Cmdlet | Where-Object { $_.Name -eq "DscTestModule" }
        AssertNotNull $psgetModuleInfo.Includes "Includes is missing on PSGetModuleInfo, $($psgetModuleInfo.Includes)"
        Assert $psgetModuleInfo.Includes.DscResource.Count "DscResource are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.DscResource)"
        Assert $psgetModuleInfo.Includes.Command.Count "Commands are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Command)"
        Assert $psgetModuleInfo.Includes.Function.Count "Functions are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Function)"
        Assert $psgetModuleInfo.Includes.Cmdlet.Count "Cmdlets are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Cmdlet)"
    }

    
    
    
    
    
    
    It FindModuleUsingIncludesFunction {
        $psgetModuleInfo = Find-Module -Includes Function -Tag CommandsAndResource | Where-Object { $_.Name -eq "DscTestModule" }
        AssertNotNull $psgetModuleInfo.Includes "Includes is missing on PSGetModuleInfo, $($psgetModuleInfo.Includes)"
        Assert $psgetModuleInfo.Includes.DscResource.Count "DscResource are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.DscResource)"
        Assert $psgetModuleInfo.Includes.Command.Count "Commands are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Command)"
        Assert $psgetModuleInfo.Includes.Function.Count "Functions are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Function)"
        Assert $psgetModuleInfo.Includes.Cmdlet.Count "Cmdlets are missing on PSGetModuleInfo, $($psgetModuleInfo.Includes.Cmdlet)"
    }

    
    
    
    
    
    
    It FindRoleCapabilityWithSingleRoleCapabilityName {
        $psgetRoleCapabilityInfo = Find-RoleCapability -Name Lev1Maintenance
        AssertEquals $psgetRoleCapabilityInfo.Name 'Lev1Maintenance' "Lev1Maintenance is not returned by Find-RoleCapability, $psgetRoleCapabilityInfo"
    }

    
    
    
    
    
    
    It FindRoleCapabilityWithTwoRoleCapabilityNames {
        $psgetRoleCapabilityInfos = Find-RoleCapability -Name Lev1Maintenance, Lev2Maintenance

        AssertEquals $psgetRoleCapabilityInfos.Count 2 "Find-RoleCapability did not return the expected RoleCapabilities, $psgetRoleCapabilityInfos"

        Assert ($psgetRoleCapabilityInfos.Name -contains 'Lev1Maintenance') "Lev1Maintenance is not returned by Find-RoleCapability, $psgetRoleCapabilityInfos"
        Assert ($psgetRoleCapabilityInfos.Name -contains 'Lev2Maintenance') "Lev2Maintenance is not returned by Find-RoleCapability, $psgetRoleCapabilityInfos"
    }

    
    
    
    
    
    
    It FindDscResourceWithSingleResourceName {
        $psgetDscResourceInfo = Find-DscResource -Name DscTestResource
        AssertEquals $psgetDscResourceInfo.Name "DscTestResource" "DscTestResource is not returned by Find-DscResource, $psgetDscResourceInfo"
    }

    
    
    
    
    
    
    It FindDscResourceWithTwoResourceNames {
        $psgetDscResourceInfos = Find-DscResource -Name DscTestResource, NewDscTestResource

        Assert ($psgetDscResourceInfos.Count -ge 2) "Find-DscResource did not return the expected DscResources, $psgetDscResourceInfos"

        Assert ($psgetDscResourceInfos.Name -contains "DscTestResource") "DscTestResource is not returned by Find-DscResource, $psgetDscResourceInfos"
        Assert ($psgetDscResourceInfos.Name -contains "NewDscTestResource") "NewDscTestResource is not returned by Find-DscResource, $psgetDscResourceInfos"
    }


    
    
    
    
    
    
    It FindCommandWithSingleCommandName {
        $psgetCommandInfo = Find-Command -Name Get-ContosoServer
        AssertEquals $psgetCommandInfo.Name 'Get-ContosoServer' "Get-ContosoServer is not returned by Find-Command, $psgetCommandInfo"
    }

    
    
    
    
    
    
    It FindCommandWithTwoResourceNames {
        $psgetCommandInfos = Find-Command -Name Get-ContosoServer, Get-ContosoClient

        Assert ($psgetCommandInfos.Count -ge 2) "Find-Command did not return the expected command names, $psgetCommandInfos"

        Assert ($psgetCommandInfos.Name -contains 'Get-ContosoServer') "Get-ContosoServer is not returned by Find-Command, $psgetCommandInfos"
        Assert ($psgetCommandInfos.Name -contains 'Get-ContosoClient') "Get-ContosoClient is not returned by Find-Command, $psgetCommandInfos"
    }
}

Describe PowerShell.PSGet.FindModuleTests.P1 -Tags 'P1', 'OuterLoop' {

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    
    
    
    
    
    
    It "FindModuleWithPrefixWildcard" {
        $res = Find-Module *ontosoServer
        Assert ($res -and ($res.Name -eq "ContosoServer")) "Find-Module failed to get a module with wild card"
    }

    
    
    
    
    
    
    It "FindMultipleModulesWithWildcard" {
        $res = Find-Module Contoso*
        Assert ($res.Count -ge 3) "Find-Module failed to multiple modules with wild card"
    }

    
    
    
    
    
    
    It "FindModuleWithPostfixWildcard" {
        $res = Find-Module ContosoServe*
        Assert ($res -and ($res.Name -eq "ContosoServer")) "Find-Module failed to get a module with postfix wild card search"
    }

    
    
    
    
    
    
    It "FindModuleWithWildcards" {
        $res = Find-Module *ontosoServe*
        Assert ($res -and ($res.Name -eq "ContosoServer")) "Find-Module failed to find module using wild cards"
    }

    
    
    
    
    
    
    It FindModuleWithAllVersionsAndMinimumVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Find-Module ContosoClient -MinimumVersion 2.0 -Repository PSGallery -AllVersions } `
            -expectedFullyQualifiedErrorId 'AllVersionsCannotBeUsedWithOtherVersionParameters,Find-Module'
    }

    
    
    
    
    
    
    It FindModuleWithAllVersionsAndRequiredVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock { Find-Module ContosoClient -RequiredVersion 2.0 -Repository PSGallery -AllVersions } `
            -expectedFullyQualifiedErrorId 'AllVersionsCannotBeUsedWithOtherVersionParameters,Find-Module'
    }

    
    
    
    
    
    
    It FindModuleUsingFilterKeyWordNotExists {
        $psgetItemInfo = Find-Module -Filter KeyWordNotExists
        AssertNull $psgetItemInfo "Find-Module with filter is not working for KeyWordNotExists, $psgetItemInfo"
    }

    
    
    
    
    
    
    It FindModuleWithIncludeDependencies {
        $ModuleName = "ModuleWithDependencies1"

        $res1 = Find-Module -Name $ModuleName -MaximumVersion "1.0" -MinimumVersion "0.1"
        AssertEquals $res1.Name $ModuleName "Find-Module didn't find the exact module which has dependencies, $res1"

        $DepencyModuleNames = $res1.Dependencies.Name

        $res2 = Find-Module -Name $ModuleName -IncludeDependencies -MaximumVersion "1.0" -MinimumVersion "0.1"
        Assert ($res2.Count -ge ($DepencyModuleNames.Count + 1)) "Find-Module with -IncludeDependencies returned wrong results, $res2"

        $DepencyModuleNames | ForEach-Object { Assert ($res2.Name -Contains $_) "Find-Module with -IncludeDependencies didn't return the $_ module, $($res2.Name)" }
    }
}

Describe PowerShell.PSGet.FindModuleTests.P2 -Tags 'P2', 'OuterLoop' {

    BeforeAll {
        if (($PSEdition -eq 'Core') -or ($env:APPVEYOR_TEST_PASS -eq 'True')) {
            return
        }

        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    if (($PSEdition -eq 'Core') -or ($env:APPVEYOR_TEST_PASS -eq 'True')) {
        return
    }

    
    $ParameterSets = Get-FindModuleParameterSets

    $ParameterSetCount = $ParameterSets.Count
    $i = 1
    foreach ($inputParameters in $ParameterSets) {
        Write-Verbose -Message "Combination 
        Write-Verbose -Message "$($inputParameters | Out-String)"
        Write-Progress -Activity "Combination $i out of $ParameterSetCount" -PercentComplete $(($i / $ParameterSetCount) * 100)

        $params = $inputParameters.FindModuleInputParameters
        Write-Verbose -Message ($params | Out-String)

        $scriptBlock = { Find-Module @params }.GetNewClosure()

        It "FindModuleParameterCombinationsTests - Combination $i/$ParameterSetCount" {

            if ($inputParameters.PositiveCase) {
                $res = Invoke-Command -ScriptBlock $scriptBlock

                if ($inputParameters.ExpectedModuleCount -gt 1) {
                    Assert ($res.Count -ge $inputParameters.ExpectedModuleCount) "Combination 
                }
                else {
                    AssertEqualsCaseInsensitive $res.Name $inputParameters.ExpectedModuleNames "Combination 
                }
            }
            else {
                AssertFullyQualifiedErrorIdEquals -Scriptblock $scriptBlock -ExpectedFullyQualifiedErrorId $inputParameters.FullyQualifiedErrorId
            }
        }

        $i = $i + 1
    }
}


Describe "Azure Artifacts Credential Provider Integration" -Tags 'BVT' {

    BeforeAll {
        $repoName = "OneGetTestPrivateFeed"
        
        $testLocation = "https://pkgs.dev.azure.com/onegettest/_packaging/onegettest/nuget/v2";
        $username = "onegettest@hotmail.com"
        $PAT = "qo2xvzdnfi2mlcq3eq2jkoxup576kt4gnngcicqhup6bbix6sila"
        
        
        $VSS_NUGET_EXTERNAL_FEED_ENDPOINTS = "{'endpointCredentials': [{'endpoint':'$testLocation', 'username':'$username', 'password':'$PAT'}]}"
        [System.Environment]::SetEnvironmentVariable("VSS_NUGET_EXTERNAL_FEED_ENDPOINTS", $VSS_NUGET_EXTERNAL_FEED_ENDPOINTS, [System.EnvironmentVariableTarget]::Process)


        
        $VSinstalledCredProvider = $false;
        $programFiles = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ProgramFilesX86);
        $vswhereExePath = $programFiles + "\\Microsoft Visual Studio\\Installer\\vswhere.exe";
        $fullVSwhereExePath = [System.Environment]::ExpandEnvironmentVariables($vswhereExePath);
        
        if (Test-Path ($fullVSwhereExePath)) {
            $VSinstalledCredProvider = $true;
        }
    }

    AfterAll {
        UnRegister-PSRepository -Name $repoName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    }

    it "Register-PackageSource using Visual Studio installed credential provider" -Skip:(!$VSinstalledCredProvider) {
        Register-PSRepository $repoName -SourceLocation $testLocation

        (Get-PSRepository -Name $repoName).Name | should match $repoName
        (Get-PSRepository -Name $repoName).SourceLocation | should match $testLocation

        Unregister-PSRepository -Name $repoName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    }

    it "Register-PackageSource using credential provider" -Skip:(!$IsWindows) {
        
        
        iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/microsoft/artifacts-credprovider/master/helpers/installcredprovider.ps1'))

        Register-PSRepository $repoName -SourceLocation $testLocation

        (Get-PSRepository -Name $repoName).Name | should match $repoName
        (Get-PSRepository -Name $repoName).SourceLocation | should match $testLocation
    }

    it "Find-Package using credential provider" -Skip:(!$IsWindows) {
        $pkg = Find-Module * -Repository $repoName
        $pkg.Count | should -BeGreaterThan 0
    }
}
