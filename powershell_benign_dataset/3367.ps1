


param(
    [string] $RootPath = "$PSScriptRoot\..\src",
    [string] $OutputFile = "$PSScriptRoot\groupMapping.json",
    [string] $WarningFile = "$PSScriptRoot\groupMappingWarnings.json",
    [string] $RulesFile = "$PSScriptRoot\CreateMappings_rules.json"
);


$rules = Get-Content -Raw -Path $RulesFile | ConvertFrom-Json;


$results = @{};
$warnings = @();


$cmdlets = Get-ChildItem $RootPath -Recurse | Where-Object { $_.FullName -cmatch ".*\\help\\.*-.*.md" -and $_.Fullname -notlike "*Stack*" };

$k = 0;
$cmdlets | ForEach-Object {
    $cmdletPath = Split-Path $_.FullName -Parent;
    $cmdlet = $_.BaseName;

    
    $matchedRule = @($rules | Where-Object { $cmdletPath -cmatch ".*$($_.Regex).*" })[0];

    
    $possibleBetterMatch = @($rules | Where-Object { $cmdlet -cmatch ".*$($_.Regex).*" })[0];

    
    if(
        
        (($matchedRule -eq $null) -and ($possibleBetterMatch -ne $null)) -or
        
        (($matchedRule.Group -ne $null) -and ($matchedRule.Group -eq $possibleBetterMatch.Group)))
    {
        $matchedRule = $possibleBetterMatch;
    }

    
    if($matchedRule -eq $null) {
        $warnings += $cmdlet;
        $results[$cmdlet] = "Other";
    } else {
        $results[$cmdlet] = $matchedRule.Alias;
    }
};


$warnings | ConvertTo-Json | Out-File $WarningFile -Encoding utf8;
$results | ConvertTo-Json | Out-File $OutputFile -Encoding utf8;


Write-Host ""
Write-Host "$($results.Count) cmdlets successfully mapped: $($OutputFile)." -ForegroundColor Green;
Write-Host ""

if($warnings.Count -gt 0) {
    Write-Host "$($warnings.Count) cmdlets could not be mapped and were placed in 'Other': $($WarningFile)." -ForegroundColor Yellow;
    throw "Some cmdlets could not be properly mapped to a documentation grouping: $($warnings -join ", ").  Please add a mapping rule to $(Resolve-Path -Path $RulesFile).";
}
