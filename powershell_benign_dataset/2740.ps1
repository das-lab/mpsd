

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False,Position=0)]
        [String]$ScanPath="C:\Windows\System32"
)

Function Expand-Zip ($zipfile, $destination) {
	[int32]$copyOption = 16 
    $shell = New-Object -ComObject shell.application
    $zip = $shell.Namespace($zipfile)
    foreach($item in $zip.items()) {
        $shell.Namespace($destination).copyhere($item, $copyOption)
    }
} 

$lokipath = ($env:SystemRoot + "\loki.zip")


if (Test-Path ($lokipath)) {
    $null = New-Item -Name loki -ItemType Directory -Path $env:Temp -Force
    $lokidest = ($env:Temp + "\loki\")
    Expand-Zip $lokipath $lokidest
    if (Test-Path($lokidest + "loki.exe")) {
        
        if (Test-Path($ScanPath)) { 
            ( & ${lokidest}\loki.exe --csv --noindicator --dontwait -p $ScanPath 2>&1 ) | ConvertFrom-Csv -Header Timestamp,hostname,message_type,message | Select-Object Timestamp,message_type,message

            

            
            Start-Sleep -Seconds 10
            $null = Remove-Item $lokidest -Force -Recurse

        } else {
            Write-Error ("{0}: scanpath of {1} not found." -f $env:COMPUTERNAME, $ScanPath)
        }
    } else {
        Write-Error ("{0}: loki.zip found, but not unzipped." -f $env:COMPUTERNAME)
    }
} else {
    Write-Error ("{0}: loki.zip not found" -f $env:COMPUTERNAME)
}