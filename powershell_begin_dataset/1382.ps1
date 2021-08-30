
function Test-CZipFile
{
    
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Alias('FullName')]
        [string]
        
        $Path
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Add-Type -Path (Join-Path -Path $CarbonBinDir -ChildPath 'Ionic.Zip.dll' -Resolve)

    $Path = Resolve-CFullPath -Path $Path
    if( -not (Test-Path -Path $Path -PathType Leaf) )
    {
        Write-Error ('File ''{0}'' not found.' -f $Path)
        return
    }

    return [Ionic.Zip.ZipFile]::IsZipFile( $Path )

}
