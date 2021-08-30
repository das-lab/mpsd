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
