

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

function add-zip
{
    param([string]$zipfilename)

    if (-not (Test-Path($zipfilename))) {
        Set-Content $zipfilename ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))
        (dir $zipfilename).IsReadOnly = $false
    }

    $shellApplication = New-Object -com shell.application
    $zipPackage = $shellApplication.NameSpace($zipfilename)

    foreach($file in $input) {
        $zipPackage.CopyHere($file.FullName)
        Start-Sleep -milliseconds 100
    }
}

$pfconf = (Get-ItemProperty "hklm:\system\currentcontrolset\control\session manager\memory management\prefetchparameters").EnablePrefetcher 
Switch -Regex ($pfconf) {
    "[1-3]" {
        $zipfile = (($env:TEMP) + "\" + ($env:COMPUTERNAME) + "-PrefetchFiles.zip")
        if (Test-Path $zipfile) { rm $zipfile -Force }
        ls $env:windir\Prefetch\*.pf | add-zip $zipfile
        
        
        $obj = "" | Select-Object FullName,Length,CreationTimeUtc,LastAccessTimeUtc,LastWriteTimeUtc,Content
        $Target = ls $zipfile
        $obj.FullName          = $Target.FullName
        $obj.Length            = $Target.Length
        $obj.CreationTimeUtc   = $Target.CreationTimeUtc
        $obj.LastAccessTimeUtc = $Target.LastAccessTimeUtc
        $obj.LastWriteTimeUtc  = $Target.LastWriteTimeUtc
        $obj.Content           = GetBase64GzippedStream($Target)
        $obj
        $suppress = Remove-Item $zipfile
    }
    default {
    
    }
}
