param([int]$Count=50, [int]$DelayMilliseconds=200)

function Write-Item($itemCount) {
    $i = 1

    while ($i -le $itemCount) {
        $str = "Output $i"
        Write-Output $str

        
        
        $i = $i + 1

        
        Start-Sleep -Milliseconds $DelayMilliseconds
    }
}




function Do-Work($workCount) {
    Write-Output "Doing work..."
    Write-Item $workcount
    Write-Host "Done!"
}

Do-Work $Count
