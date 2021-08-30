function Test-DatePattern
{

$patterns = "d","D","g","G","f","F","m","o","r","s", "t","T","u","U","Y","dd","MM","yyyy","yy","hh","mm","ss","yyyyMMdd","yyyyMMddhhmm","yyyyMMddhhmmss"

Write-host "It is now $(Get-Date)" -ForegroundColor Green

foreach ($pattern in $patterns) {


[pscustomobject]@{
 Pattern = $pattern
 Syntax = "Get-Date -format '$pattern'"
 Value = (Get-Date -Format $pattern)
}

} 

Write-Host "Most patterns are case sensitive" -ForegroundColor Green
}
