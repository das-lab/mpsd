











$tempDir = $null

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    $tempDir = New-TempDirectory -Prefix $PSCommandPath
}

function Stop-Test
{
    Remove-Item $tempDir.FullName -Recurse
}

configuration IAmBroken
{
    Set-StrictMode -Off

    node 'localhost' 
    {
        Script Fails
        {
             GetScript = { Write-Error 'GetScript' }
             SetScript = { Write-Error 'SetScript' }
             TestScript = { Write-Error 'TestScript' ; return $false }
        }
    }
}

function Test-ShouldGetDscError
{
    $startTime = Get-Date

    & IAmBroken -OutputPath $tempDir.FullName

    Start-Sleep -Milliseconds 100

    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $tempDir.FullName -ErrorAction SilentlyContinue -Force

    $dscError = Get-DscError -StartTime $startTime -Wait
    Assert-NotNull $dscError

    $Error.Clear()

    Write-DscError -EventLogRecord $dscError -ErrorAction SilentlyContinue
    Assert-DscError $dscError

    $Error.Clear()
    
    Get-DscError | Write-DscError -PassThru -ErrorAction SilentlyContinue | ForEach-Object { Assert-DscError $_ }

    
    $Error.Clear()
    Write-DscError @( $dscError, $dscError ) -ErrorAction SilentlyContinue
    Assert-DscError $dscError -Index 0
    Assert-DscError $dscError -Index 1
}

function Assert-DscError
{
    param(
        $DscError,

        $Index = 0
    )

    Set-StrictMode -Version 'Latest'

    Assert-Error
    $msg = $Error[$Index].Exception.Message
    Assert-Like $msg ('`[{0}`]*' -f $DscError.TimeCreated)
    Assert-Like $msg ('* `[{0}`] *' -f $DscError.MachineName)
    for( $idx = 0; $idx -lt $DscError.Properties.Count - 1; ++$idx )
    {
        Assert-Like $msg ('* `[{0}`] *' -f $DscError.Properties[$idx].Value)
    }
    Assert-Like $msg ('* {0}' -f $DscError.Properties[-1].Value)
}
