
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [parameter(Mandatory=$true, ParameterSetName="AllObjectTypes", HelpMessage="Specify the features to delegate permissions for")]
    [parameter(Mandatory=$true, ParameterSetName="SpecificObjectTypes")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("PasswordWriteBack","PasswordSynchronization","ExchangeHybrid")]
    [string[]]$Feature,
    [parameter(Mandatory=$true, ParameterSetName="AllObjectTypes", HelpMessage="Specify the Display Name of a service account or group")]
    [parameter(Mandatory=$true, ParameterSetName="SpecificObjectTypes")]
    [ValidateNotNullOrEmpty()]
    [string]$IdentityName,
    [parameter(Mandatory=$true, ParameterSetName="AllObjectTypes", HelpMessage="Choose (All) for inheritance for this object and all descendents, or (Descendents) for all descendents only")]
    [parameter(Mandatory=$true, ParameterSetName="SpecificObjectTypes")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("All","Descendents")]
    [string]$Inheritance,
    [parameter(Mandatory=$true, ParameterSetName="SpecificObjectTypes", HelpMessage="By specifying an ObjectType, the permissions will only apply for the specified ObjectType, e.g. users")]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("user")]
    [string]$ObjectType

)
Begin {
    
    $CurrentLocation = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
    
    if ($Host.Version -le "2.0") {
        try {
            Import-Module ActiveDirectory -ErrorAction Stop -Verbose:$false
        }
        catch [Exception] {
            Write-Warning -Message "Unable to load the Active Directory PowerShell module" ; break
        }
    }
    
    $RootDSE = Get-ADRootDSE -Verbose:$false
    $Domain = Get-ADDomain -Verbose:$false
    
    $GUIDMapping = New-Object -TypeName System.Collections.Hashtable
    $ExtendedRightsMapping = New-Object -TypeName System.Collections.Hashtable
    if (($PSBoundParameters["ObjectType"]) -or ($Feature -eq "ExchangeHybrid")) {
        
        $GUIDMappingObjects = Get-ADObject -SearchBase $RootDSE.schemaNamingContext -LDAPFilter "(schemaIDGUID=*)" -Properties ldapDisplayName, schemaIDGUID -Verbose:$false
        foreach ($GUIDMappingObject in $GUIDMappingObjects) {
            $GUIDMapping.Add(($GUIDMappingObject.ldapDisplayName), [System.GUID]$GUIDMappingObject.schemaIDGUID)
        }
    }
    
    $ExtendedRightsObjects = Get-ADObject -SearchBase $RootDSE.configurationNamingContext -LDAPFilter "(&(objectClass=controlAccessRight)(rightsGUID=*))" -Properties displayName, rightsGUID -Verbose:$false
    foreach ($ExtendedRightsObject in $ExtendedRightsObjects) {
        $ExtendedRightsMapping.Add($ExtendedRightsObject.displayName, [System.GUID]$ExtendedRightsObject.rightsGUID)
    }
    
    Set-Location -Path AD: -Verbose:$false
}
Process {
    function Set-ACLPermission {
        param(
            [parameter(Mandatory=$true, ParameterSetName="AccessRule")]
            [parameter(Mandatory=$true, ParameterSetName="ExtendedRights")]
            [ValidateSet("ExtendedRights","AccessRule")]
            [string]$Option,
            [parameter(Mandatory=$true, ParameterSetName="ExtendedRights")]
            [string[]]$ExtendedRights,
            [parameter(Mandatory=$true, ParameterSetName="AccessRule")]
            [string[]]$AccessRules
        )
        if ($Option -eq "ExtendedRights") {
            
            $ExtendedRightsList = New-Object -TypeName System.Collections.ArrayList
            $ExtendedRightsList.AddRange(@($ExtendedRights)) | Out-Null
            foreach ($ExtendedRight in $ExtendedRightsList) {
                if ($Script:PSBoundParameters["ObjectType"]) {
                    
                    $ExtendedRightObject = New-Object -TypeName System.DirectoryServices.ExtendedRightAccessRule -ArgumentList ($SecurityIdentifier, "Allow", $ExtendedRightsMapping["$($ExtendedRight)"], "$($Inheritance)", $GUIDMapping["$($ObjectType)"])
                    Write-Verbose -Message "Constructed ExtendedRightAccessRule object for ObjectType '$($ObjectType)' and '$($ExtendedRight)' extended right"
                }
                else {
                    
                    $ExtendedRightObject = New-Object -TypeName System.DirectoryServices.ExtendedRightAccessRule -ArgumentList ($SecurityIdentifier, "Allow", $ExtendedRightsMapping["$($ExtendedRight)"], "$($Inheritance)")
                    Write-Verbose -Message "Constructed ExtendedRightAccessRule object for '$($ExtendedRight)' extended right"
                }
                
                $DACL.AddAccessRule($ExtendedRightObject)
            }
        }
        if ($Option -eq "AccessRule") {
            
            $AccessRuleList = New-Object -TypeName System.Collections.ArrayList
            $AccessRuleList.AddRange(@($AccessRules)) | Out-Null
            
            $AccessRuleObject = New-Object -TypeName System.DirectoryServices.ActiveDirectoryAccessRule -ArgumentList ($SecurityIdentifier, "ReadProperty,WriteProperty", "Allow", $GUIDMapping["proxyAddresses"], "Descendents", $GUIDMapping["contact"])
            Write-Verbose -Message "Constructed ActiveDirectoryAccessRule object with 'ReadProperty' and 'WriteProperty' for Object Type 'contact'"
            
            $DACL.AddAccessRule($AccessRuleObject)
            
            $AccessRuleObject = New-Object -TypeName System.DirectoryServices.ActiveDirectoryAccessRule -ArgumentList ($SecurityIdentifier, "ReadProperty,WriteProperty", "Allow", $GUIDMapping["proxyAddresses"], "Descendents", $GUIDMapping["group"])
            Write-Verbose -Message "Constructed ActiveDirectoryAccessRule object with 'ReadProperty' and 'WriteProperty' for Object Type 'group'"
            
            $DACL.AddAccessRule($AccessRuleObject)
            
            foreach ($AccessRule in $AccessRuleList) {
                $AccessRuleObject = New-Object -TypeName System.DirectoryServices.ActiveDirectoryAccessRule -ArgumentList ($SecurityIdentifier, "ReadProperty,WriteProperty", "Allow", $GUIDMapping["$($AccessRule)"], "Descendents", $GUIDMapping["user"])
                Write-Verbose -Message "Constructed ActiveDirectoryAccessRule object with 'ReadProperty' and 'WriteProperty' for attribute '$($AccessRule)' for Object Type 'users'"
                
                $DACL.AddAccessRule($AccessRuleObject)
            }
        }
        
        if ($Script:PSCmdlet.ShouldProcess($Domain.DistinguishedName, "Set ACL permissions")) {
            try {
                Set-Acl -AclObject $DACL -Path (Join-Path -Path "AD:\" -ChildPath $Domain.DistinguishedName) -ErrorAction Stop -Verbose:$false
                Write-Verbose -Message "Successfully updated ACL for '$($Domain.DistinguishedName)'"
            }
            catch [Exception] {
                Write-Warning -Message "Unable to update ACL for identity '$($IdentityName)'"
                Set-Location -Path $CurrentLocation ; break
            }
        }
    }

    
    try {
        $IdentitySID = Get-ADObject -Filter "Name -like '$($IdentityName)'" -Properties objectSID -Verbose:$false | Select-Object -ExpandProperty objectSID
        if (($IdentitySID | Measure-Object).Count -eq 0) {
            Write-Warning -Message "Query for identity '$($IdentityName)' did not return any objects"
            Set-Location -Path $CurrentLocation ; break
        }
        elseif (($IdentitySID | Measure-Object).Count -eq 1) {
            Write-Verbose -Message "Validated specified identity '$($IdentityName)' with SID '$($IdentitySID)'"
        }
        else {
            Write-Warning -Message "Query for identity '$($IdentityName)' returned more than one object, please refine your identity"
            Set-Location -Path $CurrentLocation ; break
        }
    }
    catch [Exception] {
        Write-Warning -Message "Unable to determine Active Directory identity reference object from specified argument '$($IdentityName)'" ; break
    }
    
    $SecurityIdentifier = New-Object -TypeName System.Security.Principal.SecurityIdentifier -ArgumentList $IdentitySID
    
    try {
        $DACL = Get-Acl -Path ($Domain.DistinguishedName) -ErrorAction Stop -Verbose:$false
    }
    catch [Exception] {
        Write-Warning -Message "Unable to determine DACL for domain"
        Set-Location -Path $CurrentLocation ; break
    }
    
    foreach ($CurrentFeature in $Feature) {
        if ($CurrentFeature -eq "PasswordSynchronization") {
            
            Set-ACLPermission -Option ExtendedRights -ExtendedRights "Replicating Directory Changes", "Replicating Directory Changes All"
        }
        if ($CurrentFeature -eq "PasswordWriteBack") {
            
            Set-ACLPermission -Option ExtendedRights -ExtendedRights "Reset Password", "Change Password"
        }
        if ($CurrentFeature -eq "ExchangeHybrid") {
            
            Set-ACLPermission -Option AccessRule -AccessRules "msExchArchiveStatus", "msExchBlockedSendersHash", "msExchSafeRecipientsHash", "msExchSafeSendersHash", "msExchUCVoiceMailSettings", "msExchUserHoldPolicies", "proxyAddresses"
        }
    }
}
End {
    
    Set-Location -Path $CurrentLocation -Verbose:$false
}