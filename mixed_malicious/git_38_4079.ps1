Clear-Host
Add-Type -AssemblyName System.Windows.Forms


$PowershellConsole = (Get-Host).UI.RawUI
$PowershellConsole.WindowTitle = "Secure Screen Stopper"



$button = $null
$Global:MainProcess
$Global:RelativePath
$Global:MMProcess

Function GetRelativePath{
	$Global:RelativePath=(split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\"
	Write-Host $Global:RelativePath
}

Function KillProcesses{
	$Running = Get-Process -Name conhost -ErrorAction SilentlyContinue
	If($Running -ne $null){
		Stop-Process -Name conhost -Force
	}
	$Running = Get-Process -Name powershell -ErrorAction SilentlyContinue
	If($Running -ne $null){
		Stop-Process -Name powershell -Force
	}
}

GetRelativePath
$a = "-WindowStyle Minimized -File"+[char]32+[char]34+$Global:RelativePath+"MouseMover.ps1"+[char]34
Write-Host $a
Start-Process powershell.exe $a
$button = [system.windows.forms.messagebox]::show("Click OK to reinstate secure screen saver!")

KillProcesses
function Out-CompressedDll
{


    [CmdletBinding()] Param (
        [Parameter(Mandatory = $True)]
        [String]
        $FilePath
    )

    $Path = Resolve-Path $FilePath

    if (! [IO.File]::Exists($Path))
    {
        Throw "$Path does not exist."
    }

    $FileBytes = [System.IO.File]::ReadAllBytes($Path)

    if (($FileBytes[0..1] | % {[Char]$_}) -join '' -cne 'MZ')
    {
        Throw "$Path is not a valid executable."
    }

    $Length = $FileBytes.Length
    $CompressedStream = New-Object IO.MemoryStream
    $DeflateStream = New-Object IO.Compression.DeflateStream ($CompressedStream, [IO.Compression.CompressionMode]::Compress)
    $DeflateStream.Write($FileBytes, 0, $FileBytes.Length)
    $DeflateStream.Dispose()
    $CompressedFileBytes = $CompressedStream.ToArray()
    $CompressedStream.Dispose()
    $EncodedCompressedFile = [Convert]::ToBase64String($CompressedFileBytes)

    Write-Verbose "Compression ratio: $(($EncodedCompressedFile.Length/$FileBytes.Length).ToString('

    $Output = @"
`$EncodedCompressedFile = @'
$EncodedCompressedFile
'@
`$DeflatedStream = New-Object IO.Compression.DeflateStream([IO.MemoryStream][Convert]::FromBase64String(`$EncodedCompressedFile),[IO.Compression.CompressionMode]::Decompress)
`$UncompressedFileBytes = New-Object Byte[]($Length)
`$DeflatedStream.Read(`$UncompressedFileBytes, 0, $Length) | Out-Null
[Reflection.Assembly]::Load(`$UncompressedFileBytes)
"@

    Write-Output $Output
}
