











[CmdletBinding()]
param(
    [string[]]
    $Path,

    [Parameter()]
    [string[]]
    $Test,

    [Switch]
    $Recurse,

    [Switch]
    $PassThru
)


Set-StrictMode -Version 'Latest'


$prependFormats = @(
                        (Join-Path -Path $PSScriptRoot -ChildPath 'System.Management.Automation.ErrorRecord.format.ps1xml'),
                        (Join-Path -Path $PSScriptRoot -ChildPath 'System.Exception.format.ps1xml')
                    )
Update-FormatData -PrependPath $prependFormats

$bladeTestParam = @{ }
if( $Test )
{
    $bladeTestParam['Test'] = $Test
}

$uploadTestResults = $false 
$uploadUri = ''
$isAppVeyor = Test-Path -Path 'env:APPVEYOR'
if( $isAppVeyor )
{
    $uploadTestResults = $true
    $uploadUri = 'https://ci.appveyor.com/api/testresults/nunit/{0}' -f $env:APPVEYOR_JOB_ID 
}

$testsFailed = $false

$xmlLogPath = Join-Path -Path $PSScriptRoot -ChildPath '.output\Carbon.blade.xml'
$bladePath = Join-Path -Path $PSScriptRoot -ChildPath '.\Tools\Blade\blade.ps1' -Resolve
& $bladePath -Path $Path -XmlLogPath $xmlLogPath @bladeTestParam -Recurse:$Recurse -PassThru:$PassThru |
    Format-Table -Property Duration,FixtureName,Name
if( $PassThru )
{
    $LastBladeResult
}

if( $isAppVeyor )
{
    & { 
            $LastBladeResult.Failures
            $LastBladeResult.Errors
    } | Format-List
}

if( $LastBladeResult.Errors -or $LastBladeResult.Failures )
{
    $testsFailed = $true
}

if( $uploadTestResults )
{
    $webClient = New-Object 'Net.WebClient'
    $webClient.UploadFile($uploadUri, $xmlLogPath)
}

if( $testsFailed )
{
    throw 'Blade tests failed.'
}
