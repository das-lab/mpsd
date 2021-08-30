











[CmdletBinding()]
param(
)


Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon\Import-Carbon.ps1' -Resolve)

$installRoot = Get-PowerShellModuleInstallPath
$carbonModuleRoot = Join-Path -Path $installRoot -ChildPath 'Carbon'
Install-Junction -Link $carbonModuleRoot -Target (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon' -Resolve) 

if( (Test-Path -Path 'env:APPVEYOR') )
{
    Grant-Permission -Path ($PSScriptRoot | Split-Path) -Identity 'Everyone' -Permission 'FullControl'
    Grant-Permission -Path ('C:\Users\appveyor\Documents') -Identity 'Everyone' -Permission 'FullControl'

    $wmiprvse = Get-Process -Name 'wmiprvse'
    
    $wmiprvse | Stop-Process -Force
    
}

configuration Yolo
{
    node 'localhost'
    {
        Script AvailableModules
        {
            GetScript = {
                return @{ PID = $PID }

            }

            SetScript = {
            
            }

            TestScript =  {
                $PID | Write-Verbose
                Get-Module -ListAvailable | Format-Table | Out-String | Write-Verbose
                Get-DscResource | Format-Table | Out-String | Write-Verbose
                return $true
            }

        }
    }
}














Clear-DscLocalResourceCache
