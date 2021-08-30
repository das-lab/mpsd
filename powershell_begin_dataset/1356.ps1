
function Get-CFileSharePermission
{
    
    [CmdletBinding()]
    [OutputType([Carbon.Security.ShareAccessRule])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name,

        [string]
        
        $Identity
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $share = Get-CFileShare -Name $Name
    if( -not $share )
    {
        return
    }

    if( $Identity )
    {
        if( -not [System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters( $Identity ) )
        {
            $Identity = Resolve-CIdentityName -Name $Identity -ErrorAction $ErrorActionPreference
            if( -not $Identity )
            {
                return
            }
        }
    }
        
    $acl = $null  
    $lsss = Get-WmiObject -Class 'Win32_LogicalShareSecuritySetting' -Filter "name='$Name'"
    if( -not $lsss )
    {
        return
    }

    $result = $lsss.GetSecurityDescriptor()
    if( -not $result )
    {
        return
    }

    if( $result.ReturnValue )
    {
        $win32lsssErrors = @{
                                [uint32]2 = 'Access Denied';
                                [uint32]8 = 'Unknown Failure';
                                [uint32]9 = 'Privilege Missing';
                                [uint32]21 = 'Invalid Parameter';
                            }
        Write-Error ('Failed to get ''{0}'' share''s security descriptor. WMI returned error code {1} which means: {2}' -f $Name,$result.ReturnValue,$win32lsssErrors[$result.ReturnValue])
        return
    }

    $sd = $result.Descriptor
    if( -not $sd -or -not $sd.DACL )
    {
        return
    }

    foreach($ace in $SD.DACL)
    {   
        if( -not $ace -or -not $ace.Trustee )
        {
            continue
        }

        [Carbon.Identity]$rId = [Carbon.Identity]::FindBySid( $ace.Trustee.SIDString )
        if( $Identity -and  (-not $rId -or $rId.FullName -notlike $Identity) )
        {
            continue
        }

        if( $rId )
        {
            $aceId = New-Object 'Security.Principal.NTAccount' $rId.FullName
        }
        else
        {
            $aceId = New-Object 'Security.Principal.SecurityIdentifier' $ace.Trustee.SIDString
        }

        New-Object 'Carbon.Security.ShareAccessRule' $aceId, $ace.AccessMask, $ace.AceType
    } 
}

