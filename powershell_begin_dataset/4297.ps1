



. "$PSScriptRoot\PSGetTests.Manifests.ps1"
. "$PSScriptRoot\PSGetTests.Generators.ps1"

function SuiteSetup {
    Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue
    Import-Module "$PSScriptRoot\Asserts.psm1" -WarningAction SilentlyContinue

    $script:ProgramFilesModulesPath = Get-AllUsersModulesPath
    $script:MyDocumentsModulesPath = Get-CurrentUserModulesPath
    $script:PSGetLocalAppDataPath = Get-PSGetLocalAppDataPath
    $script:TempPath = Get-TempPath
    $script:BuiltInModuleSourceName = "PSGallery"

    $script:URI200OK = "http://go.microsoft.com/fwlink/?LinkID=533903&clcid=0x409"
    $script:URI404NotFound = "http://go.microsoft.com/fwlink/?LinkID=533902&clcid=0x409"

    
    Install-NuGetBinaries

    $script:PowerShellGetModuleInfo = Import-Module PowerShellGet -Global -Force -PassThru

    Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $PowerShellGetModuleInfo.ModuleBase

    
    $script:moduleSourcesFilePath= Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml"
    $script:moduleSourcesBackupFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml_$(get-random)_backup"
    if(Test-Path $script:moduleSourcesFilePath)
    {
        Rename-Item $script:moduleSourcesFilePath $script:moduleSourcesBackupFilePath -Force
    }

    $script:TestModuleSourceUri = ''
    GetAndSet-PSGetTestGalleryDetails -PSGallerySourceUri ([REF]$script:TestModuleSourceUri)

    
    $script:TestModuleSourceName = "PSGetTestModuleSource"
    Register-PSRepository -Name $script:TestModuleSourceName -SourceLocation $script:TestModuleSourceUri -InstallationPolicy Trusted

    $repo = Get-PSRepository -Name $script:BuiltInModuleSourceName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    if($repo)
    {
        Set-PSRepository -Name $script:BuiltInModuleSourceName -InstallationPolicy Trusted -ErrorAction SilentlyContinue
    }
    else
    {
        Register-PSRepository -Default -InstallationPolicy Trusted
    }

    $modSource = Get-PSRepository -Name $script:TestModuleSourceName
    AssertEquals $modSource.SourceLocation $script:TestModuleSourceUri "Test module source is not set properly"

    
    $script:TempModulesPath= Join-Path $script:TempPath "PSGet_$(Get-Random)"
    $null = New-Item -Path $script:TempModulesPath -ItemType Directory -Force
}

function SuiteCleanup {
    if(Test-Path $script:moduleSourcesBackupFilePath)
    {
        Move-Item $script:moduleSourcesBackupFilePath $script:moduleSourcesFilePath -Force
    }
    else
    {
        Unregister-PSRepository -Name $script:TestModuleSourceName
    }

    
    $null = Import-PackageProvider -Name PowerShellGet -Force

    RemoveItem $script:TempModulesPath
}

