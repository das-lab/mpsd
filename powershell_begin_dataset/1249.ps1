
function Remove-CJunction
{
    
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='Path')]
    param(
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='Path')]
        [string]
        
        
        
        $Path,

        [Parameter(Mandatory=$true,ParameterSetName='LiteralPath')]
        [string]
        
        
        
        $LiteralPath
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $PSCmdlet.ParameterSetName -eq 'Path' )
    {
        if( [Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Path) )
        {
            Get-Item -Path $Path |
                Where-Object { $_.PsIsContainer -and $_.IsJunction } |
                ForEach-Object { Remove-CJunction -Path $_.FullName }
        }
        else
        {
            Remove-CJunction -LiteralPath $Path
        }
        return
    }

    if( -not (Test-Path -LiteralPath $LiteralPath) )
    {
        Write-Error ('Path ''{0}'' not found.' -f $LiteralPath)
        return
    }
    
    if( (Test-Path -LiteralPath $LiteralPath -PathType Leaf) )
    {
        Write-Error ('Path ''{0}'' is a file, not a junction.' -f $LiteralPath)
        return
    }
    
    if( Test-CPathIsJunction -LiteralPath $LiteralPath  )
    {
        $LiteralPath = Resolve-Path -LiteralPath $LiteralPath | 
                            Select-Object -ExpandProperty ProviderPath
        if( $PSCmdlet.ShouldProcess($LiteralPath, "remove junction") )
        {
            [Carbon.IO.JunctionPoint]::Delete( $LiteralPath )
        }
    }
    else
    {
        Write-Error ("Path '{0}' is a directory, not a junction." -f $LiteralPath)
    }
}

