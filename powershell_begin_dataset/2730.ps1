



function GetBase64GzippedStream {
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [System.IO.FileInfo]$File
)
    
    $memFile = New-Object System.IO.MemoryStream (,[System.IO.File]::ReadAllBytes($File))
        
    
    $memStrm = New-Object System.IO.MemoryStream

    
    $gzStrm  = New-Object System.IO.Compression.GZipStream $memStrm, ([System.IO.Compression.CompressionMode]::Compress)

    
    $gzStrm.Write($memFile.ToArray(), 0, $File.Length)
    $gzStrm.Close()
    $gzStrm.Dispose()

    
    [System.Convert]::ToBase64String($memStrm.ToArray())
}

$Comp = $env:COMPUTERNAME
$Date = Get-Date -Format "yyyyMMddHHmmss"
$Path = ($env:temp) + "\" + $Comp + "_" + $Date + "GPResult.xml"

if (Get-Command Get-GPResultantSetOfPolicy -ErrorAction SilentlyContinue) {
    Get-GPResultantSetOfPolicy -Path $Path -ReportType XML
} else {
    GPResult.exe /X $Path
}

if ($File = ls $Path) {
    $obj = "" | Select-Object GPResultB64GZ
    $obj.GPResultB64GZ = GetBase64GzippedStream $File
} else {
    $obj.GPResultB64GZ = ("{0} could not find {1} on {2}." -f ($MyInvocation.InvocationName), $Path, $Comp)
}
$obj
