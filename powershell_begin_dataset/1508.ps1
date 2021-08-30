













function Assert-NoError
{
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]
        
        $Message
    )

    Set-StrictMode -Version 'Latest'

    if( $Global:Error.Count -gt 0 )
    {
        $errors = $Global:Error | ForEach-Object { $_; if( (Get-Member 'ScriptStackTrace' -InputObject $_) ) { $_.ScriptStackTrace } ; "`n" } | Out-String
        Fail "Found $($Global:Error.Count) errors, expected none. $Message`n$errors" 
    }
}

Set-Alias -Name 'Assert-NoErrors' -Value 'Assert-NoError'
