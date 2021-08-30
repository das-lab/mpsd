
function Resolve-CPathCase
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [string]
        
        [Alias('FullName')]
        $Path
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-Path -Path $Path) )
    {
        Write-Error "Path '$Path' not found."
        return
    }

    $uri = [uri]$Path
    if( $uri.IsUnc )
    {
        Write-Error ('Path ''{0}'' is a UNC path, which is not supported.' -f $Path)
        return
    }

    if( -not ([IO.Path]::IsPathRooted($Path)) )
    {
        $Path = (Resolve-Path -Path $Path).Path
    }
    
    $qualifier = '{0}\' -f (Split-Path -Qualifier -Path $Path)
    $qualifier = Get-Item -Path $qualifier | Select-Object -ExpandProperty 'Name'
    $canonicalPath = ''
    do
    {
        $parent = Split-Path -Parent -Path $Path
        $leaf = Split-Path -Leaf -Path $Path
        $canonicalLeaf = Get-ChildItem -Path $parent -Filter $leaf
        if( $canonicalPath )
        {
            $canonicalPath = Join-Path -Path $canonicalLeaf -ChildPath $canonicalPath
        }
        else
        {
            $canonicalPath = $canonicalLeaf
        }
    }
    while( $parent -ne $qualifier -and ($Path = Split-Path -Parent -Path $Path) )

    return Join-Path -Path $qualifier -ChildPath $canonicalPath
}

Set-Alias -Name 'Get-PathCanonicalCase' -Value 'Resolve-CPathCase'

