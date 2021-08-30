
    
    
    
    
    
    
    
    
    
    
    


param (
    [string] $configuration = 'Debug',
    [string] $pathDelimiter = ':'
)

$tempModulePath = $env:PSModulePath
$outputDir = "$PSScriptRoot/../artifacts/$configuration"
Write-Warning "Running Test-ModuleManfiest on .psd1 files in $outputDir"
$env:PSModulePath += "$pathDelimiter$outputDir/"
Write-Warning "PSModulePath: $env:PSModulePath"

$success = $true
foreach($psd1FilePath in Get-ChildItem -Path $outputDir -Recurse -Filter *.psd1) {
    $manifestError = $null
    Test-ModuleManifest -Path $psd1FilePath.FullName -ErrorVariable manifestError
    if($manifestError){
        Write-Warning "$($psd1FilePath.Name) failed to load."
        $success = $false
    }
}

$env:PSModulePath = $tempModulePath
if(-not $success) {
    Write-Warning 'Failure: One or more module manifests failed to load.'
    exit 1
}