

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False,Position=0)]
        [Int]$ProcId=$pid
)

$datestr = (Get-Date -Format "yyyyMMddHHmmss")
$outfile = "${pwd}\" + ($env:COMPUTERNAME) + "_PId_" + ($pid) + "_${datestr}.dmp"

$obj = "" | Select-Object Path,PId,Base64EncodedGzippedBytes
$obj.PId = $ProcId
$obj.ProcessName = (Get-Process -Id $ProcId).Path

if (Test-Path "$env:SystemRoot\Procdump.exe") {
    
    $Suppress = & $env:SystemRoot\Procdump.exe /accepteula $ProcId $outfile 2> $null
    $File = ls $outfile 
    Try {
        
        $memFile = New-Object System.IO.MemoryStream (,[System.IO.File]::ReadAllBytes($File))

        
        $memStrm = New-Object System.IO.MemoryStream

        
        $gzStrm  = New-Object System.IO.Compression.GZipStream $memStrm, ([System.IO.Compression.CompressionMode]::Compress)

        
        $gzStrm.Write($memFile.ToArray(), 0, $File.Length)
        $gzStrm.Close()
        $gzStrm.Dispose()

        
        $obj.Base64EncodedGzippedBytes = [System.Convert]::ToBase64String($memStrm.ToArray())
    } Catch {
        Write-Error ("Caught Exception: {0}." -f $_)
    } Finally {
        Remove-Item $File 
    }
    
    $obj 
}