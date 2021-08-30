















function Split-File ([string]$inFile, [int]$bufSize = 5mb) {
    $stream = [System.IO.File]::OpenRead($inFile)
    $chunkNum = 1
    $barr = New-Object byte[] $bufSize

    $fileinfo = [System.IO.FileInfo]$inFile
    $name = $fileinfo.Name
    $dir = $fileinfo.Directory

    while ($bytesRead = $stream.Read($barr, 0, $bufsize)) {
        $outFile = Join-Path $dir "$name.part$chunkNum"
        $ostream = [System.IO.File]::OpenWrite($outFile)
        $ostream.Write($barr, 0, $bytesRead)
        $ostream.Close()
        Write-Host "Wrote $outFile"
        $chunkNum += 1
    }
}




function Join-File ([string]$infilePrefix) {
    $fileinfo = [System.IO.FileInfo]$infilePrefix
    $outFile = Join-Path $fileinfo.Directory $fileinfo.BaseName
    $ostream = [System.Io.File]::OpenWrite($outFile)
    $chunkNum = 1
    $infileName = "$infilePrefix$chunkNum"

    while (Test-Path $infileName) {
        $bytes = [System.IO.File]::ReadAllBytes($infileName)
        $ostream.Write($bytes, 0, $bytes.Count)
        Write-Host "Read $infileName"
        $chunkNum += 1
        $infileName = "$infilePrefix$chunkNum"
    }

    $ostream.close()
}
