
function Remove-MrSavedCredential {

    [CmdletBinding(SupportsShouldProcess,
                   ConfirmImpact='Medium')]
    param (
        [Parameter(Mandatory,
                   ValueFromPipelineByPropertyName)]
        [string]$Target
    )

    PROCESS {
        if ($PSCmdlet.ShouldProcess($Target,'Delete')) {
            & "$env:windir\System32\cmdkey.exe" /delete $Target
        }
    }
    
}
