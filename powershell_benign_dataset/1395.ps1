
function Get-CPowershellPath
{
    
    [CmdletBinding()]
    param(
        [Switch]
        
        $x86
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $psPath = $PSHOME
    if( Test-COSIs64Bit )
    {
        if( Test-CPowerShellIs64Bit )
        {
            if( $x86 )
            {
                
                $psPath = $PSHOME -replace 'System32','SysWOW64'
            }
        }
        else
        {
            if( -not $x86 )
            {
                
                $psPath = $PSHome -replace 'SysWOW64','sysnative'
            }
        }
    }
    else
    {
        
        $psPath = $PSHOME
    }
    
    Join-Path $psPath powershell.exe
}

