


function Revoke-RsSystemAccess
{
    

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [Alias('UserOrGroupName')]
        [Parameter(Mandatory = $True)]
        [string]
        $Identity,
        
        [switch]
        $Strict,
        
        [string]
        $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy
    )
    
    if ($PSCmdlet.ShouldProcess((Get-ShouldProcessTargetweb -BoundParameters $PSBoundParameters), "Revoke all system access for $Identity"))
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
        
        
        
        try
        {
            Write-Verbose "Retrieving system policies..."
            $originalPolicies = $proxy.GetSystemPolicies()
            
            Write-Verbose "Policies retrieved: $($originalPolicies.Length)!"
        }
        catch
        {
            throw (New-Object System.Exception("Error retrieving existing system policies! $($_.Exception.Message)", $_.Exception))
        }
        
        
        $policyList = $originalPolicies | Where-Object { $_.GroupUserName -ne $Identity }
        
        if ($Strict -and (-not ($originalPolicies | Where-Object { $_.GroupUserName -eq $Identity })))
        {
            throw (New-Object System.Management.Automation.PSArgumentException("$Identity was not granted any rights on the Report Server!"))
        }
        
        
        
        try
        {
            Write-Verbose "Revoking all access for $Identity..."
            $proxy.SetSystemPolicies($policyList)
            Write-Verbose "Revoked all access for $Identity!"
        }
        catch
        {
            throw (New-Object System.Exception("Error occurred while revoking all access from $Identity! $($_.Exception.Message)", $_.Exception))
        }
        
    }
}
New-Alias -Name "Revoke-AccessToRs" -Value Revoke-RsSystemAccess -Scope Global
