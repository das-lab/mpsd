
function Install-CJunction
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([IO.DirectoryInfo])]
    param(
        [Parameter(Mandatory=$true)]
        [Alias("Junction")]
        [string]
        
        $Link,
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $Target,

        [Switch]
        
        $PassThru,

        [Switch]
        
        $Force
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $Link = Resolve-CFullPath -Path $Link
    $Target = Resolve-CFullPath -Path $Target

    if( Test-Path -LiteralPath $Target -PathType Leaf )
    {
        Write-Error ('Unable to create junction {0}: target {1} exists and is a file.' -f $Link,$Target)
        return
    }

    if( -not (Test-Path -LiteralPath $Target -PathType Container) )
    {
        if( $Force )
        {
            New-Item -Path $Target -ItemType Directory -Force | Out-String | Write-Verbose
        }
        else
        {
            Write-Error ('Unable to create junction {0}: target {1} not found.  Use the `-Force` switch to create target paths that don''t exist.' -f $Link,$Target)
            return
        }
    }

    if( Test-Path -LiteralPath $Link -PathType Container )
    {
        $junction = Get-Item -LiteralPath $Link -Force
        if( -not $junction.IsJunction )
        {
            Write-Error ('Failed to create junction ''{0}'': a directory exists with that path and it is not a junction.' -f $Link)
            return
        }

        if( $junction.TargetPath -eq $Target )
        {
            return
        }

        Remove-CJunction -LiteralPath $Link
    }

    if( $PSCmdlet.ShouldProcess( $Target, ("creating '{0}' junction" -f $Link) ) )
    {
        $result = New-CJunction -Link $Link -Target $target -Verbose:$false
        if( $PassThru )
        {
            return $result
        }
    }
}

