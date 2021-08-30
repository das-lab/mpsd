Function Expand-GZipFile
{

[CmdletBinding()]
Param(
    [ValidateScript({Test-path -Path $_})]
    [String]$LiteralPath,
    $outfile = ($LiteralPath -replace '\.gz$','')
)
try{
    $FileStreamIn = New-Object -TypeName System.IO.FileStream -ArgumentList $LiteralPath, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read)
    $output = New-Object -TypeName System.IO.FileStream -ArgumentList $outFile, ([IO.FileMode]::Create), ([IO.FileAccess]::Write), ([IO.FileShare]::None)
    $GzipStream = New-Object -TypeName System.IO.Compression.GzipStream -ArgumentList $FileStreamIn, ([IO.Compression.CompressionMode]::Decompress)

    
    $buffer = New-Object -TypeName byte[] -ArgumentList 1024
    while($true){
        $read = $GzipStream.Read($buffer, 0, 1024)
        if ($read -le 0){break}
        $output.Write($buffer, 0, $read)
    }

    $GzipStream.Close()
    $output.Close()
    $FileStreamIn.Close()
}catch{
    throw $_
    if($GzipStream){$GzipStream.Close()}
    if($output){$output.Close()}
    if($FileStreamIn){$FileStreamIn.Close()}
}
}
