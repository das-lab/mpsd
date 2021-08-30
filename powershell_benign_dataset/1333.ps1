
function Reset-CHostsFile
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
       [string]
       
       $Path = (Get-CPathToHostsFile)
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
 
    if(-not (Test-Path $Path) )
    {
       Write-Warning "Creating hosts file '$Path'."
       New-Item $Path -ItemType File
    }
    
    $cmdErrors = @()
    [string[]]$lines = Read-CFile -Path $Path -ErrorVariable 'cmdErrors'
    if( $cmdErrors )
    {
        return
    }

    $outLines = New-Object -TypeName 'System.Collections.ArrayList'
    foreach($line in $lines)
    {
        if($line.Trim().StartsWith("
        {
            [void] $outlines.Add($line)
        }
        else
        {
            break
        }
    }
    
    [void] $outlines.Add("127.0.0.1       localhost")
    
    if( $PSCmdlet.ShouldProcess( $Path, "Reset-CHostsFile" ) )
    {
        $outlines | Write-CFile -Path $Path
    }     
}

