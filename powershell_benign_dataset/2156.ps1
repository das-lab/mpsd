



[CmdletBinding()]
param
(
    [ValidateNotNullOrEmpty()]
    [string] $Path = $PSScriptRoot
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-Elevated
{
    [CmdletBinding()]
    [OutputType([bool])]
    Param()

    
    
    
    return (([Security.Principal.WindowsIdentity]::GetCurrent()).Groups -contains "S-1-5-32-544")
}
$IsWindowsOs = $PSHOME.EndsWith('\WindowsPowerShell\v1.0', [System.StringComparison]::OrdinalIgnoreCase) -or $IsWindows

if (-not $IsWindowsOs)
{
    throw 'This script must be run on Windows.'
}

if (-not (Test-Elevated))
{
    throw 'This script must be run from an elevated process.'
}

if ([System.Management.Automation.Platform]::IsNanoServer)
{
    throw 'Group policy definitions are not supported on Nano Server.'
}

$admxName = 'PowerShellCoreExecutionPolicy.admx'
$admlName = 'PowerShellCoreExecutionPolicy.adml'
$admx = Get-Item -Path (Join-Path -Path $Path -ChildPath $admxName)
$adml = Get-Item -Path (Join-Path -Path $Path -ChildPath $admlName)
$admxTargetPath = Join-Path -Path $env:WINDIR -ChildPath "PolicyDefinitions"
$admlTargetPath = Join-Path -Path $admxTargetPath -ChildPath "en-US"

$files = @($admx, $adml)
foreach ($file in $files)
{
    if (-not (Test-Path -Path $file))
    {
        throw "Could not find $($file.Name) at $Path"
    }
}

Write-Verbose "Copying $admx to $admxTargetPath"
Copy-Item -Path $admx -Destination $admxTargetPath -Force
$admxTargetFullPath = Join-Path -Path $admxTargetPath -ChildPath $admxName
if (Test-Path -Path $admxTargetFullPath)
{
    Write-Verbose "$admxName was installed successfully"
}
else
{
    Write-Error "Could not install $admxName"
}

Write-Verbose "Copying $adml to $admlTargetPath"
Copy-Item -Path $adml -Destination $admlTargetPath -Force
$admlTargetFullPath = Join-Path -Path $admlTargetPath -ChildPath $admlName
if (Test-Path -Path $admlTargetFullPath)
{
    Write-Verbose "$admlName was installed successfully"
}
else
{
    Write-Error "Could not install $admlName"
}
