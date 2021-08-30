
function Get-CADDomainController
{
    
    [CmdletBinding()]
    param(
        [string]
        
        
        $Domain
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    if( $Domain )
    {
        $principalContext = $null
        try
        {
            Add-Type -AssemblyName System.DirectoryServices.AccountManagement
            $principalContext = New-Object DirectoryServices.AccountManagement.PrincipalContext Domain,$Domain
            return $principalContext.ConnectedServer
        }
        catch
        {
            $firstException = $_.Exception
            while( $firstException.InnerException )
            {
                $firstException = $firstException.InnerException
            }
            Write-Error ("Unable to find domain controller for domain '{0}': {1}: {2}" -f $Domain,$firstException.GetType().FullName,$firstException.Message)
            return $null
        }
        finally
        {
            if( $principalContext )
            {
                $principalContext.Dispose()
            }
        }
    }
    else
    {
        $root = New-Object DirectoryServices.DirectoryEntry "LDAP://RootDSE"
        try
        {
            return  $root.Properties["dnsHostName"][0].ToString();
        }
        finally
        {
            $root.Dispose()
        }
    }
}

