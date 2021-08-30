
function Enable-CAclInheritance
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [Alias('PSPath')]
        [string]
        
        $Path,
        
        [Switch]
        
        $Preserve
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $acl = Get-Acl -Path $Path
    if( $acl.AreAccessRulesProtected )
    {
        Write-Verbose -Message ('[{0}] Enabling access rule inheritance.' -f $Path)
        $acl.SetAccessRuleProtection($false, $Preserve)
        $acl | Set-Acl -Path $Path

        if( -not $Preserve )
        {
            Get-CPermission -Path $Path | ForEach-Object { Revoke-CPermission -Path $Path -Identity $_.IdentityReference }
        }
    }
}
