

$data = $null

foreach ($file in (ls *svcall.xml)) {
    $data += Import-Clixml $file
}

$data | Select-Object Caption, Pathname | Sort-Object Caption, Pathname | Group-Object Caption, Pathname | Sort-Object Name