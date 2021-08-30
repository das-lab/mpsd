











$appSettingName = "TEST_APP_SETTING_NAME"
$appSettingValue = "TEST_APP_SETTING_VALUE"
$appSettingNewValue = "TEST_APP_SETTING_VALUE"

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Remove-AppSetting
}

function Stop-Test
{
    Remove-AppSetting
}

function Remove-AppSetting
{
    $command = @"
Add-Type -AssemblyName System.Configuration
        
`$config = [Configuration.ConfigurationManager]::OpenMachineConfiguration()
`$appSettings = `$config.AppSettings.Settings
if( `$appSettings['$appSettingName'] )
{
    `$appSettings.Remove( '$appSettingName' )
    `$config.Save()
}
"@
    
    if( (Test-DotNet -V2) )
    {
        Invoke-PowerShell -Command $command -x86 -Runtime 'v2.0'
        Invoke-PowerShell -Command $command -Runtime 'v2.0'
    }

    if( (Test-DotNet -V4 -Full) )
    {
        Invoke-PowerShell -Command $command -x86 -Runtime 'v4.0'
        Invoke-PowerShell -Command $command -Runtime 'v4.0'
    }
}

function Test-ShouldUpdateMachineConfigDotNet2x64
{
    if( -not (Test-DotNet -V2) )
    {
        Fail ('.NET v2 is not installed')
    }

    Set-DotNetAppSetting -Name $appSettingName -Value $appSettingValue -Framework64 -Clr2
    Assert-AppSetting -Name $appSettingName -Value $appSettingValue -Framework64 -Clr2
    Assert-AppSetting -Name $appSettingName -Value $null -Framework -Clr2
}


function Test-ShouldUpdateMachineConfigDotNet2x86
{
    if( -not (Test-DotNet -V2) )
    {
        Fail ('.NET v2 is not installed')
    }

    Set-DotNetAppSetting -Name $appSettingName -Value $appSettingValue -Framework -Clr2
    Assert-AppSetting -Name $appSettingName -Value $appSettingValue -Framework -Clr2
    Assert-AppSetting -Name $appSettingName -Value $null -Framework64 -Clr2
}

function Test-ShouldUpdateMachineConfigDotNet4x64
{
    if( -not (Test-DotNet -V4 -Full) )
    {
        Fail ('.NET v4 full is not installed')
    }

    Set-DotNetAppSetting -Name $appSettingName -Value $appSettingValue -Framework64 -Clr4
    Assert-AppSetting -Name $appSettingName -Value $appSettingValue -Framework64 -Clr4
    Assert-AppSetting -Name $appSettingName -Value $null -Framework -Clr4
}

function Test-ShouldUpdateMachineConfigDotNet4x86
{
    if( -not (Test-DotNet -V4 -Full) )
    {
        Fail ('.NET v4 full is not installed')
    }

    Set-DotNetAppSetting -Name $appSettingName -Value $appSettingValue -Framework -Clr4
    Assert-AppSetting -Name $appSettingName -Value $appSettingValue -Framework -Clr4
    Assert-AppSetting -Name $appSettingName -Value $null -Framework64 -Clr4
}

function Test-ShouldUpdateAppSetting
{
    if( -not (Test-DotNet -V2) )
    {
        Fail ('.NET v2 is not installed')
    }

    Set-DotNetAppSetting -Name $appSettingName -Value $appSettingValue -Framework -Framework64 -Clr2
    Set-DotNetAppSetting -Name $appSettingName -Value $appSettingNewValue -Framework -Framework64 -Clr2
    Assert-AppSetting -Name $appSettingName -Value $appSettingNewValue -Framework  -Framework64 -Clr2
}

function Test-ShouldRequireAFrameworkFlag
{
    $error.Clear()
    Set-DotNetAppSetting -Name $appSettingName -Value $appSettingValue -Clr2 -ErrorACtion SilentlyContinue
    Assert-Equal 1 $error.Count
    Assert-Like $error[0].Exception 'You must supply either or both of the Framework and Framework64 switches.'
}

function Test-ShouldRequireAClrSwitch
{
    $error.Clear()
    Set-DotNetAppSetting -Name $appSettingName -Value $appSettingValue -Framework -ErrorAction SilentlyContinue
    Assert-Equal 1 $error.Count
    Assert-Like $error[0].Exception 'You must supply either or both of the Clr2 and Clr4 switches.'
}

function Test-ShouldAddAppSettingWithSensitiveCharacters
{
    $name = $value = '`1234567890-=qwertyuiop[]\a sdfghjkl;''zxcvbnm,./~!@
    Set-DotNetAppSetting -Name $name -Value $value -Framework64 -Clr4
    Assert-AppSetting -Name $name -Value $value -Framework64 -Clr4
}

function Assert-AppSetting($Name, $value, [Switch]$Framework, [Switch]$Framework64, [Switch]$Clr2, [Switch]$Clr4)
{
    $Name = $Name -replace "'","''"
    $command = @"
        
        Add-Type -AssemblyName System.Configuration
        
        `$config = [Configuration.ConfigurationManager]::OpenMachineConfiguration()
        
        `$appSettings = `$config.AppSettings.Settings
        
        if( `$appSettings['$Name'] )
        {
            `$appSettings['$Name'].Value
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
    
    $runtimes | ForEach-Object {
        $params = @{
            Command = $command
            Encode = $true
            Runtime = $_
        }
        
        if( $Framework64 )
        {
            $actualValue = Invoke-PowerShell @params
            Assert-Equal $Value $actualValue ".NET $_ x64"
        }
        
        if( $Framework )
        {
            $actualValue = Invoke-PowerShell @params -x86
            Assert-Equal $Value $actualValue ".NET $_ x86"
        }
    }
}

