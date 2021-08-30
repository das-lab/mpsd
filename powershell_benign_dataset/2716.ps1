


[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$File
)

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

$obj = "" | Select-Object FullName,Length,CreationTimeUtc,LastAccessTimeUtc,LastWriteTimeUtc,Hash,Content

if (Test-Path($File)) {
    $Target = ls $File
    $obj.FullName          = $Target.FullName
    $obj.Length            = $Target.Length
    $obj.CreationTimeUtc   = $Target.CreationTimeUtc
    $obj.LastAccessTimeUtc = $Target.LastAccessTimeUtc
    $obj.LastWriteTimeUtc  = $Target.LastWriteTimeUtc
    $EAP = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    Try {
        $obj.Hash              = $(Get-FileHash $File -Algorithm SHA256).Hash
    } Catch {
        $obj.Hash = 'Error hashing file'
    }
    $ErrorActionPreference = $EAP
    $obj.Content           = GetBase64GzippedStream($Target)
}  
$obj
