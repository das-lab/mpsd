



function Grant-RsSystemRole
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
        
        [switch]
        $Strict,
        
        [string]
        $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,
        
        $Proxy
    )
    
    if ($PSCmdlet.ShouldProcess((Get-ShouldProcessTargetweb -BoundParameters $PSBoundParameters), "Grant $RoleName on Report Server to $Identity"))
    {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
        
        
        
        Write-Verbose "Retrieving valid roles for System..."
        try
        {
            $roles = $proxy.ListRoles("System", $null)
        }
        catch
        {
            throw (New-Object System.Exception("Error retrieving roles for System! $($_.Exception.Message)", $_.Exception))
        }
        
        
        if ($roles.Name -notcontains $RoleName)
        {
            throw "Role name is not valid. Valid options are: $($roles.Name -join ", ")"
        }
        
        Write-verbose 'retrieving existing system policies'
        try
        {
            Write-Verbose "Retrieving system policies..."
            $originalPolicies = $proxy.GetSystemPolicies()
        }
        catch
        {
            throw (New-Object -TypeName System.Exception("Error retrieving existing system policies! $($_.Exception.Message)", $_.Exception))
        }
        Write-Verbose "Policies retrieved: $($originalPolicies.Length)!"
        
        Write-Verbose 'checking if the specified role already exists for the specified user/group name'
        if (($originalPolicies | Where-Object { $_.GroupUserName -eq $Identity }).Roles.Name -contains $RoleName)
        {
            if ($Strict)
            {
                throw "$($Identity) already has $($RoleName) privileges"
            }
            else
            {
                Write-Warning "$($Identity) already has $($RoleName) privileges"
                return
            }
        }
        
        
        
        
        $namespace = $proxy.GetType().Namespace
        $policyDataType = $namespace + '.Policy'
        $roleDataType = $namespace + '.Role'
        
        
        $numPolicies = $originalPolicies.Length + 1
        $policies = New-Object -TypeName "$policyDataType[]" -ArgumentList $numPolicies
        $index = 0
        foreach ($originalPolicy in $originalPolicies)
        {
            $policies[$index++] = $originalPolicy
        }
        
        
        $policy = New-Object -TypeName $policyDataType
        $policy.GroupUserName = $Identity
        
        
        $role = New-Object -TypeName $roleDataType
        $role.Name = $RoleName
        
        
        $numRoles = 1
        $policy.Roles = New-Object -TypeName "$roleDataType[]" -ArgumentList $numRoles
        $policy.Roles[0] = $role
        
        
        $policies[$originalPolicies.Length] = $policy
        
        
        try
        {
            Write-Verbose "Granting $($role.Name) to $($policy.GroupUserName)..."
            $proxy.SetSystemPolicies($policies)
            Write-Verbose "Granted $($role.Name) to $($policy.GroupUserName)!"
        }
        catch
        {
            throw (New-Object System.Exception("Error occurred while granting $($role.Name) to $($policy.GroupUserName)! $($_.Exception.Message)", $_.Exception))
        }
        
    }
}
New-Alias -Name "Grant-AccessToRs" -Value Grant-RsSystemRole -Scope Global
