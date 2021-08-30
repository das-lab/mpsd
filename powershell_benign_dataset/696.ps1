



function Grant-RsCatalogItemRole
{
    

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param
    (
        [Alias('UserOrGroupName')]
        [Parameter(Mandatory = $True)]
        [string]
        $Identity,

        [Parameter(Mandatory = $True)]
        [string]
        $RoleName,

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

    if ($PSCmdlet.ShouldProcess((Get-ShouldProcessTargetweb -BoundParameters $PSBoundParameters), "Grant $RoleName on $Path to $Identity"))
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters

        
        
        Write-Verbose "Retrieving valid roles for Catalog items..."
        try
        {
            $roles = $proxy.ListRoles("Catalog", $null)
        }
        catch
        {
            throw (New-Object System.Exception("Error retrieving roles for catalog items! $($_.Exception.Message)", $_.Exception))
        }

        
        if ($roles.Name -notcontains $RoleName)
        {
            throw "Role name is not valid. Valid options are: $($roles.Name -join ", ")"
        }

        
        try
        {
            Write-Verbose "Retrieving policies for $Path..."
            $inheritsParentPolicy = $false
            $policies = $proxy.GetPolicies($Path, [ref]$inheritsParentPolicy)
        }
        catch
        {
            throw (New-Object System.Exception("Error retrieving existing policies for $Path! $($_.Exception.Message)", $_.Exception))
        }
        Write-Verbose "Policies retrieved: $($Policies.Length)!"

        
        if (($policies | Where-Object { $_.GroupUserName -eq $Identity }).Roles.Name -contains $RoleName)
        {
            if ($Strict)
            {
                throw "$($Identity) already has $($RoleName) privileges on $Path"
            }
            else
            {
                Write-Warning "$($Identity) already has $($RoleName) privileges on $Path"
                return
            }
        }
        

        
        
        $namespace = $proxy.GetType().Namespace
        $policyDataType = $namespace + '.Policy'
        $roleDataType = $namespace + '.Role'

        
        $policy = $policies | Where-Object { $_.GroupUserName -eq $Identity } | Select-Object -First 1

        
        if (-not $policy)
        {
            $policy = New-Object -TypeName $policyDataType
            $policy.GroupUserName = $Identity
            $policy.Roles = @()
            
            $policies += $policy
        }

        
        $role = $policy.Roles | Where-Object { $_.Name -eq $RoleName } | Select-Object -First 1
        if (-not $role)
        {
            $role = New-Object -TypeName $roleDataType
            $role.Name = $RoleName
            
            $policy.Roles += $role
        }

        
        try
        {
            Write-Verbose "Granting $($role.Name) to $($policy.GroupUserName) on $Path..."
            $proxy.SetPolicies($Path, $policies)
            Write-Verbose "Granted $($role.Name) to $($policy.GroupUserName) on $Path!"
        }
        catch
        {
            throw (New-Object System.Exception("Error occurred while granting $($role.Name) to $($policy.GroupUserName) on $Path! Please verify if you have typed the user full name. You can get the current permissions by running the Get-RsCatalogItemRole command. $($_.Exception.Message)", $_.Exception))
        }
        
    }
}
New-Alias -Name "Grant-AccessOnCatalogItem" -Value Grant-RsCatalogItemRole -Scope Global
