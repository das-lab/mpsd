

$(foreach($file in (ls *Prox.xml)) {
    $data = Import-Clixml $file
    $data | Where-Object { $_.ProcessName -eq "System" } |
        Select-Object PSComputerName, ProcessName, StartTime
}) | Sort-Object StartTime