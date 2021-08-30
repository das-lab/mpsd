

[CmdletBinding()] 
    
Param ([Parameter(Mandatory)] [string[]] $memstream = $(Throw("-memstream is required")),
       [Parameter(Mandatory)] [string[]] $outputloc = $(Throw("-outputloc is required"))
)

function Get-DecompressedByteArray {

	[CmdletBinding()] Param ([Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [byte[]] $byteArray)

	Process {
	    Write-Verbose "Get-DecompressedByteArray"
        $input = New-Object System.IO.MemoryStream( , $byteArray )
	    $output = New-Object System.IO.MemoryStream
        $gzipStream = New-Object System.IO.Compression.GzipStream $input, ([IO.Compression.CompressionMode]::Decompress)
	    $gzipStream.CopyTo( $output )
        $gzipStream.Close()
		$input.Close()
		[byte[]] $byteOutArray = $output.ToArray()
        Write-Output $byteOutArray
    }
}


function Write-StreamToDisk {
    
    [io.file]::WriteAllBytes("$outputloc",$(Get-DecompressedByteArray -byteArray $([System.Convert]::FromBase64String($memstream))))

}

Write-StreamToDisk -memstream $memstream -outputloc $outputloc
