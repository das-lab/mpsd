
function Disable-CAclInheritance
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
    if( -not $acl.AreAccessRulesProtected )
    {
        Write-Verbose -Message ("[{0}] Disabling access rule inheritance." -f $Path)
        $acl.SetAccessRuleProtection( $true, $Preserve )
        $acl | Set-Acl -Path $Path
    }
}

Set-Alias -Name 'Unprotect-AclAccessRules' -Value 'Disable-CAclInheritance'
Set-Alias -Name 'Protect-Acl' -Value 'Disable-CAclInheritance'

