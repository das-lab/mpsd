
function Set-CServiceAcl
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name,
        
        [Parameter(Mandatory=$true)]
        [Security.AccessControl.DiscretionaryAcl]
        
        $Dacl
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $rawSD = Get-CServiceSecurityDescriptor -Name $Name
    $daclBytes = New-Object byte[] $Dacl.BinaryLength 
    $Dacl.GetBinaryForm($daclBytes, 0);
    $rawSD.DiscretionaryAcl = New-Object Security.AccessControl.RawAcl $daclBytes,0
    $sdBytes = New-Object byte[] $rawSD.BinaryLength   
    $rawSD.GetBinaryForm($sdBytes, 0);
    
    if( $pscmdlet.ShouldProcess( ("{0} service DACL" -f $Name), "set" ) )
    {
        [Carbon.Service.ServiceSecurity]::SetServiceSecurityDescriptor( $Name, $sdBytes )
    }
}

