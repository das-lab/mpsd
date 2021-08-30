

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False,Position=0)]
        [String]$Drive="$env:SystemDrive"
)

Function Expand-Zip ($zipfile, $destination) {
	[int32]$copyOption = 16 
    $shell = New-Object -ComObject shell.application
    $zip = $shell.Namespace($zipfile)
    foreach($item in $zip.items()) {
        $shell.Namespace($destination).copyhere($item, $copyOption)
    }
}

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

$flspath = ($env:SystemRoot + "\fls.zip")

if (Test-Path ($flspath)) {
    $suppress = New-Item -Name fls -ItemType Directory -Path $env:Temp -Force
    $flsdest = ($env:Temp + "\fls\")
    Expand-Zip $flspath $flsdest
    if (Test-Path($flsdest + "\fls.exe")) {
        
        $suppress = & $flsdest\fls.exe -r -m ($Drive) \\.\$Drive | Out-File "$flsdest\bodyfile.txt"

        $obj = "" | Select-Object FullName,Length,CreationTimeUtc,LastAccessTimeUtc,LastWriteTimeUtc,Content
        if (Test-Path("$flsdest\bodyfile.txt")) {
            $Target = ls "$flsdest\bodyfile.txt"
            $obj.FullName          = $Target.FullName
            $obj.Length            = $Target.Length
            $obj.CreationTimeUtc   = $Target.CreationTimeUtc
            $obj.LastAccessTimeUtc = $Target.LastAccessTimeUtc
            $obj.LastWriteTimeUtc  = $Target.LastWriteTimeUtc
            $obj.Content           = GetBase64GzippedStream($Target)
        }  
        
        $obj

        $suppress = Remove-Item $flsdest -Force -Recurse
    } else {
        "Fls.zip found, but not unzipped."
    }
} else {
    "Fls.zip not found on $env:COMPUTERNAME"
}