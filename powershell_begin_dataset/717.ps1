


function New-RsRestCredentialsInServerObject
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Alias('UseAsWindowsCredentials')]
        [switch]
        $WindowsCredentials,

        [Alias('ImpersonateAuthenticatedUser')]
        [switch]
        $ImpersonateUser
    )
    Process
    {
        return @{
            "UserName" = $Credential.Username;
            "Password" = $Credential.GetNetworkCredential().Password;
            "UseAsWindowsCredentials" = $WindowsCredentials -eq $true;
            "ImpersonateAuthenticatedUser" = $ImpersonateUser -eq $true;
        }
    }
}