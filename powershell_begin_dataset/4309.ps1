



function SuiteSetup {
    Import-Module "$PSScriptRoot\PSGetTestUtils.psm1" -WarningAction SilentlyContinue
    Import-Module "$PSScriptRoot\Asserts.psm1" -WarningAction SilentlyContinue

    $script:IsWindowsOS = (-not (Get-Variable -Name IsWindows -ErrorAction Ignore)) -or $IsWindows
    $script:ProgramFilesModulesPath = Get-AllUsersModulesPath
    $script:MyDocumentsModulesPath = Get-CurrentUserModulesPath
    $script:PSGetLocalAppDataPath = Get-PSGetLocalAppDataPath
    $script:TempPath = Get-TempPath

    $null = New-Item -Path $script:MyDocumentsModulesPath -ItemType Directory -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    
    Install-NuGetBinaries

    $psgetModuleInfo = Import-Module PowerShellGet -Global -Force -Passthru
    Import-LocalizedData  script:LocalizedData -filename PSGet.Resource.psd1 -BaseDirectory $psgetModuleInfo.ModuleBase

    $script:moduleSourcesFilePath= Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml"
    $script:moduleSourcesBackupFilePath = Join-Path $script:PSGetLocalAppDataPath "PSRepositories.xml_$(get-random)_backup"
    if(Test-Path $script:moduleSourcesFilePath)
    {
        Rename-Item $script:moduleSourcesFilePath $script:moduleSourcesBackupFilePath -Force
    }

    $Global:PSGallerySourceUri  = ''
    GetAndSet-PSGetTestGalleryDetails -SetPSGallery -PSGallerySourceUri ([REF]$Global:PSGallerySourceUri)

    PSGetTestUtils\Uninstall-Module ContosoServer
    PSGetTestUtils\Uninstall-Module ContosoClient

    if($script:IsWindowsOS)
    {
        $script:userName = "PSGetUser"
        $password = "Password1"
        
        net user $script:UserName /delete 2>&1 | Out-Null
        $null = net user $script:userName $password /add
        $secstr = ConvertTo-SecureString $password -AsPlainText -Force
        $script:credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $script:userName, $secstr
    }

    $script:assertTimeOutms = 20000
    $script:UntrustedRepoSourceLocation = 'https://powershell.myget.org/F/powershellget-test-items/api/v2/'
    $script:UntrustedRepoPublishLocation = 'https://powershell.myget.org/F/powershellget-test-items/api/v2/package'

    
    $script:TempModulesPath = Join-Path -Path $script:TempPath -ChildPath "PSGet_$(Get-Random)"
    $script:TestPSModulePath = Join-Path -Path $script:TempPath -ChildPath "PSGet_$(Get-Random)"
    $null = New-Item -Path $script:TempModulesPath -ItemType Directory -Force
    $null = New-Item -Path $script:TestPSModulePath -ItemType Directory -Force

    
    $script:localGalleryName = [System.Guid]::NewGuid().ToString()
    $script:PSGalleryRepoPath = Join-Path -Path $script:TempPath -ChildPath 'PSGalleryRepo'
    RemoveItem $script:PSGalleryRepoPath
    $null = New-Item -Path $script:PSGalleryRepoPath -ItemType Directory -Force

    Set-PSGallerySourceLocation -Name $script:localGalleryName -Location $script:PSGalleryRepoPath -PublishLocation $script:PSGalleryRepoPath -UseExistingModuleSourcesFile

    
    if ((Get-Module PKI -ListAvailable)) {
        $pesterDestination = Join-Path -Path $script:TempModulesPath -ChildPath "Pester"
        $pesterv1Destination = Join-Path -Path $pesterDestination -ChildPath "99.99.99.98"
        $pesterv2Destination = Join-Path -Path $pesterDestination -ChildPath "99.99.99.99"
        if (Test-Path -Path $pesterDestination) {
            $null = Remove-Item -Path $pesterDestination -Force
        }

        $null = New-Item -Path $pesterDestination -Force -ItemType Directory
        $null = New-Item -Path $pesterv1Destination -Force -ItemType Directory
        $null = New-Item -Path $pesterv2Destination -Force -ItemType Directory

        $null = New-ModuleManifest -Path (Join-Path -Path $pesterv1Destination -ChildPath "Pester.psd1") -Description "Test signed module v1" -ModuleVersion 99.99.99.98
        $null = New-ModuleManifest -Path (Join-Path -Path $pesterv2Destination -ChildPath "Pester.psd1") -Description "Test signed module v2" -ModuleVersion 99.99.99.99

        
        
        
        
        
        $signedPester = (Get-Module Pester -ListAvailable | Where-Object { $_.Version -eq '3.4.0' }).ModuleBase
        if (-not $signedPester) {
            $psName = [System.Guid]::NewGuid().ToString()
            Register-PackageSource -Name $psName -Location "https://www.powershellgallery.com/api/v2" -ProviderName PowerShellGet -Trusted
            try {
                Save-Module Pester -RequiredVersion 3.4.0 -Repository $psName -Path $script:TestPSModulePath
            } finally {
                Unregister-PackageSource -Name $psName
            }
        } else {
            $signedPesterDestination = Join-Path -Path $script:TestPSModulePath -ChildPath "Pester"
            if (-not (Test-Path -Path $signedPesterDestination)) {
                $null = New-Item -Path $signedPesterDestination -ItemType Directory
            }
            Copy-Item -Path $signedPester -Destination $signedPesterDestination -Recurse -Force
        }

        $csCert = Get-CodeSigningCert -IncludeLocalMachineCerts
        if (-not $csCert) {
            Create-CodeSigningCert
            $csCert = Get-CodeSigningCert -IncludeLocalMachineCerts
        }

        $null = Set-AuthenticodeSignature -FilePath (Join-Path -Path $pesterv1Destination -ChildPath "Pester.psd1") -Certificate $csCert
        $null = Set-AuthenticodeSignature -FilePath (Join-Path -Path $pesterv2Destination -ChildPath "Pester.psd1") -Certificate $csCert
    }
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

    if($script:IsWindowsOS)
    {
        
        net user $script:UserName /delete | Out-Null
        
        
        if(Get-Command -Name Get-WmiObject -ErrorAction SilentlyContinue)
        {
            $userProfile = (Get-WmiObject -Class Win32_UserProfile | Where-Object {$_.LocalPath -match $script:UserName})
            if($userProfile)
            {
                RemoveItem $userProfile.LocalPath
            }
        }
    }

    RemoveItem $script:TempModulesPath
    RemoveItem $script:TestPSModulePath
}

