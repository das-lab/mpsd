


[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$InputFile,
    [Parameter(Mandatory=$False,Position=1)]
    [ValidateSet("CSV","JSON","TSV","XML")]
        [String]$Format="CSV",
    [Parameter(Mandatory=$True,Position=2)]
        [String]$Field,
    [Parameter(Mandatory=$True,Position=3)]
        [String]$OutputFile,
    [Parameter(Mandatory=$False,Position=4)]
        [switch]$Force
)

function GetTimestampUTC {
    Get-Date (Get-Date).ToUniversalTime() -Format "yyyy-MM-ddTHH:mm:ssZ"
}

function ConvertBase64-ToByte {
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [String]$base64String
)
    
    
    
    Try {
        $Error.Clear()
        [System.Convert]::FromBase64String($base64String)
    } Catch {
        Write-Error ("Input string or file does not match Base64 encoding. Quitting.")
        exit
    }
}

$ErrorActionPreference = "SilentlyContinue"
if ($InPath = Resolve-Path $InputFile) {
    if ((Resolve-Path $OutputFile) -and (-not $Force)) {
        
        Write-Error ("{0}: Output file already exists. Remove it and try again or add -Force. Quitting." -f (GetTimestampUTC))
        Exit
    } else {
        

        $Suppress = New-Item -Path $OutputFile -ItemType File
        $OutputFile = ls $OutputFile

        switch ($Format) {
            
            "CSV" {
                $data = Import-Csv $InPath
            }
            "JSON" {
                $data = Get-Content -Raw -Path $InPath | ConvertFrom-Json
            }
            "TSV" {
                $data = Import-Csv -Delimiter "`t" -Path $InPath
            }
            "XML" {
                $data = Import-Clixml -Path $InPath
            }
            default {
                Write-Error ("{0}: Invalid or unsupported input format. Input file must be on of CSV, JSON, TSV or XML. Quitting." -f (GetTimestampUTC))
                Exit
            }
        }

        
        if (-not $data.$Field) {
            Write-Error ("{0}: Could not find the specified field name, {1} in the input file. Check the data and try again. Quitting." -f (GetTimestampUTC), $Field)
            Exit
        } else {
            
            $CompressedByteArray = [byte[]](ConvertBase64-ToByte -base64String $data.$Field)

            
            $CompressedByteStream = New-Object System.IO.MemoryStream(@(,$CompressedByteArray))

            
            $DecompressedStream = new-object -TypeName System.IO.MemoryStream

            
            $StreamDecompressor = New-Object System.IO.Compression.GZipStream $CompressedByteStream, ([System.IO.Compression.CompressionMode]::Decompress)

            
            $StreamDecompressor.CopyTo($DecompressedStream)

            
            [System.IO.File]::WriteAllBytes($OutputFile, $DecompressedStream.ToArray())

            $StreamDecompressor.Close()
            $CompressedByteStream.Close()
            Write-Verbose("Done.")
        }
    }
} else {
    Write-Error ("{0}: Could not resolve path to -InputFile argument {1}. Check the argument and try again, maybe. Quitting." -f (GetTimestampUTC), $InputFile)
    exit
}