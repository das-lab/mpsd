$jsonFileName = "gherkin-languages.json"
$url = "https://raw.githubusercontent.com/cucumber/cucumber/master/gherkin/$jsonFileName"
$localFileName = "lib/Gherkin/$jsonFileName"
try {
    Invoke-WebRequest -Uri $url -OutFile $localFileName
    Write-Output "JSON file stored to $localFileName"
}
catch {
    
    Write-Warning "Could not get $url`n$($_.Exception)"
}
