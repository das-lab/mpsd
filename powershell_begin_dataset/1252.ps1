
function Remove-CGroupMember
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name,
        
        [Parameter(Mandatory=$true)]
        [string[]]
        
		[Alias('Members')]
        $Member
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    [DirectoryServices.AccountManagement.GroupPrincipal]$group = Get-CGroup -Name $Name
    if( -not $group )
    {
        return
    }
    
    try
    {
        foreach( $_member in $Member )
        {
            $identity = Resolve-CIdentity -Name $_member
            if( -not $identity )
            {
                continue
            }

            if( -not (Test-CGroupMember -GroupName $group.Name -Member $_member) )
            {
                continue
            }

            Write-Verbose -Message ('[{0}] Members      {1} ->' -f $Name,$identity.FullName)
            if( -not $PSCmdlet.ShouldProcess(('removing "{0}" from local group "{1}"' -f $identity.FullName, $group.Name), $null, $null) )
            {
                continue
            }

            try
            {
                $identity.RemoveFromLocalGroup( $group.Name )
            }
            catch
            {
                Write-Error ('Failed to remove "{0}" from local group "{1}": {2}.' -f $identity,$group.Name,$_)
            }
        }
    }
    finally
    {
        $group.Dispose()
    }
}

