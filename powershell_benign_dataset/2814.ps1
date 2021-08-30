

$data = $null

foreach ($file in (ls *svcall.xml)) {
    $data += Import-Clixml $file
}

$data | Select-Object Caption, StartName | Sort-Object Caption, StartName | Group-Object Caption, StartName | Sort-Object Name