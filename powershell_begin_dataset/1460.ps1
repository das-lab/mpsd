
function Copy-CDscResource
{
    
    [CmdletBinding()]
    [OutputType([IO.FileInfo])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Path,

        [Parameter(Mandatory=$true)]
        [string]
        
        $Destination,

        [Switch]
        
        $Recurse,

        [Switch]
        
        $PassThru,

        [Switch]
        
        $Force
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $tempDir = New-CTempDirectory -Prefix 'Carbon+Copy-CDscResource+'

    try
    {
        foreach( $item in (Get-ChildItem -Path $Path -Exclude '*.checksum') )
        {
            $destinationPath = Join-Path -Path $Destination -ChildPath $item.Name
            if( $item.PSIsContainer )
            {
                if( $Recurse )
                {
                    if( -not (Test-Path -Path $destinationPath -PathType Container) )
                    {
                        New-Item -Path $destinationPath -ItemType 'Directory' | Out-Null
                    }
                    Copy-CDscResource -Path $item.FullName -Destination $destinationPath -Recurse -Force:$Force -PassThru:$PassThru
                }
                continue
            }

            $sourceChecksumPath = '{0}.checksum' -f $item.Name
            $sourceChecksumPath = Join-Path -Path $tempDir -ChildPath $sourceChecksumPath
            $sourceChecksum = Get-FileHash -Path $item.FullName | Select-Object -ExpandProperty 'Hash'
            
            [IO.File]::WriteAllText($sourceChecksumPath, $sourceChecksum)

            $destinationChecksum = ''

            $destinationChecksumPath = '{0}.checksum' -f $destinationPath
            if( (Test-Path -Path $destinationChecksumPath -PathType Leaf) )
            {
                $destinationChecksum = Get-Content -TotalCount 1 -Path $destinationChecksumPath
            }

            if( $Force -or -not (Test-Path -Path $destinationPath -PathType Leaf) -or ($sourceChecksum -ne $destinationChecksum) )
            {
                Copy-Item -Path $item -Destination $Destination -PassThru:$PassThru
                Copy-Item -Path $sourceChecksumPath -Destination $Destination -PassThru:$PassThru
            }
            else
            {
                Write-Verbose ('File ''{0}'' already up-to-date.' -f $destinationPath)
            }
        }
    }
    finally
    {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction Ignore
    }
}
