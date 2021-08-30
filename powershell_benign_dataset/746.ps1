


param(
    
    [Parameter(Position=0, Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $ScriptPath,

    
    [Parameter()]
    [string]
    $TestName,

    
    
    [Parameter()]
    [ValidatePattern('\d*')]
    [string]
    $LineNumber,

    
    [Parameter()]
    [switch]
    $All
)

$pesterModule = Microsoft.PowerShell.Core\Get-Module Pester
if (!$pesterModule) {
    Write-Output "Importing Pester module..."
    $pesterModule = Microsoft.PowerShell.Core\Import-Module Pester -ErrorAction Ignore -PassThru
    if (!$pesterModule) {
        
        Write-Warning "Failed to import the Pester module. You must install Pester to run or debug Pester tests."
        Write-Warning "You can install Pester by executing: Install-Module Pester -Scope CurrentUser -Force"
        return
    }
}

if ($All) {
    Pester\Invoke-Pester -Script $ScriptPath -PesterOption @{IncludeVSCodeMarker=$true}
}
elseif ($TestName) {
    Pester\Invoke-Pester -Script $ScriptPath -PesterOption @{IncludeVSCodeMarker=$true} -TestName $TestName
}
elseif (($LineNumber -match '\d+') -and ($pesterModule.Version -ge '4.6.0')) {
    Pester\Invoke-Pester -Script $ScriptPath -PesterOption (New-PesterOption -ScriptBlockFilter @{
        IncludeVSCodeMarker=$true; Line=$LineNumber; Path=$ScriptPath})
}
else {
    
    
    Write-Warning "The Describe block's TestName cannot be evaluated. EXECUTING ALL TESTS instead."
    Write-Warning "To avoid this, install Pester >= 4.6.0 or remove any expressions in the TestName."

    Pester\Invoke-Pester -Script $ScriptPath -PesterOption @{IncludeVSCodeMarker=$true}
}
