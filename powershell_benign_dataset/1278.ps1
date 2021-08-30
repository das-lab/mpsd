
function Convert-CSecureStringToString
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Security.SecureString]
        
        $SecureString
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $stringPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    return [Runtime.InteropServices.Marshal]::PtrToStringAuto($stringPtr)
}

