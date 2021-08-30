
function Expand-CItem
{
    
    [OutputType([IO.DirectoryInfo])]
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Path,

        [string]
        
        $OutDirectory,

        [Switch]
        
        $Force
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Add-Type -Path (Join-Path -Path $CarbonBinDir -ChildPath 'Ionic.Zip.dll' -Resolve)

    $Path = Resolve-Path -Path $Path | Select-Object -ExpandProperty 'ProviderPath'
    if( -not $Path )
    {
        return
    }

    if( -not (Test-CZipFile -Path $Path) )
    {
        Write-Error ('File ''{0}'' is not a ZIP file.' -f $Path)
        return
    }

    if( $OutDirectory )
    {
        $OutDirectory = Resolve-CFullPath -Path $OutDirectory
        if( (Test-Path -Path $OutDirectory -PathType Container) )
        {
            if( -not $Force -and (Get-ChildItem -LiteralPath $OutDirectory | Measure-Object | Select-Object -ExpandProperty Count) )
            {
                Write-Error ('Output directory ''{0}'' is not empty. Use the `-Force` switch to overwrite existing files/directories.' -f $OutDirectory)
                return
            }
        }
    }
    else
    {
        $OutDirectory = 'Carbon+Expand-CItem+{0}+{1}' -f (Split-Path -Leaf -Path $Path),([IO.Path]::GetRandomFileName())
        $OutDirectory = Join-Path -Path $env:TEMP -ChildPath $OutDirectory
        $null = New-Item -Path $OutDirectory -ItemType 'Directory'
    }

    $zipFile = [Ionic.Zip.ZipFile]::Read($Path)
    try
    {
        $zipFile.ExtractAll($OutDirectory, [Ionic.Zip.ExtractExistingFileAction]::OverwriteSilently)
    }
    finally
    {
        $zipFile.Dispose()
    }

    Get-Item -Path $OutDirectory
}
