


Function Expand-Zip ($zipfile, $destination) {
	[int32]$copyOption = 16 
    $shell = New-Object -ComObject shell.application
    $zip = $shell.Namespace($zipfile)
    foreach($item in $zip.items()) {
        $shell.Namespace($destination).copyhere($item, $copyOption)
    }
}

$rkpath = ($env:SystemRoot + "\rekall.zip")

if (Test-Path ($rkpath)) {
    $suppress = New-Item -Name rekall -ItemType Directory -Path $env:Temp -Force
    $rkdest = ($env:Temp + "\rekall\")
    Expand-Zip $rkpath $env:Temp
    if (Test-Path($rkdest + "\rekal.exe")) {
        $suppress = & $rkdest\winpmem_1.5.5.exe -l
        & $rkdest\rekal.exe -f \\.\pmem pslist
        $suppress = & $rkdest\winpmem_1.5.5.exe -u
        $suppress = Remove-Item $rkdest -Force -Recurse
    } else {
        "rekall.zip found, but not unzipped."
    }
} else {
    "rekall.zip not found on $env:COMPUTERNAME"
}