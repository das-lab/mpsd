



[CmdletBinding()]
param
(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Manifest,

    [string] $Name = 'EventResource',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $Namespace = 'System.Management.Automation.Tracing',

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $ResxPath,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $CodePath

)

Import-Module $PSScriptRoot\ResxGen.psm1 -Force
try
{
    ConvertTo-Resx -Manifest $Manifest -Name $Name -ResxPath $ResxPath -CodePath $CodePath -Namespace $Namespace
}
finally
{
    Remove-Module ResxGen -Force -ErrorAction Ignore
}