Describe PowerShell.PSGet.ModuleSourceTests -Tags 'BVT', 'InnerLoop' {

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    
    It RegisterAngGetModuleSource {

        $Name = 'MyTestModSourceForRegisterAngGet'
        $Location = 'https://www.nuget.org/api/v2/'

        Register-PSRepository -Default -ErrorAction SilentlyContinue

        try {
            Register-PSRepository -Name $Name -SourceLocation $Location
            $moduleSource = Get-PSRepository -Name $Name
            $allModuleSources = Get-PSRepository
            $defaultModuleSourceDetails = Get-PSRepository -Name $script:BuiltInModuleSourceName

            AssertEquals $moduleSource.Name $Name "The module source name is not same as the registered name"
            AssertEquals $moduleSource.SourceLocation $Location "The module source location is not same as the registered location"

            Assert (Test-Path $script:moduleSourcesFilePath) "Missing $script:moduleSourcesFilePath file after module source registration"

            Assert ($allModuleSources.Count -ge 3) "ModuleSources count should be >=3 with registed module source along with default PSGallery Source, $allModuleSources"

            AssertEquals $defaultModuleSourceDetails.Name $script:BuiltInModuleSourceName "The default module source name is not same as the expected module source name"
        }
        finally {
            Get-PSRepository -Name $Name -ErrorAction SilentlyContinue | Unregister-PSRepository
        }
    }

    
    It RegisterSMBShareRepository {

        $Name = 'MyTestModSource'
        $Location = $script:TempModulesPath
        try {
            Register-PSRepository -Name $Name -SourceLocation $Location -PublishLocation $Location
            $repo = Get-PSRepository -Name $Name

            AssertEquals $repo.Name $Name "The repository name is not same as the registered name. Actual: $($repo.Name), Expected: $Name"
            AssertEquals $repo.SourceLocation $Location "The SourceLocation is not same as the registered SourceLocation. Actual: $($repo.SourceLocation), Expected: $Location"
            AssertEquals $repo.PublishLocation $Location "The PublishLocation is not same as the registered PublishLocation. Actual: $($repo.PublishLocation), Expected: $Location"
        }
        finally {
            Get-PSRepository -Name $Name | Unregister-PSRepository
        }
    }

    
    It SetPSRepositoryWithSMBSharePath {

        $Name = 'MyTestModSource'
        $Location = $script:TempModulesPath
        try {
            Register-PSRepository -Name $Name -SourceLocation $Location
            Set-PSRepository -Name $Name -SourceLocation $Location -PublishLocation $Location
            $repo = Get-PSRepository -Name $Name

            AssertEquals $repo.Name $Name "The repository name is not same as the registered name. Actual: $($repo.Name), Expected: $Name"
            AssertEquals $repo.SourceLocation $Location "The SourceLocation is not same as the registered SourceLocation. Actual: $($repo.SourceLocation), Expected: $Location"
            AssertEquals $repo.PublishLocation $Location "The PublishLocation is not same as the registered PublishLocation. Actual: $($repo.PublishLocation), Expected: $Location"
        }
        finally {
            Get-PSRepository -Name $Name | Unregister-PSRepository
        }
    }

    
    It UnregisterModuleSource {

        $Name = 'MyTestModSource'
        $Location = 'https://www.nuget.org/api/v2/'

        Register-PSRepository -Name $Name -SourceLocation $Location
        Unregister-PSRepository -Name $Name

        $expectedFullyQualifiedErrorId = 'SourceNotFound,Microsoft.PowerShell.PackageManagement.Cmdlets.GetPackageSource'

        AssertFullyQualifiedErrorIdEquals -scriptblock {Get-PSRepository -Name $Name} `
            -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }
}
Describe PowerShell.PSGet.ModuleSourceTests.P1 -Tags 'P1','OuterLoop' {

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    
    It RegisterPSRepositoryWithInvalidSMBShareSourceLocation {

        $Name='MyTestModSource'
        $Location = Join-Path $script:TempPath 'DirNotAvailable'
        AssertFullyQualifiedErrorIdEquals -scriptblock {Register-PSRepository -Name $Name -SourceLocation $Location} `
                                          -expectedFullyQualifiedErrorId "PathNotFound,Register-PSRepository"
    }

    
    It RegisterPSRepositoryWithInvalidSMBSharePublishLocation {

        $Name='MyTestModSource'
        $Location=$script:TempModulesPath
        $PublishLocation = Join-Path $script:TempPath 'DirNotAvailable'
        AssertFullyQualifiedErrorIdEquals -scriptblock {Register-PSRepository -Name $Name -SourceLocation $Location -PublishLocation $PublishLocation} `
                                          -expectedFullyQualifiedErrorId "PathNotFound,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.RegisterPackageSource"
    }

    
    It SetPSRepositoryWithInvalidSMBShareSourceLocation {

        $Name='MyTestModSource'
        $Location=$script:TempModulesPath
        $Location2 = Join-Path $script:TempPath 'DirNotAvailable'
        try
        {
            Register-PSRepository -Name $Name -SourceLocation $Location
            AssertFullyQualifiedErrorIdEquals -scriptblock {Set-PSRepository -Name $Name -SourceLocation $Location2} `
                                              -expectedFullyQualifiedErrorId "PathNotFound,Set-PSRepository"
        }
        finally
        {
            Get-PSRepository -Name $Name | Unregister-PSRepository
        }
    }

    
    It SetPSRepositoryWithInvalidSMBSharePublishLocation {

        $Name='MyTestModSource'
        $Location=$script:TempModulesPath
        $Location2 = Join-Path $script:TempPath 'DirNotAvailable'
        try
        {
            Register-PSRepository -Name $Name -SourceLocation $Location -PublishLocation $Location
            AssertFullyQualifiedErrorIdEquals -scriptblock {Set-PSRepository -Name $Name -SourceLocation $Location -PublishLocation $Location2} `
                                              -expectedFullyQualifiedErrorId "PathNotFound,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.SetPackageSource"
        }
        finally
        {
            Get-PSRepository -Name $Name | Unregister-PSRepository
        }
    }

    
    It GetModuleSourceWithWildCards {
        $Name='MyTestModSource'
        $Location='https://www.nuget.org/api/v2/'
        try
        {
            Register-PSRepository -Name $Name -SourceLocation $Location
            $moduleSource = Get-PSRepository -Name 'MyTestModS*rce'

            AssertEquals $moduleSource.Name $Name "The module source name is not same as the registered name"
            AssertEquals $moduleSource.SourceLocation $Location "The module source location is not same as the registered location"

            Assert (Test-Path $script:moduleSourcesFilePath) "Missing $script:moduleSourcesFilePath file after module source registration"
        }
        finally
        {
            Get-PSRepository -Name $Name | Unregister-PSRepository
        }
    }

    
    It RegisterModuleSourceWithSameName {
        $Name='MyTestModSource'
        $Location='https://www.nuget.org/api/v2/'
        try
        {
            Register-PSRepository -Name $Name -SourceLocation $Location

            AssertFullyQualifiedErrorIdEquals -scriptblock {Register-PSRepository -Name $Name -SourceLocation $Location} `
                                              -expectedFullyQualifiedErrorId 'PackageSourceExists,Microsoft.PowerShell.PackageManagement.Cmdlets.RegisterPackageSource'
        }
        finally
        {
            Get-PSRepository -Name $Name | Unregister-PSRepository
        }
    }

    
    It RegisterModuleSourceWithAlreadyRegisteredLocation {
        $Name='MyTestModSource'
        $Location='https://www.nuget.org/api/v2/'
        try
        {
            Register-PSRepository -Name $Name -SourceLocation $Location

            $expectedFullyQualifiedErrorId = 'RepositoryAlreadyRegistered,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.RegisterPackageSource'

            AssertFullyQualifiedErrorIdEquals -scriptblock {Register-PSRepository -Name 'MyTestModSource2' -SourceLocation $Location} `
                                              -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
        }
        finally
        {
            Get-PSRepository -Name $Name | Unregister-PSRepository
        }
    }

    
    It RegisterModuleSourceWithNotAvailableLocation {

        $expectedFullyQualifiedErrorId = 'InvalidWebUri,Register-PSRepository'

        AssertFullyQualifiedErrorIdEquals -scriptblock {Register-PSRepository -Name myNuGetSource -SourceLocation https://www.nonexistingcompany.com/api/v2/} `
                                    -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }

    
    It RegisterModuleSourceWithNotAvailableLocation2 {

        $expectedFullyQualifiedErrorId = 'InvalidWebUri,Register-PSRepository'

        AssertFullyQualifiedErrorIdEquals -scriptblock {Register-PSRepository -Name myNuGetSource2 -SourceLocation https://www.nonexistingcompany.com} `
                                          -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }

    
    It RegisterModuleSourceWithInvalidWebUri {

        $expectedFullyQualifiedErrorId = 'PathNotFound,Register-PSRepository'

        AssertFullyQualifiedErrorIdEquals -scriptblock {Register-PSRepository -Name myNuGetSource1 -SourceLocation myget.org/F/powershellgetdemo} `
                                          -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }

    
    It RegisterModuleSourceWithWildCardInName {

        $expectedFullyQualifiedErrorId = 'RepositoryNameContainsWildCards,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.RegisterPackageSource'

        AssertFullyQualifiedErrorIdEquals -scriptblock {Register-PSRepository -Name my*NuGetSource -SourceLocation https://www.myget.org/F/powershellgetdemo} `
                                          -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }

    
    It GetNonRegisteredModuleSource {

        $expectedFullyQualifiedErrorId = 'SourceNotFound,Microsoft.PowerShell.PackageManagement.Cmdlets.GetPackageSource'

        AssertFullyQualifiedErrorIdEquals -scriptblock {Get-PSRepository -Name 'MyTestModSourceNotRegistered'} `
                                          -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }

    
    It GetNonRegisteredModuleSourceNameWithWildCards {
        $moduleSources = Get-PSRepository -Name 'MyTestModSourceNotRegiste*ed' -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        AssertNull $moduleSources "Get-PSRepository should not return the $moduleSources module source"
    }

    
    It UnregisterModuleSourceWithWildCards {
        $Name='MyTestModSource'
        $Location='https://www.nuget.org/api/v2/'
        try
        {
            Register-PSRepository -Name $Name -SourceLocation $Location

            AssertFullyQualifiedErrorIdEquals -scriptblock {Unregister-PSRepository -Name 'MyTestMo*ource'} `
                                              -expectedFullyQualifiedErrorId 'RepositoryNameContainsWildCards,Unregister-PSRepository'
        }
        finally
        {
            Get-PSRepository $Name -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Unregister-PSRepository
        }
    }

    
    It UnregisterBuiltinModuleSource {
        try {
            Unregister-PSRepository -Name $script:BuiltInModuleSourceName

            $expectedFullyQualifiedErrorId = 'SourceNotFound,Microsoft.PowerShell.PackageManagement.Cmdlets.GetPackageSource'
            AssertFullyQualifiedErrorIdEquals -scriptblock {Get-PSRepository -Name $script:BuiltInModuleSourceName} `
                                              -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId

            $expectedFullyQualifiedErrorId = 'PSGalleryNotFound,Publish-Module'
            AssertFullyQualifiedErrorIdEquals -scriptblock {Publish-Module -Name MyTempModule} `
                                              -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
        }
        finally {
            Register-PSRepository -Default -InstallationPolicy Trusted
        }
    } `
    -Skip:$($PSEdition -eq 'Core')

    
    It UnregisterNotRegisteredModuleSource {

        $expectedFullyQualifiedErrorId = 'SourceNotFound,Microsoft.PowerShell.PackageManagement.Cmdlets.UnregisterPackageSource'

        AssertFullyQualifiedErrorIdEquals -scriptblock {Unregister-PSRepository -Name "NonAvailableModuleSource"} `
                                          -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }

    It RegisterPSRepositoryShouldFailWithPSModuleAsPMProviderName {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Register-PSRepository -Name Foo -SourceLocation $script:TempPath -PackageManagementProvider PowerShellGet} `
                                          -expectedFullyQualifiedErrorId "InvalidPackageManagementProviderValue,Register-PSRepository"
    }

    It SetPSRepositoryShouldFailWithPSModuleAsPMProviderName {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Set-PSRepository -Name PSGallery -PackageManagementProvider PowerShellGet} `
                                          -expectedFullyQualifiedErrorId "InvalidPackageManagementProviderValue,Set-PSRepository"
    }

    It RegisterPackageSourceShouldFailWithPSModuleAsPMProviderName {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Register-PackageSource -ProviderName PowerShellGet -Name Foo -Location $script:TempPath -PackageManagementProvider PowerShellGet} `
                                          -expectedFullyQualifiedErrorId "InvalidPackageManagementProviderValue,Add-PackageSource,Microsoft.PowerShell.PackageManagement.Cmdlets.RegisterPackageSource"
    }
}

Describe PowerShell.PSGet.FindModule.ModuleSourceTests.P1 -Tags 'P1','OuterLoop' {

    
    
    if($IsMacOS) {
        return
    }

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    
    $ParameterSets = Get-FindModuleWithSourcesParameterSets
    $ParameterSetCount = $ParameterSets.Count
    $i = 1
    foreach ($inputParameters in $ParameterSets)
    {
        Write-Verbose -Message "Combination 
        Write-Verbose -Message "$($inputParameters | Out-String)"
        Write-Progress -Activity "Combination $i out of $ParameterSetCount" -PercentComplete $(($i/$ParameterSetCount) * 100)

        $scriptBlock = $null
        if($inputParameters.Name -and $inputParameters.Source)
        {
            $scriptBlock = { Find-Module -Name $inputParameters.Name -Repository $inputParameters.Source }.GetNewClosure()
        }
        elseif($inputParameters.Name)
        {
            $scriptBlock = { Find-Module -Name $inputParameters.Name }.GetNewClosure()
        }
        elseif($inputParameters.Source)
        {
            $scriptBlock = { Find-Module -Repository $inputParameters.Source }.GetNewClosure()
        }
        else
        {
            $scriptBlock = { Find-Module }
        }

        It "FindModuleWithModuleSourcesTests - Combination $i/$ParameterSetCount" {
            if($inputParameters.PositiveCase)
            {
                $res = Invoke-Command -ScriptBlock $scriptBlock

                if($inputParameters.ExpectedModuleCount -gt 1)
                {
                    Assert ($res.Count -ge $inputParameters.ExpectedModuleCount) "Combination 
                }
                else
                {
                    AssertEqualsCaseInsensitive $res.Name $inputParameters.Name "Combination 
                }
            }
            else
            {
                AssertFullyQualifiedErrorIdEquals -scriptblock $scriptBlock -expectedFullyQualifiedErrorId $inputParameters.FullyQualifiedErrorID
            }
        }

        $i = $i+1
    }
}

Describe PowerShell.PSGet.InstallModule.ModuleSourceTests.P1 -Tags 'P1','OuterLoop' {

    
    
    if($IsMacOS) {
        return
    }

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    
    $ParameterSets = Get-InstallModuleWithSourcesParameterSets
    $ParameterSetCount = $ParameterSets.Count
    $i = 1
    foreach ($inputParameters in $ParameterSets)
    {
        Write-Verbose -Message "Combination 
        Write-Verbose -Message "$($inputParameters | Out-String)"
        Write-Progress -Activity "Combination $i out of $ParameterSetCount" -PercentComplete $(($i/$ParameterSetCount) * 100)

        $scriptBlock = $null
        if($inputParameters.Source)
        {
            $scriptBlock = { Install-Module -Name $inputParameters.Name -Repository $inputParameters.Source }.GetNewClosure()
        }
        else
        {
            $scriptBlock = { Install-Module -Name $inputParameters.Name }.GetNewClosure()
        }

        It "InstallModuleWithModuleSourcesTests - Combination $i/$ParameterSetCount" {
            try {
                if($inputParameters.PositiveCase)
                {
                    Invoke-Command -ScriptBlock $scriptBlock

                    $res = Get-Module -ListAvailable -Name $inputParameters.Name

                    AssertEqualsCaseInsensitive $res.Name $inputParameters.Name "Combination 
                }
                else
                {
                    AssertFullyQualifiedErrorIdEquals -scriptblock $scriptBlock -expectedFullyQualifiedErrorId $inputParameters.FullyQualifiedErrorID
                }
            } finally {
                PSGetTestUtils\Uninstall-Module $inputParameters.Name
            }
        }

        $i = $i+1
    }
}