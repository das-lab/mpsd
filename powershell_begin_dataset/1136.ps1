











[CmdletBinding()]
param(
    [Switch]
    $ForDsc
)


Set-StrictMode -Version 'Latest'

if( $env:COMPUTERNAME -eq $env:USERNAME )
{
    throw ('Can''t run Carbon tests. The current user''s username ({0}) is the same as the computer name ({1}). This causes problems with resolving identities, getting items from the registry, etc. Please re-run these tests using a different account.')
}

$importCarbonPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\Import-Carbon.ps1' -Resolve

if( (Test-Path -Path 'env:APPVEYOR') )
{
    
    if( -not (Get-Module -Name 'Carbon') )
    {
        & $importCarbonPath -Force
    }
}
else 
{
    
    if( -not (Test-Path -Path 'variable:CarbonLastImportedAt') )
    {
        $Global:CarbonLastImportedAt = [DateTime]::MinValue
    }

    $startedAt = Get-Date
    $mostRecentModificationAt = 
        Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon') -File -Recurse |
        Sort-Object -Property 'LastWriteTime' -Descending |
        Select-Object -First 1 |
        Select-Object -ExpandProperty 'LastWriteTime'
    $checkDuration = (Get-Date) - $startedAt
    Write-Debug -Message ('It took "{0}" seconds to check if any of Carbon''s files changed.' -f $checkDuration.TotalSeconds)

    $moduleImported = $null -ne (Get-Module -Name 'Carbon')
    $moduleUpdated = $mostRecentModificationAt -gt $CarbonLastImportedAt
    if( -not $moduleImported -or $moduleUpdated )
    {
        Write-Verbose -Message ('Importing Carbon.') -Verbose
        Write-Verbose -Message ('Module Already Imported?            {0}' -f $moduleImported) -Verbose
        Write-Verbose -Message ('Module Modified Since Last Import?  {0}' -f $moduleUpdated) -Verbose
        Write-Verbose -Message ('              CarbonLastImportedAt  {0}' -f $CarbonLastImportedAt) -Verbose
        Write-Verbose -Message ('                LastModificationAt  {0}' -f $mostRecentModificationAt) -Verbose
        & $importCarbonPath -Force
        $Global:CarbonLastImportedAt = Get-Date
    }
}

if( $ForDsc )
{
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest' -Resolve) -Force
}
else
{
    if( (Get-Module -Name 'CarbonDscTest') )
    {
        Remove-Module -Name 'CarbonDscTest' -Force
    }
}

$password = 'Tt6QML1lmDrFSf'
[pscredential]$global:CarbonTestUser = New-Credential 'CarbonTestUser' -Password $password

if( -not (Test-CUser -Username $CarbonTestUser.UserName) )
{
    Install-CUser -Credential $CarbonTestUser -Description 'User used during Carbon tests.'

    $usedCredential = $false
    while( $usedCredential -ne $CarbonTestUser.UserName )
    {
        try
        {
            Write-Verbose -Message ('Attempting to launch process as "CarbonTestUser".') -Verbose
            $usedCredential = 
                Start-Job -ScriptBlock { [Environment]::UserName } -Credential $CarbonTestUser  | 
                Wait-Job |
                Receive-Job
        }
        catch 
        {
            Start-Sleep -Milliseconds 100
        }
    }
}