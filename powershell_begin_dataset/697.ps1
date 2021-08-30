


function Revoke-RsCatalogItemAccess
{
    

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [Alias('UserOrGroupName')]
        [Parameter(Mandatory = $True)]
        [string]
        $Identity,
        
        [Alias('ItemPath')]
        [Parameter(Mandatory = $True)]
        [string]
        $Path,
        
        [switch]
        $Strict,
        
        [string]
        $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy
    )
    
    if ($PSCmdlet.ShouldProcess((Get-ShouldProcessTargetweb -BoundParameters $PSBoundParameters), "Revoke all roles on $Path for $Identity"))
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters

        
        
        try
        {
            Write-Verbose "Retrieving policies for $Path..."
            $inheritsParentPolicy = $false
            $originalPolicies = $proxy.GetPolicies($Path, [ref] $inheritsParentPolicy)
            
            Write-Verbose "Policies retrieved: $($originalPolicies.Length)!"
        }
        catch
        {
            throw (New-Object System.Exception("Error retrieving existing policies for $Path! $($_.Exception.Message)", $_.Exception))
        }

        
        $policyList = $originalPolicies | Where-Object { $_.GroupUserName -ne $Identity }
        
        if ($Strict -and (-not ($originalPolicies | Where-Object { $_.GroupUserName -eq $Identity } )))
        {
            throw (New-Object System.Management.Automation.PSArgumentException("$Identity was not granted any rights on $Path!"))
        }
        
        
        
        try
        {
            Write-Verbose "Revoking all access from $Identity on $Path..."
            $proxy.SetPolicies($Path, $policyList)
            Write-Verbose "Revoked all access from $Identity on $Path!"
        }
        catch
        {
            throw (New-Object System.Exception("Error occurred while revoking all access from $Identity on $Path! $($_.Exception.Message)", $_.Exception))
        }
        
    }
}
New-Alias -Name "Revoke-AccessOnCatalogItem" -Value Revoke-RsCatalogItemAccess -Scope Global
