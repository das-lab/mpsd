

$data = $null

foreach ($file in (ls *svcall.xml)) {
    $data += Import-Clixml $file
}

$data | ? { $_.StartMode -eq "Auto" -or $_.State -eq "Running" }