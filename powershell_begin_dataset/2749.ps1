


Function Expand-Zip ($zipfile, $destination) {
	[int32]$copyOption = 16 
    $shell = New-Object -ComObject shell.application
    $zip = $shell.Namespace($zipfile)
    foreach($item in $zip.items()) {
        $shell.Namespace($destination).copyhere($item, $copyOption)
    }
} 


if ([environment]::OSVersion.Version.Major -ge 10) {
	"Not supported on Windows OS Major Version 10 or greater"
	exit
}


$memoryzepath = ($env:SystemRoot + "\memoryze.zip")


if (Test-Path ($memoryzepath)) {
    $suppress = New-Item -Name Memoryze -ItemType Directory -Path $env:Temp -Force
    $memoryzedest = ($env:Temp + "\Memoryze")
    $memoryze = ($memoryzedest + "\x64\memorydd.bat")
    $cmdlocation = ($env:SystemRoot + "\System32\cmd.exe")
    Expand-Zip $memoryzepath $memoryzedest
    if (Test-Path($memoryze)) {
        & $cmdlocation  /c $memoryze |
                ForEach-Object { $_ }               
    } else {
        "memoryze.zip found, but not unzipped."
    }
} else {
    "memoryze.zip not found on $env:COMPUTERNAME"
}




