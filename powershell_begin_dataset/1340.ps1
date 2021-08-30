
function Remove-CIniEntry
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
        [Parameter(Mandatory=$true)]
        [string]
        
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name,
        
        [string]
        
        $Section,

        [Switch]
        
        $CaseSensitive
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $settings = @{ }
    
    if( Test-Path $Path -PathType Leaf )
    {
        $settings = Split-CIni -Path $Path -AsHashtable -CaseSensitive:$CaseSensitive
    }
    else
    {
        Write-Error ('INI file {0} not found.' -f $Path)
        return
    }

    $key = $Name
    if( $Section )
    {
        $key = '{0}.{1}' -f $Section,$Name
    }

    if( $settings.ContainsKey( $key ) )
    {
        $lines = New-Object 'Collections.ArrayList'
        Get-Content -Path $Path | ForEach-Object { [void] $lines.Add( $_ ) }
        $null = $lines.RemoveAt( ($settings[$key].LineNumber - 1) )
        if( $PSCmdlet.ShouldProcess( $Path, ('remove INI entry {0}' -f $key) ) )
        {
            if( $lines )
            {
                $lines | Set-Content -Path $Path
            }
            else
            {
                Clear-Content -Path $Path
            }
        }
    }

}
