
function Test-CGroupMember
{
    
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $GroupName,

        [Parameter(Mandatory=$true)]
        [string] 
        
        $Member
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-CGroup -Name $GroupName) )
    {
        Write-Error -Message ('Group ''{0}'' not found.' -f $GroupName)
        return
    }

    $group = Get-CGroup -Name $GroupName
    if( -not $group )
    {
        return
    }
    
    $principal = Resolve-CIdentity -Name $Member
    if( -not $principal )
    {
        return
    }

    try
    {
        return $principal.IsMemberOfLocalGroup($group.Name)
    }
    catch
    {
        Write-Error -Message ('Checking if "{0}" is a member of local group "{1}" failed: {2}' -f $principal.FullName,$group.Name,$_)
    }
}
