
function Test-CFileShare
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $share = Get-CFileShare -Name ('{0}*' -f $Name) |
                Where-Object { $_.Name -eq $Name }

    return ($share -ne $null)
}

