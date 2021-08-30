
function Grant-CHttpUrlPermission
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Url,

        [Parameter(Mandatory=$true)]
        [Alias('Identity')]
        [string]
        
        $Principal,

        [Parameter(Mandatory=$true)]
        [Carbon.Security.HttpUrlAccessRights]
        
        
        
        
        
        $Permission
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $Url.EndsWith("/") )
    {
        $Url = '{0}/' -f $Url
    }

    $acl = Get-CHttpUrlAcl -LiteralUrl $Url -ErrorAction Ignore
    if( -not $acl )
    {
        $acl = New-Object 'Carbon.Security.HttpUrlSecurity' $Url
    }

    $id = Resolve-CIdentity -Name $Principal
    if( -not $id )
    {
        return
    }

    $currentRule = $acl.Access | Where-Object { $_.IdentityReference -eq $id.FullName }
    $currentRights = ''
    if( $currentRule )
    {
        if( $currentRule.HttpUrlAccessRights -eq $Permission )
        {
            return
        }
        $currentRights = $currentRule.HttpUrlAccessRights
    }

    Write-Verbose -Message ('[{0}]  [{1}]  {2} -> {3}' -f $Url,$id.FullName,$currentRights,$Permission)
    $rule = New-Object 'Carbon.Security.HttpUrlAccessRule' $id.Sid,$Permission
    $modifiedRule = $null
    $acl.ModifyAccessRule( ([Security.AccessControl.AccessControlModification]::RemoveAll), $rule, [ref]$modifiedRule )
    $acl.SetAccessRule( $rule )
}