Describe PowerShell.PSGet.InstallModuleTests -Tags 'BVT','InnerLoop' {

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    AfterEach {
        PSGetTestUtils\Uninstall-Module Contoso
        PSGetTestUtils\Uninstall-Module ContosoServer
        PSGetTestUtils\Uninstall-Module ContosoClient
        PSGetTestUtils\Uninstall-Module DscTestModule
    }

    
    
    
    
    
    
    It "Install-Module ContosoServer should return be silent" {
        $result = Install-Module -Name "ContosoServer"
        $result | Should -BeNullOrEmpty
    }

    
    
    
    
    
    
    It "Install-Module ContosoServer -PassThru should return output" {
        $result = Install-Module -Name "ContosoServer" -PassThru
        $result | Should -Not -BeNullOrEmpty
    }

    
    
    
    
    
    
    It "InstallNotAvailableModuleWithWildCard" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Install-Module -Name "Co[nN]t?soS[a-z]r?eW"} `
                                          -expectedFullyQualifiedErrorId 'NameShouldNotContainWildcardCharacters,Install-Module'
    }

    
    
    
    
    
    
    It "InstallModuleWithVersionParams" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Install-Module ContosoServer -MinimumVersion 1.0 -RequiredVersion 5.0} `
                                          -expectedFullyQualifiedErrorId "VersionRangeAndRequiredVersionCannotBeSpecifiedTogether,Install-Module"
    }

    
    
    
    
    
    
    It "InstallMultipleNamesWithReqVersion" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Install-Module ContosoClient,ContosoServer -RequiredVersion 2.0} `
                                          -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Install-Module"
    }

    
    
    
    
    
    
    It "InstallMultipleNamesWithMinVersion" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Install-Module ContosoClient,ContosoServer -MinimumVersion 2.0} `
                                          -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Install-Module"
    }

    
    
    
    
    
    
    It "InstallMultipleModules" {
        Install-Module ContosoClient,ContosoServer
        $res = Get-Module ContosoClient,ContosoServer -ListAvailable
        Assert ($res.Count -eq 2) "Install-Module with multiple names should not fail"
    }

    
    
    
    
    
    
    It "InstallSingleModule" {
        Install-Module ContosoServer
        $res = Get-Module ContosoServer -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ContosoServer")) "Install-Module failed to install ContosoServer"
    }

    
    
    
    
    
    
    It "InstallAModuleWithMinVersion" {
        Install-Module ContosoServer -MinimumVersion 1.0
        $res = Get-Module ContosoServer -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ContosoServer") -and ($res.Version -ge [Version]"2.5")) "Install-Module failed to install with Version"
    }

    
    
    
    
    
    
    It "InstallAModuleWithReqVersion" {
        Install-Module ContosoServer -RequiredVersion 1.5
        $res = Get-Module ContosoServer -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ContosoServer") -and ($res.Version -eq [Version]"1.5")) "Install-Module failed to install with Version"
    }

    
    
    
    
    
    
    It "InstallModuleShouldFailIfReqVersionNotAlreadyInstalled" {
        Install-Module ContosoServer -RequiredVersion 1.5

        $expectedFullyQualifiedErrorId = 'ModuleAlreadyInstalled,Install-Package,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'

        AssertFullyQualifiedErrorIdEquals -scriptblock {Install-Module ContosoServer -RequiredVersion 2.0 -WarningAction SilentlyContinue} `
                                          -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }

    
    
    
    
    
    
    It "InstallModuleShouldFailIfMinVersionNotAlreadyInstalled" {
        Install-Module ContosoServer -RequiredVersion 1.5

        $expectedFullyQualifiedErrorId = 'ModuleAlreadyInstalled,Install-Package,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'

        AssertFullyQualifiedErrorIdEquals -scriptblock {Install-Module ContosoServer -MinimumVersion 2.0 -WarningAction SilentlyContinue} `
                                          -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }

    
    
    
    
    
    
    It "InstallModuleShouldNotFailIfReqVersionAlreadyInstalled" {
        Install-Module ContosoServer -RequiredVersion 2.0
        $MyError=$null
        Install-Module ContosoServer -RequiredVersion 2.0 -ErrorVariable MyError
        Assert ($MyError.Count -eq 0) "There should not be any error from second install with required, $MyError"
    }

    
    
    
    
    
    
    It "InstallModuleShouldNotFailIfMinVersionAlreadyInstalled" {
        Install-Module ContosoServer -RequiredVersion 2.5
        $MyError=$null
        Install-Module ContosoServer -MinimumVersion 2.0 -ErrorVariable MyError
        Assert ($MyError.Count -eq 0) "There should not be any error from second install with min version, $MyError"
    }

    
    
    
    
    
    
    
    
    It InstallModuleWithForce {
        Install-Module ContosoServer -RequiredVersion 1.0
        $MyError=$null
        Install-Module ContosoServer -RequiredVersion 1.5 -Force -ErrorVariable MyError
        Assert ($MyError.Count -eq 0) "There should not be any error from force install, $MyError"

        if(Test-ModuleSxSVersionSupport)
        {
            $res = Get-Module -FullyQualifiedName @{ModuleName='ContosoServer';RequiredVersion='1.5'} -ListAvailable
        }
        else
        {
            $res = Get-Module ContosoServer -ListAvailable
        }

        Assert (($res.Count -eq 1) -and ($res.Name -eq "ContosoServer") -and ($res.Version -eq [Version]"1.5")) "Install-Module with existing module should be overwritten if force is specified"
    }

    
    
    
    
    
    
    
    
    It InstallModuleSameVersionWithForce {
        Install-Module ContosoServer -RequiredVersion 1.5
        $MyError=$null
        Install-Module ContosoServer -RequiredVersion 1.5 -Force -ErrorVariable MyError
        Assert ($MyError.Count -eq 0) "There should not be any error from force install, $MyError"
        $res = Get-Module ContosoServer -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ContosoServer") -and ($res.Version -eq [Version]"1.5")) "Install-Module with existing module should be overwritten if force is specified"
    }

    
    
    
    
    
    
    It "InstallModuleWithNotAvailableMinVersion" {

        $expectedFullyQualifiedErrorId = 'NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'

        AssertFullyQualifiedErrorIdEquals -scriptblock {Install-Module ContosoServer -MinimumVersion 10.0} `
                                          -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }

    
    
    
    
    
    
    It "InstallModuleWithNotAvailableReqVersion" {

        $expectedFullyQualifiedErrorId = 'NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'

        AssertFullyQualifiedErrorIdEquals -scriptblock {Install-Module ContosoServer -RequiredVersion 1.44} `
                                          -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }

    
    
    
    
    
    
    It "InstallModuleWithReqVersion" {
        Install-Module ContosoServer -RequiredVersion 1.5 -Confirm:$false
        $res = Get-Module ContosoServer -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ContosoServer")-and ($res.Version -eq [Version]"1.5")) "Install-Module failed to install with RequiredVersion"
    }

    
    
    
    
    
    
    It "InstallModuleWithMinVersion" {
        Install-Module ContosoServer -MinimumVersion 1.5
        $res = Get-Module ContosoServer -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ContosoServer")-and ($res.Version -ge [Version]"2.5")) "Install-Module failed to install with MinimumVersion"
    }

    
    
    
    
    
    
    It "InstallNotAvailableModule" {

        $expectedFullyQualifiedErrorId = 'NoMatchFoundForCriteria,Microsoft.PowerShell.PackageManagement.Cmdlets.InstallPackage'

        AssertFullyQualifiedErrorIdEquals -scriptblock {Install-Module NonExistentModule} `
                                          -expectedFullyQualifiedErrorId $expectedFullyQualifiedErrorId
    }

    
    
    
    
    
    
    It "InstallModuleWithPipelineInput" {
        Find-Module ContosoServer | Install-Module
        $res = Get-Module ContosoServer -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ContosoServer")) "Install-Module failed to install ContosoServer with pipeline input"
    }

    
    
    
    
    
    
    It "InstallMultipleModulesWithPipelineInput" {
        Find-Module ContosoClient,ContosoServer | Install-Module
        $res = Get-Module ContosoClient,ContosoServer -ListAvailable
        Assert ($res.Count -eq 2) "Install-Module failed to install multiple modules from Find-Module output"
    }

    
    
    
    
    
    
    It "InstallMultipleModulesUsingInputObjectParam" {
        $items = Find-Module ContosoClient,ContosoServer
        Install-Module -InputObject $items
        $res = Get-Module ContosoClient,ContosoServer -ListAvailable
        Assert ($res.Count -eq 2) "Install-Module failed to install multiple modules with -InputObject parameter"
    }

    
    
    
    
    
    
    It "InstallToCurrentUserScopeWithPipelineInput" {
        Find-Module ContosoServer | Install-Module -Scope CurrentUser
        $mod = Get-Module ContosoServer -ListAvailable
        Assert ($mod.ModuleBase.StartsWith($script:MyDocumentsModulesPath, [System.StringComparison]::OrdinalIgnoreCase)) "Install-Module with CurrentUser scope did not install ContosoServer to user documents folder"
    }

    
    
    
    
    
    
    It "InstallToCurrentUserScope" {
        Install-Module ContosoServer -Scope CurrentUser
        $mod = Get-Module ContosoServer -ListAvailable
        Assert ($mod.ModuleBase.StartsWith($script:MyDocumentsModulesPath, [System.StringComparison]::OrdinalIgnoreCase)) "Install-Module with CurrentUser scope did not install ContosoServer to user documents folder"
    }

    
    
    
    
    
    
    It "InstallModuleWithForceAndDifferentScope" {
        Install-Module ContosoServer -Scope CurrentUser -RequiredVersion 1.0
        $mod1 = Get-Module ContosoServer -ListAvailable
        Assert ($mod1.ModuleBase.StartsWith($script:MyDocumentsModulesPath, [System.StringComparison]::OrdinalIgnoreCase)) "Install-Module with CurrentUser scope did not install ContosoServer to user documents folder, $mod1"

        Install-Module ContosoServer -Scope AllUsers -Force -RequiredVersion 2.5

        $mod2 = Get-Module ContosoServer -ListAvailable
        AssertEquals $mod2.Count 2 "Only two modules should be available after changing the -Scope with -Force and without -AllowClobber on Install-Module cmdlet, $mod2"

        $mod3 = Get-InstalledModule ContosoServer -RequiredVersion 2.5
        AssertNotNull $mod3 "Install-Module with Force and without AllowClobber should install the module to a different scope, $mod3"
    }

    It "InstallModuleWithForceAllowClobberAndDifferentScope" {
        Install-Module ContosoServer -Scope CurrentUser
        $mod1 = Get-Module ContosoServer -ListAvailable
        Assert ($mod1.ModuleBase.StartsWith($script:MyDocumentsModulesPath, [System.StringComparison]::OrdinalIgnoreCase)) "Install-Module with CurrentUser scope did not install ContosoServer to user documents folder, $mod1"

        Install-Module ContosoServer -Scope AllUsers -Force -AllowClobber
        $mod2 = Get-Module ContosoServer -ListAvailable
        Assert ($mod2.Count -ge 2) "Atleast two versions of ContosoServer should be available after changing the -Scope with -Force and without -AllowClobber on Install-Module cmdlet, $mod2"
    }

    
    
    
    
    
    
    It "InstallModuleWithAllUsersScopeParameterForNonAdminUser" {
        $NonAdminConsoleOutput = Join-Path ([System.IO.Path]::GetTempPath()) 'nonadminconsole-out.txt'

        $psProcess = "$pshome\PowerShell.exe"
        if ($script:IsCoreCLR)
        {
            $psProcess = "$pshome\pwsh.exe"
        }

        Start-Process $psProcess -ArgumentList '-command if(-not (Get-PSRepository -Name PoshTest -ErrorAction SilentlyContinue)) {
                                                Register-PSRepository -Name PoshTest -SourceLocation https://www.poshtestgallery.com/api/v2/ -InstallationPolicy Trusted
                                                }
                                                Install-Module -Name ContosoServer -scope AllUsers -Repository PoshTest -ErrorVariable ev -ErrorAction SilentlyContinue;
                                                Write-Output "$ev"' `
                                -Credential $script:credential `
                                -Wait `
                                -WorkingDirectory $PSHOME `
                                -RedirectStandardOutput $NonAdminConsoleOutput

        waitFor {Test-Path $NonAdminConsoleOutput} -timeoutInMilliseconds $script:assertTimeOutms -exceptionMessage "Install-Module on non-admin console failed to complete"
        $content = Get-Content $NonAdminConsoleOutput
        RemoveItem $NonAdminConsoleOutput

        AssertNotNull ($content) "Install-Module with AllUsers scope on non-admin user console should not succeed"
        Assert ($content -match "Administrator rights are required to install") "Install module with AllUsers scope on non-admin user console should fail, $content"
    } `
    -Skip:$(
        $whoamiValue = (whoami)

        ($whoamiValue -eq "NT AUTHORITY\SYSTEM") -or
        ($whoamiValue -eq "NT AUTHORITY\LOCAL SERVICE") -or
        ($whoamiValue -eq "NT AUTHORITY\NETWORK SERVICE") -or
        ($PSVersionTable.PSVersion -lt '4.0.0') -or
        (-not $script:IsWindowsOS) -or
        
        ($script:IsCoreCLR)

    )

    
    
    
    
    
    
    It "InstallModuleDefaultUserScopeParameterForNonAdminUser" {
        $NonAdminConsoleOutput = Join-Path ([System.IO.Path]::GetTempPath()) 'nonadminconsole-out.txt'

        $psProcess = "PowerShell.exe"
        if ($script:IsCoreCLR)
        {
            $psProcess = "pwsh.exe"
        }

        Start-Process $psProcess -ArgumentList '-command Install-Module -Name ContosoServer -Repository PoshTest;
                                                Get-InstalledModule -Name ContosoServer | Format-List Name, InstalledLocation' `
                                               -Credential $script:credential `
                                               -Wait `
                                               -WorkingDirectory $PSHOME `
                                               -RedirectStandardOutput $NonAdminConsoleOutput

        waitFor {Test-Path $NonAdminConsoleOutput} -timeoutInMilliseconds $script:assertTimeOutms -exceptionMessage "Install-Module on non-admin console failed to complete"
        $content = Get-Content $NonAdminConsoleOutput
        RemoveItem $NonAdminConsoleOutput

        AssertNotNull ($content) "Install-Module with default current user scope on non-admin user console should succeed"
        Assert ($content -match "ContosoServer") "Module did not install correctly"
        Assert ($content -match "Documents") "Module did not install to the correct location"
    } `
    -Skip:$(
        $whoamiValue = (whoami)

        ($whoamiValue -eq "NT AUTHORITY\SYSTEM") -or
        ($whoamiValue -eq "NT AUTHORITY\LOCAL SERVICE") -or
        ($whoamiValue -eq "NT AUTHORITY\NETWORK SERVICE") -or
        ($PSVersionTable.PSVersion -lt '4.0.0') -or
        (-not $script:IsWindowsOS) -or
        
        ($script:IsCoreCLR)
    )

    
    
    
    
    
    
    It "ValidateModuleIsInUseError" {
        $NonAdminConsoleOutput = Join-Path ([System.IO.Path]::GetTempPath()) 'nonadminconsole-out.txt'
        Start-Process "$PSHOME\PowerShell.exe" -ArgumentList '$null = Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser;
                                                              $null = Import-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force;
                                                              Install-Module -Name DscTestModule -Scope CurrentUser;
                                                              Import-Module -Name DscTestModule;
                                                              Install-Module -Name DscTestModule -Scope CurrentUser -Force' `
                                               -Wait `
                                               -RedirectStandardOutput $NonAdminConsoleOutput
        waitFor {Test-Path $NonAdminConsoleOutput} -timeoutInMilliseconds $script:assertTimeOutms -exceptionMessage "Install-Module on non-admin console failed to complete"
        $content = Get-Content $NonAdminConsoleOutput

        Assert ($content -and ($content -match 'DscTestModule')) "Install-module with -force should fail when a module version being installed is in use, $content."
        RemoveItem $NonAdminConsoleOutput
    } `
    -Skip:$(
        $whoamiValue = (whoami)

        ($PSEdition -eq 'Core') -or
        ($whoamiValue -eq "NT AUTHORITY\SYSTEM") -or
        ($whoamiValue -eq "NT AUTHORITY\LOCAL SERVICE") -or
        ($whoamiValue -eq "NT AUTHORITY\NETWORK SERVICE") -or
        ($PSCulture -ne 'en-US') -or
        ($PSVersionTable.PSVersion -lt '5.0.0')
    )

    
    
    
    
    
    
    It "InstallModuleWithWhatIf" {
        $outputPath = $script:TempPath
        $guid =  [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1
        $content = $null

        try
        {
            $result = ExecuteCommand $runspace 'Install-Module -Name ContosoServer -WhatIf'
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

        $itemInfo = Find-Module ContosoServer -Repository PSGallery
        $installShouldProcessMessage = $script:LocalizedData.InstallModulewhatIfMessage -f ($itemInfo.Name, $itemInfo.Version)
        Assert ($content -and ($content -match $installShouldProcessMessage)) "Install module whatif message is missing, Expected:$installShouldProcessMessage, Actual:$content"

        $mod = Get-Module ContosoServer -ListAvailable
        Assert (-not $mod) "Install-Module should not install the module with -WhatIf option"
    } `
    -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    
    
    
    
    
    
    It "InstallModuleWithConfirmAndNoToPrompt" {
        $outputPath = $script:TempPath
        $guid =  [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        
        $Global:proxy.UI.ChoiceToMake=2
        $content = $null

        try
        {
            $result = ExecuteCommand $runspace 'Install-Module ContosoServer -Repository PSGallery -Confirm'
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

        $itemInfo = Find-Module ContosoServer -Repository PSGallery

        $installShouldProcessMessage = $script:LocalizedData.InstallModulewhatIfMessage -f ($itemInfo.Name, $itemInfo.Version)
        Assert ($content -and ($content -match $installShouldProcessMessage)) "Install module confirm prompt is not working, Expected:$installShouldProcessMessage, Actual:$content"

        $res = Get-Module ContosoServer -ListAvailable
        AssertNull $res "Install-Module should not install a module if Confirm is not accepted"
    } `
    -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    
    
    
    
    
    
    It "InstallModuleWithConfirmAndYesToPrompt" {
        $outputPath = $script:TempPath
        $guid =  [system.guid]::newguid().tostring()
        $outputFilePath = Join-Path $outputPath "$guid"
        $runspace = CreateRunSpace $outputFilePath 1

        
        $Global:proxy.UI.ChoiceToMake=0
        $content = $null

        try
        {
            $result = ExecuteCommand $runspace 'Find-Module ContosoServer | Install-Module -Confirm'
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

        $itemInfo = Find-Module ContosoServer -Repository PSGallery

        $installShouldProcessMessage = $script:LocalizedData.InstallModulewhatIfMessage -f ($itemInfo.Name, $itemInfo.Version)
        Assert ($content -and ($content -match $installShouldProcessMessage)) "Install module confirm prompt is not working, Expected:$installShouldProcessMessage, Actual:$content"

        $res = Get-Module ContosoServer -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ContosoServer")) "Install-Module should install a module if Confirm is accepted"
    } `
    -Skip:$(($PSEdition -eq 'Core') -or ([System.Environment]::OSVersion.Version -lt "6.2.9200.0") -or ($PSCulture -ne 'en-US'))

    
    
    
    
    
    
    It ValidatePSGetPropertiesOnPSModuleInfoFromGetModule {
        Install-Module ContosoServer -Repository PSGallery
        $res = Get-Module ContosoServer -ListAvailable
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ContosoServer") -and ($res.Version -ge [Version]"2.5")) "Install-Module failed to install ContosoServer"
        AssertNotNull $res.Tags "Tags value is missing on PSModuleInfo"
        AssertNotNull $res.LicenseUri "LicenseUri value is missing on PSModuleInfo"
        AssertNotNull $res.ProjectUri "ProjectUri value is missing on PSModuleInfo"
        AssertNotNull $res.IconUri "IconUri value is missing on PSModuleInfo"
        AssertNotNull $res.ReleaseNotes "ReleaseNotes value is missing on PSModuleInfo"
        AssertNotNull $res.RepositorySourceLocation "RepositorySourceLocation value is missing on PSModuleInfo"
    } -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')

    
    
    
    
    
    
    It InstallModuleUsingFindRoleCapabilityOutput {
        $moduleName = "DscTestModule"
        Find-RoleCapability -Name Lev1Maintenance,Lev2Maintenance | Where-Object {$_.ModuleName -eq $moduleName } | Install-Module
        $res = Get-Module $moduleName -ListAvailable
        AssertEquals $res.Name $moduleName "Install-Module failed to install with Find-RoleCapability output"
    }

    
    
    
    
    
    
    It InstallModuleUsingFindDscResourceOutput {
        $moduleName = "DscTestModule"
        Find-DscResource -Name DscTestResource,NewDscTestResource | Where-Object {$_.ModuleName -eq $moduleName } | Install-Module
        $res = Get-Module $moduleName -ListAvailable
        AssertEquals $res.Name $moduleName "Install-Module failed to install with Find-DscResource output"
    }

    
    It ValidateGetInstalledModuleCmdlet {

        $ModuleName = 'ContosoServer'
        $ContosoClient = 'ContosoClient'
        $DateTimeBeforeInstall = Get-Date

        Install-Module -Name $ContosoClient
        $mod = Get-InstalledModule -Name $ContosoClient
        AssertEquals $mod.Name $ContosoClient "Get-InstalledModule results are not expected, $mod"
        AssertNotNull $mod.InstalledDate "Get-InstalledModule results are not expected, InstalledDate should not be null, $mod"
        Assert ($mod.InstalledDate.AddSeconds(1) -ge $DateTimeBeforeInstall) "Get-InstalledModule results are not expected, InstalledDate $($mod.InstalledDate.Ticks) should be after $($DateTimeBeforeInstall.Ticks)"
        AssertNull $mod.UpdatedDate "Get-InstalledModule results are not expected, UpdateDate should be null, $mod"

        Install-Module -Name $ModuleName -RequiredVersion 1.0 -Force
        $modules = Get-InstalledModule
        AssertNotNull $modules "Get-InstalledModule is not working properly"

        $mod = Get-InstalledModule -Name $ModuleName
        AssertEquals $mod.Name $ModuleName "Get-InstalledModule returned wrong module, $mod"
        AssertEquals $mod.Version "1.0" "Get-InstalledModule returned wrong module version, $mod"

        $modules1 = Get-InstalledModule

        Update-Module -Name $ModuleName -RequiredVersion 2.0
        $mod2 = Get-InstalledModule -Name $ModuleName -RequiredVersion "2.0"
        AssertEquals $mod2.Name $ModuleName "Get-InstalledModule returned wrong module after Update-Module, $mod2"
        AssertEquals $mod2.Version "2.0"  "Get-InstalledModule returned wrong module version  after Update-Module, $mod2"

        $modules2 = Get-InstalledModule

        
        
        AssertEquals $modules1.count $modules2.count "module count should be same before and after updating a module, before: $($modules1.count), after: $($modules2.count)"
    }

    It ValidateGetInstalledModuleAndUninstallModuleCmdletsWithMinimumVersion {

        $ModuleName = 'ContosoServer'
        $version = "2.0"

        try
        {
            Install-Module -Name $ModuleName -RequiredVersion $version -Force
            $module = Get-InstalledModule -Name $ModuleName -MinimumVersion 1.0
            AssertEquals $module.Name $ModuleName "Get-InstalledModule is not working properly, $module"
            AssertEquals $module.Version $Version "Get-InstalledModule is not working properly, $module"
        }
        finally
        {
            PowerShellGet\Uninstall-Module -Name $ModuleName -MinimumVersion $Version
            $module = Get-InstalledModule -Name $ModuleName -ErrorAction SilentlyContinue
            AssertNull $module "Module uninstallation is not working properly, $module"
        }
    }

    It ValidateGetInstalledModuleAndUninstallModuleCmdletWithMinMaxRange {

        $ModuleName = 'ContosoServer'
        $version = "2.0"

        try
        {
            Install-Module -Name $ModuleName -RequiredVersion $version -Force
            $module = Get-InstalledModule -Name $ModuleName -MinimumVersion $Version -MaximumVersion $Version
            AssertEquals $module.Name $ModuleName "Get-InstalledModule is not working properly, $module"
            AssertEquals $module.Version $Version "Get-InstalledModule is not working properly, $module"
        }
        finally
        {
            PowerShellGet\Uninstall-Module -Name $ModuleName -MinimumVersion $Version -MaximumVersion $Version
            $module = Get-InstalledModule -Name $ModuleName -ErrorAction SilentlyContinue
            AssertNull $module "Module uninstallation is not working properly, $module"
        }
    }

    It ValidateGetInstalledModuleAndUninstallModuleCmdletWithRequiredVersion {

        $ModuleName = 'ContosoServer'
        $version = "2.0"

        try
        {
            Install-Module -Name $ModuleName -RequiredVersion $version -Force
            $module = Get-InstalledModule -Name $ModuleName -RequiredVersion $Version
            AssertEquals $module.Name $ModuleName "Get-InstalledModule is not working properly, $module"
            AssertEquals $module.Version $Version "Get-InstalledModule is not working properly, $module"
        }
        finally
        {
            PowerShellGet\Uninstall-Module -Name $ModuleName -RequiredVersion $Version
            $module = Get-InstalledModule -Name $ModuleName -ErrorAction SilentlyContinue
            AssertNull $module "Module uninstallation is not working properly, $module"
        }
    }

    It ValidateGetInstalledModuleAndUninstallModuleCmdletWithMiximumVersion {

        $ModuleName = 'ContosoServer'
        $version = "2.0"

        try
        {
            Install-Module -Name $ModuleName -RequiredVersion $version -Force
            $module = Get-InstalledModule -Name $ModuleName -MaximumVersion $Version
            AssertEquals $module.Name $ModuleName "Get-InstalledModule is not working properly, $module"
            AssertEquals $module.Version $Version "Get-InstalledModule is not working properly, $module"
        }
        finally
        {
            PowerShellGet\Uninstall-Module -Name $ModuleName -RequiredVersion $Version
            $module = Get-InstalledModule -Name $ModuleName -ErrorAction SilentlyContinue
            AssertNull $module "Module uninstallation is not working properly, $module"
        }
    }

    
    
    
    
    
    
    It InstallModuleUsingFindCommandOutput {
        $moduleName1 = "ContosoServer"
        $moduleName2 = "ContosoClient"
        Find-Command -Name Get-ContosoServer,Get-ContosoClient | Where-Object {($_.ModuleName -eq $moduleName1) -or ($_.ModuleName -eq $moduleName2) } | Install-Module

        $res = Get-Module $moduleName1 -ListAvailable
        AssertEquals $res.Name $moduleName1 "Install-Module failed to install with Find-Command output"

        $res = Get-Module $moduleName2 -ListAvailable
        AssertEquals $res.Name $moduleName2 "Install-Module failed to install with Find-Command output"
    }

    
    
    
    
    
    
    It 'InstallNonMsSignedModuleOverMsSignedModule' {
        $pesterRoot = Join-Path -Path $script:TempModulesPath -ChildPath "Pester"
        $v1Path = Join-Path -Path $pesterRoot -ChildPath "99.99.99.98"
        $v2Path = Join-Path -Path $pesterRoot -ChildPath "99.99.99.99"
        
        Publish-Module -Path $v1Path -Repository $script:localGalleryName
        Publish-Module -Path $v2Path -Repository $script:localGalleryName
        $oldPSModulePath = $env:PSModulePath
        $env:PSModulePath = $script:TestPSModulePath
        try {
            
            Install-Module Pester -RequiredVersion 99.99.99.98 -Repository $script:localGalleryName -ErrorVariable iev -WarningVariable iwv -WarningAction SilentlyContinue -Force
            
            $iev | should be $null
            $iwv | should not be $null
            $iwv | should not belike "*root*authority*"

            
            
            
            
            $env:PSModulePath = $oldPSModulePath

            
            Install-Module Pester -RequiredVersion 99.99.99.99 -Repository $script:localGalleryName -ErrorVariable iev -WarningVariable iwv -Force
            
            $iev | should be $null
            $iwv | should be $null
        } finally {
            
            $env:PSModulePath = $oldPSModulePath

            
            if (Get-Module Pester -ListAvailable | Where-Object { $_.Version -eq '99.99.99.98' }) {
                $moduleBase = (Get-Module Pester -ListAvailable | Where-Object { $_.Version -eq '99.99.99.98' }).ModuleBase
                $null = Remove-Item -Path $moduleBase -Force -Recurse
                if (Get-Module Pester -ListAvailable | Where-Object { $_.Version -eq '99.99.99.98' }) {
                    Write-Error "Failed to uninstall v1"
                }
            }

            
            if (Get-Module Pester -ListAvailable | Where-Object { $_.Version -eq '99.99.99.99' }) {
                $moduleBase = (Get-Module Pester -ListAvailable | Where-Object { $_.Version -eq '99.99.99.99' }).ModuleBase
                $null = Remove-Item -Path $moduleBase -Force -Recurse
                if (Get-Module Pester -ListAvailable | Where-Object { $_.Version -eq '99.99.99.99' }) {
                    Write-Error "Failed to uninstall v2"
                }
            }
        }
    } `
    -Skip:$((-not (Get-Module PKI -ListAvailable)) -or ([Environment]::OSVersion.Version -lt '10.0'))

}

Describe PowerShell.PSGet.InstallModuleTests.P1 -Tags 'P1','OuterLoop' {

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    AfterEach {
        PSGetTestUtils\Uninstall-Module Contoso
        PSGetTestUtils\Uninstall-Module ContosoServer
        PSGetTestUtils\Uninstall-Module ContosoClient
        PSGetTestUtils\Uninstall-Module DscTestModule
    }

    
    
    
    
    
    
    It "InstallModuleWithPrefixWildCard" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Install-Module *ontosoServer} `
                                          -expectedFullyQualifiedErrorId 'NameShouldNotContainWildcardCharacters,Install-Module'
    }

    
    
    
    
    
    
    It "InstallModuleWithPostfixWildCard" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Install-Module ContosoServe*} `
                                          -expectedFullyQualifiedErrorId 'NameShouldNotContainWildcardCharacters,Install-Module'
    }

    
    
    
    
    
    
    It "InstallModuleWithRangeWildCards" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Install-Module -Name "Co[nN]t?soS[a-z]r?er"} `
                                          -expectedFullyQualifiedErrorId 'NameShouldNotContainWildcardCharacters,Install-Module'
    }

    
    
    
    
    
    
    It "InstallModuleWithWildCards" {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Install-Module *ContosoServer*} `
                                          -expectedFullyQualifiedErrorId 'NameShouldNotContainWildcardCharacters,Install-Module'
    }

    
    
    
    
    
    
    It ValidatePSGetPropertiesOnPSModuleInfoFromImportModule {
        Install-Module ContosoServer -Repository PSGallery
        $res = Import-Module ContosoServer -PassThru -Force
        $res | Remove-Module -Force
        Assert (($res.Count -eq 1) -and ($res.Name -eq "ContosoServer") -and ($res.Version -ge [Version]"2.5")) "Install-Module failed to install ContosoServer"
        AssertNotNull $res.Tags "Tags value is missing on PSModuleInfo"
        AssertNotNull $res.LicenseUri "LicenseUri value is missing on PSModuleInfo"
        AssertNotNull $res.ProjectUri "ProjectUri value is missing on PSModuleInfo"
        AssertNotNull $res.IconUri "IconUri value is missing on PSModuleInfo"
        AssertNotNull $res.ReleaseNotes "ReleaseNotes value is missing on PSModuleInfo"
        AssertNotNull $res.RepositorySourceLocation "RepositorySourceLocation value is missing on PSModuleInfo"
    } -Skip:$($PSVersionTable.PSVersion -lt '5.0.0')

    
    
    
    
    
    
    It InstallAModulFromUntrustedRepositoryAndNoToPrompt {
        try {
            
            Register-PSRepository -Name UntrustedTestRepo -SourceLocation $script:UntrustedRepoSourceLocation -PublishLocation $script:UntrustedRepoPublishLocation
            $moduleRepo = Get-PSRepository -Name UntrustedTestRepo
            AssertEqualsCaseInsensitive $moduleRepo.SourceLocation $script:UntrustedRepoSourceLocation "Test repository 'UntrustedTestRepo' is not registered properly"

            $outputPath = $script:TempPath
            $guid =  [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            if($PSVersionTable.PSVersion -ge '4.0.0')
            {
                
                $Global:proxy.UI.ChoiceToMake=2
            }
            else
            {
                
                $Global:proxy.UI.ChoiceToMake=1
            }

            $content = $null
            try
            {
                $result = ExecuteCommand $runspace "Install-Module ContosoServer -Repository UntrustedTestRepo"
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

            $itemInfo = Find-Module ContosoServer
            $acceptPromptMessage = "Are you sure you want to install the modules from"
            Assert ($content -and $content.Contains($acceptPromptMessage)) "Prompt for installing a module from an untrusted repository is not working, $content"
            $res = Get-Module ContosoServer -ListAvailable
            Assert (-not $res) "Install-Module should not install a module if prompt is not accepted"
        }
        finally {
            Get-PSRepository -Name UntrustedTestRepo -ErrorAction SilentlyContinue | Unregister-PSRepository -ErrorAction SilentlyContinue
        }
    } -Skip:$(($PSCulture -ne 'en-US') -or ($PSVersionTable.PSVersion -lt '4.0.0') -or ($PSEdition -eq 'Core'))

    
    
    
    
    
    
    It InstallAModulFromUntrustedRepositoryAndYesToPrompt {
        try {
            
            Register-PSRepository -Name UntrustedTestRepo -SourceLocation $script:UntrustedRepoSourceLocation -PublishLocation $script:UntrustedRepoPublishLocation
            $moduleRepo = Get-PSRepository -Name UntrustedTestRepo
            AssertEqualsCaseInsensitive $moduleRepo.SourceLocation $script:UntrustedRepoSourceLocation "Test repository 'UntrustedTestRepo' is not registered properly"

            $outputPath = $script:TempPath
            $guid =  [system.guid]::newguid().tostring()
            $outputFilePath = Join-Path $outputPath "$guid"
            $runspace = CreateRunSpace $outputFilePath 1

            
            $Global:proxy.UI.ChoiceToMake=0
            $content = $null
            try
            {
                $result = ExecuteCommand $runspace "Install-Module ContosoServer -Repository UntrustedTestRepo"
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

            $acceptPromptMessage = "Are you sure you want to install the modules from"
            Assert ($content -and $content.Contains($acceptPromptMessage)) "Prompt for installing a module from an untrusted repository is not working, $content"

            $res = Get-Module ContosoServer -ListAvailable
            Assert (($res.Count -eq 1) -and ($res.Name -eq "ContosoServer")) "Install-Module should install a module if prompt is accepted, $res"
        }
        finally {
            Get-PSRepository -Name UntrustedTestRepo -ErrorAction SilentlyContinue | Unregister-PSRepository -ErrorAction SilentlyContinue
        }
    } -Skip:$(($PSCulture -ne 'en-US') -or ($PSVersionTable.PSVersion -lt '4.0.0') -or ($PSEdition -eq 'Core'))

    
    It ValidateGetInstalledModuleWithMultiNamesAndRequiredVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Get-InstalledModule -Name ContosoClient,ContosoServer -RequiredVersion 3.0 } `
                                    -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Get-InstalledModule"
    }

    It ValidateGetInstalledModuleWithMultiNamesAndMinVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Get-InstalledModule -Name ContosoClient,ContosoServer -MinimumVersion 3.0 } `
                                    -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Get-InstalledModule"
    }

    It ValidateGetInstalledModuleWithMultiNamesAndMaxVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Get-InstalledModule -Name ContosoClient,ContosoServer -MaximumVersion 3.0 } `
                                    -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Get-InstalledModule"
    }

    It ValidateGetInstalledModuleWithSingleWildcardNameAndRequiredVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Get-InstalledModule -Name Contoso*Client -RequiredVersion 3.0 } `
                                    -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Get-InstalledModule"
    }

    It ValidateGetInstalledModuleWithSingleWildcardNameAndMinVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Get-InstalledModule -Name Contoso*Client -MinimumVersion 3.0 } `
                                    -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Get-InstalledModule"
    }

    It ValidateGetInstalledModuleWithSingleWildcardNameAndMaxVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Get-InstalledModule -Name Contoso*Client -MaximumVersion 3.0 } `
                                    -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Get-InstalledModule"
    }

    It ValidateGetInstalledModuleWithSingleNameRequiredandMinVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Get-InstalledModule -Name ContosoClient -RequiredVersion 3.0 -MinimumVersion 1.0 } `
                                    -expectedFullyQualifiedErrorId "VersionRangeAndRequiredVersionCannotBeSpecifiedTogether,Get-InstalledModule"
    }

    It ValidateGetInstalledModuleWithSingleNameRequiredandMaxVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Get-InstalledModule -Name ContosoClient -RequiredVersion 3.0 -MaximumVersion 1.0 } `
                                    -expectedFullyQualifiedErrorId "VersionRangeAndRequiredVersionCannotBeSpecifiedTogether,Get-InstalledModule"
    }

    It ValidateGetInstalledModuleWithSingleNameInvalidMinMaxRange {
        AssertFullyQualifiedErrorIdEquals -scriptblock {Get-InstalledModule -Name ContosoClient -MinimumVersion 3.0 -MaximumVersion 1.0 } `
                                    -expectedFullyQualifiedErrorId "MinimumVersionIsGreaterThanMaximumVersion,Get-InstalledModule"
    }

    
    It ValidateUninstallModuleWithMultiNamesAndRequiredVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {PowerShellGet\Uninstall-Module -Name ContosoClient,ContosoServer -RequiredVersion 3.0 } `
                                    -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Uninstall-Module"
    }

    It ValidateUninstallModuleWithMultiNamesAndMinVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {PowerShellGet\Uninstall-Module -Name ContosoClient,ContosoServer -MinimumVersion 3.0 } `
                                    -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Uninstall-Module"
    }

    It ValidateUninstallModuleWithMultiNamesAndMaxVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {PowerShellGet\Uninstall-Module -Name ContosoClient,ContosoServer -MaximumVersion 3.0 } `
                                    -expectedFullyQualifiedErrorId "VersionParametersAreAllowedOnlyWithSingleName,Uninstall-Module"
    }

    It ValidateUninstallModuleWithSingleWildcard {
        AssertFullyQualifiedErrorIdEquals -scriptblock {PowerShellGet\Uninstall-Module -Name Contoso*Client} `
                                    -expectedFullyQualifiedErrorId "NameShouldNotContainWildcardCharacters,Uninstall-Module"
    }

    It ValidateUninstallModuleWithSingleNameRequiredandMinVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {PowerShellGet\Uninstall-Module -Name ContosoClient -RequiredVersion 3.0 -MinimumVersion 1.0 } `
                                    -expectedFullyQualifiedErrorId "VersionRangeAndRequiredVersionCannotBeSpecifiedTogether,Uninstall-Module"
    }

    It ValidateUninstallModuleWithSingleNameRequiredandMaxVersion {
        AssertFullyQualifiedErrorIdEquals -scriptblock {PowerShellGet\Uninstall-Module -Name ContosoClient -RequiredVersion 3.0 -MaximumVersion 1.0 } `
                                    -expectedFullyQualifiedErrorId "VersionRangeAndRequiredVersionCannotBeSpecifiedTogether,Uninstall-Module"
    }

    It ValidateUninstallModuleWithSingleNameInvalidMinMaxRange {
        AssertFullyQualifiedErrorIdEquals -scriptblock {PowerShellGet\Uninstall-Module -Name ContosoClient -MinimumVersion 3.0 -MaximumVersion 1.0 } `
                                    -expectedFullyQualifiedErrorId "MinimumVersionIsGreaterThanMaximumVersion,Uninstall-Module"
    }

    
    
    
    
    
    
    It SaveModuleWithFindRoleCapabilityOutput {
        $RoleCapabilityName = 'Lev1Maintenance'
        $ModuleName = 'DscTestModule'
        $res1 = Find-RoleCapability -Name $RoleCapabilityName

        try
        {
            AssertEquals $res1.Name $RoleCapabilityName "Find-RoleCapability didn't find a role capability, $res1"
            AssertEquals $res1.ModuleName $ModuleName "Find-RoleCapability didn't find a role capability, $res1"

            Find-RoleCapability -Name $RoleCapabilityName | Save-Module -LiteralPath $script:MyDocumentsModulesPath
            $ActualModuleDetails = Get-InstalledModule -Name $ModuleName -RequiredVersion $res1.Version
            AssertNotNull $ActualModuleDetails "$ModuleName module with dependencies is not saved properly"
        }
        finally
        {
            $res1.ModuleName  | ForEach-Object {PSGetTestUtils\Uninstall-Module $_}
        }
    }

    
    
    
    
    
    
    It SaveModuleWithFindDscResourceOutput {
        $DscResourceName = 'DscTestResource'
        $ModuleName = 'DscTestModule'
        $res1 = Find-DscResource -Name $DscResourceName

        try
        {
            AssertEquals $res1.Name $DscResourceName "Find-DscResource didn't find a DscResource, $res1"
            AssertEquals $res1.ModuleName $ModuleName "Find-DscResource didn't find a DscResource, $res1"

            Find-DscResource -Name $DscResourceName | Save-Module -LiteralPath $script:MyDocumentsModulesPath
            $ActualModuleDetails = Get-InstalledModule -Name $ModuleName -RequiredVersion $res1.Version
            AssertNotNull $ActualModuleDetails "$ModuleName module with dependencies is not saved properly"
        }
        finally
        {
            $res1.ModuleName  | ForEach-Object {PSGetTestUtils\Uninstall-Module $_}
        }
    }

    
    
    
    
    
    
    It GetInstalledModuleWithWildcard {
        $ModuleNames = 'Contoso','ContosoServer','ContosoClient'

        Install-Module -Name $ModuleNames

        
        $res1 = Get-InstalledModule -Name $ModuleNames[0]
        AssertEquals $res1.Name $ModuleNames[0] "Get-InstalledModule didn't return the exact module, $res1"

        
        $res2 = Get-InstalledModule -Name "Contoso*"
        AssertEquals $res2.count $ModuleNames.Count "Get-InstalledModule didn't return the $ModuleNames modules, $res2"
    }

    
    
    
    
    
    It InstallModuleWithSameLocationRegisteredWithNuGetProvider {
        $ModuleName = 'ContosoServer'
        $TempNuGetSourceName = "$(Get-Random)"
        $RepositoryName = "PSGallery"
        Register-PackageSource -Provider nuget -Name $TempNuGetSourceName -Location $Global:PSGallerySourceUri -Trusted
        try
        {
            Install-Module -Name $ModuleName -Repository $RepositoryName

            $res1 = Get-InstalledModule -Name $ModuleName
            AssertEquals $res1.Name $ModuleName "Get-InstalledModule didn't return the exact module, $res1"

            AssertEquals $res1.RepositorySourceLocation $Global:PSGallerySourceUri "PSGetItemInfo object was created with wrong RepositorySourceLocation"
            AssertEquals $res1.Repository $RepositoryName "PSGetItemInfo object was created with wrong repository name"

            $expectedInstalledLocation = Join-Path $script:ProgramFilesModulesPath -ChildPath $res1.Name
            if($script:IsCoreCLR)
            {
                $expectedInstalledLocation = Join-Path -Path $script:MyDocumentsModulesPath -ChildPath $res1.Name
            }
            if($PSVersionTable.PSVersion -ge '5.0.0')
            {
                $expectedInstalledLocation = Join-Path -Path $expectedInstalledLocation -ChildPath $res1.Version
            }

            AssertEquals $res1.InstalledLocation $expectedInstalledLocation "Invalid InstalledLocation value on PSGetItemInfo object"
        }
        finally
        {
            Unregister-PackageSource -ProviderName NuGet -Name $TempNuGetSourceName -Force
        }
    }

    
    
    
    
    
    
    It SaveModuleWithFindCommandOutput {
        $CommandName = 'Get-ContosoServer'
        $ModuleName = 'ContosoServer'
        $res1 = Find-Command -Name $CommandName -ModuleName $ModuleName

        try
        {
            AssertEquals $res1.Name $CommandName "Find-Command didn't find a Command, $res1"
            AssertEquals $res1.ModuleName $ModuleName "Find-Command didn't find a Command, $res1"

            Find-Command -Name $CommandName -ModuleName $ModuleName | Save-Module -LiteralPath $script:MyDocumentsModulesPath
            $ActualModuleDetails = Get-InstalledModule -Name $ModuleName -RequiredVersion $res1.Version
            AssertNotNull $ActualModuleDetails "$ModuleName module is not saved properly"
        }
        finally
        {
            $res1.ModuleName  | ForEach-Object {PSGetTestUtils\Uninstall-Module $_}
        }
    }
}

