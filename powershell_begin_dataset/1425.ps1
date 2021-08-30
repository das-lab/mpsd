
function Revoke-CHttpUrlPermission
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Url,

        [Parameter(Mandatory=$true)]
        [Alias('Identity')]
        [string]
        
        $Principal
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $id = Resolve-CIdentity -Name $Principal
    if( -not $id )
    {
        return
    }

    if( -not $Url.EndsWith('/') )
    {
        $Url = '{0}/' -f $Url
    }

    $acl = Get-CHttpUrlAcl -LiteralUrl $Url -ErrorAction Ignore
    if( -not $acl )
    {
        return
    }

    $currentAccess = $acl.Access | Where-Object { $_.IdentityReference -eq $id.FullName }
    if( $currentAccess )
    {
        Write-Verbose -Message ('[{0}]  [{1}]  {2} ->' -f $Url,$id.FullName,$currentAccess.HttpUrlAccessRights)
        $acl.RemoveAccessRule($currentAccess)
    }
}