Describe PowerShell.PSGet.InstallModuleTests.P2 -Tags 'P2','OuterLoop' {
    
    
    if($IsMacOS) {
        return
    }

    BeforeAll {
        SuiteSetup
    }

    AfterAll {
        SuiteCleanup
    }

    AfterEach {
        PSGetTestUtils\Uninstall-Module Contoso
        PSGetTestUtils\Uninstall-Module ContosoServer
        PSGetTestUtils\Uninstall-Module ContosoClient
        PSGetTestUtils\Uninstall-Module DscTestModule
    }

    
    
    
    
    
    
    It InstallModuleWithIncludeDependencies {
        $ModuleName = "ModuleWithDependencies1"
        $DepencyModuleNames = @()

        try
        {
            $res1 = Find-Module -Name $ModuleName -MaximumVersion "1.0" -MinimumVersion "0.1"
            AssertEquals $res1.Name $ModuleName "Find-Module didn't find the exact module which has dependencies, $res1"

            $DepencyModuleNames = $res1.Dependencies.Name

            $res2 = Find-Module -Name $ModuleName -IncludeDependencies -MaximumVersion "1.0" -MinimumVersion "0.1"
            Assert ($res2.Count -ge ($DepencyModuleNames.Count+1)) "Find-Module with -IncludeDependencies returned wrong results, $res2"

            Install-Module -Name $ModuleName -MaximumVersion "1.0" -MinimumVersion "0.1" -AllowClobber
            $ActualModuleDetails = Get-InstalledModule -Name $ModuleName -RequiredVersion $res1.Version
            AssertNotNull $ActualModuleDetails "$ModuleName module with dependencies is not installed properly"

            $DepModuleDetails = Get-Module -Name $DepencyModuleNames -ListAvailable
            AssertNotNull $DepModuleDetails "$DepencyModuleNames dependencies is not installed properly"
            Assert ($DepModuleDetails.Count -ge $DepencyModuleNames.Count)  "$DepencyModuleNames dependencies is not installed properly"

            if($PSVersionTable.PSVersion -ge '5.0.0')
            {
                $res2 | ForEach-Object {
                    $mod = Get-InstalledModule -Name $_.Name -MinimumVersion $_.Version
                    AssertNotNull $mod "$($_.Name) module is not installed properly"
                }

                $depModuleDetails = $res1.Dependencies | Where-Object {$_.Name -eq 'NestedRequiredModule2'}
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                                           -MinimumVersion $depModuleDetails.MinimumVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with MinimumVersion is not installed properly"

                $depModuleDetails = $res1.Dependencies | Where-Object {$_.Name -eq 'RequiredModule2'}
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                                           -MinimumVersion $depModuleDetails.MinimumVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with MinimumVersion is not installed properly"

                $depModuleDetails = $res1.Dependencies | Where-Object {$_.Name -eq 'NestedRequiredModule3'}
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                                           -RequiredVersion $depModuleDetails.RequiredVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with exact version is not installed properly"

                $depModuleDetails = $res1.Dependencies | Where-Object {$_.Name -eq 'RequiredModule3'}
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                                           -RequiredVersion $depModuleDetails.RequiredVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with exact version is not installed properly"

                $depModuleDetails = $res1.Dependencies | Where-Object {$_.Name -eq 'NestedRequiredModule4'}
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                                           -MinimumVersion $depModuleDetails.MinimumVersion `
                                           -MaximumVersion $depModuleDetails.MaximumVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with version range is not installed properly"

                $depModuleDetails = $res1.Dependencies | Where-Object {$_.Name -eq 'RequiredModule4'}
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                                           -MinimumVersion $depModuleDetails.MinimumVersion `
                                           -MaximumVersion $depModuleDetails.MaximumVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with version range is not installed properly"

                $depModuleDetails = $res1.Dependencies | Where-Object {$_.Name -eq 'NestedRequiredModule5'}
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                                           -MaximumVersion $depModuleDetails.MaximumVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with maximum version is not installed properly"

                $depModuleDetails = $res1.Dependencies | Where-Object {$_.Name -eq 'RequiredModule5'}
                $mod = Get-InstalledModule -Name $depModuleDetails.Name `
                                           -MaximumVersion $depModuleDetails.MaximumVersion
                AssertNotNull $mod "$($depModuleDetails.Name) module with maximum version is not installed properly"

            }
        }
        finally
        {
            Get-InstalledModule -Name $ModuleName -AllVersions | PowerShellGet\Uninstall-Module -Force
            $DepencyModuleNames | ForEach-Object { Get-InstalledModule -Name $_ -AllVersions | PowerShellGet\Uninstall-Module -Force }
        }
    }

    
    
    
    
    
    
    It SaveModuleNameWithDependencies {
        $ModuleName = "ModuleWithDependencies1"

        $res1 = Find-Module -Name $ModuleName -RequiredVersion "1.0"
        $DepencyModuleNames = @()

        try
        {
            AssertEquals $res1.Name $ModuleName "Find-Module didn't find the exact module which has dependencies, $res1"
            $DepencyModuleNames = $res1.Dependencies.Name

            Save-Module -Name $ModuleName -MaximumVersion "1.0" -MinimumVersion "0.1" $script:MyDocumentsModulesPath
            $ActualModuleDetails = Get-InstalledModule -Name $ModuleName -RequiredVersion $res1.Version
            AssertNotNull $ActualModuleDetails "$ModuleName module with dependencies is not saved properly"

            $DepModuleDetails = Get-Module -Name $DepencyModuleNames -ListAvailable
            AssertNotNull $DepModuleDetails "$DepencyModuleNames dependencies is not saved properly"
            Assert ($DepModuleDetails.Count -ge $DepencyModuleNames.Count)  "$DepencyModuleNames dependencies is not saved properly"
        }
        finally
        {
            Get-InstalledModule -Name $res1.Name -AllVersions | PowerShellGet\Uninstall-Module -Force
            $DepencyModuleNames | ForEach-Object { Get-InstalledModule -Name $_ -AllVersions | PowerShellGet\Uninstall-Module -Force }
        }
    }

    
    
    
    
    
    
    It SaveModuleWithFindModuleOutput {
        $ModuleName = "ModuleWithDependencies1"

        $res1 = Find-Module -Name $ModuleName -RequiredVersion "2.0"
        $DepencyModuleNames = @()

        try
        {
            AssertEquals $res1.Name $ModuleName "Find-Module didn't find the exact module which has dependencies, $res1"
            $DepencyModuleNames = $res1.Dependencies.Name

            Find-Module -Name $ModuleName -RequiredVersion "2.0" | Save-Module -LiteralPath $script:MyDocumentsModulesPath
            $ActualModuleDetails = Get-InstalledModule -Name $ModuleName -RequiredVersion $res1.Version
            AssertNotNull $ActualModuleDetails "$ModuleName module with dependencies is not saved properly"

            $DepModuleDetails = Get-Module -Name $DepencyModuleNames -ListAvailable
            AssertNotNull $DepModuleDetails "$DepencyModuleNames dependencies is not saved properly"
            Assert ($DepModuleDetails.Count -ge $DepencyModuleNames.Count)  "$DepencyModuleNames dependencies is not saved properly"
        }
        finally
        {
            Get-InstalledModule -Name $res1.Name -AllVersions | PowerShellGet\Uninstall-Module -Force
            $DepencyModuleNames | ForEach-Object { Get-InstalledModule -Name $_ -AllVersions | PowerShellGet\Uninstall-Module -Force }
        }
    }
}