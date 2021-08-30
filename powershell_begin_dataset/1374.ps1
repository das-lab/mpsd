
function Grant-CPermission
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([Security.AccessControl.AccessRule])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $Identity,
        
        [Parameter(Mandatory=$true)]
        [string[]]
        
		[Alias('Permissions')]
        $Permission,
        
        [Carbon.Security.ContainerInheritanceFlags]
        
        $ApplyTo = ([Carbon.Security.ContainerInheritanceFlags]::ContainerAndSubContainersAndLeaves),

        [Security.AccessControl.AccessControlType]
        
        
        
        $Type = [Security.AccessControl.AccessControlType]::Allow,
        
        [Switch]
        
        $Clear,

        [Switch]
        
        
        
        $PassThru,

        [Switch]
        
        $Force,

        [Switch]
        
        
        
        $Append
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $Path = Resolve-Path -Path $Path
    if( -not $Path )
    {
        return
    }

    $providerName = Get-CPathProvider -Path $Path | Select-Object -ExpandProperty 'Name'
    if( $providerName -eq 'Certificate' )
    {
        $providerName = 'CryptoKey'
    }

    if( $providerName -ne 'Registry' -and $providerName -ne 'FileSystem' -and $providerName -ne 'CryptoKey' )
    {
        Write-Error "Unsupported path: '$Path' belongs to the '$providerName' provider.  Only file system, registry, and certificate paths are supported."
        return
    }

    $rights = $Permission | ConvertTo-ProviderAccessControlRights -ProviderName $providerName
    if( -not $rights )
    {
        Write-Error ('Unable to grant {0} {1} permissions on {2}: received an unknown permission.' -f $Identity,($Permission -join ','),$Path)
        return
    }

    if( -not (Test-CIdentity -Name $Identity ) )
    {
        Write-Error ('Identity ''{0}'' not found.' -f $Identity)
        return
    }

    $Identity = Resolve-CIdentityName -Name $Identity
    
    if( $providerName -eq 'CryptoKey' )
    {
        Get-Item -Path $Path |
            ForEach-Object {
                [Security.Cryptography.X509Certificates.X509Certificate2]$certificate = $_

                if( -not $certificate.HasPrivateKey )
                {
                    Write-Warning ('Certificate {0} ({1}; {2}) does not have a private key.' -f $certificate.Thumbprint,$certificate.Subject,$Path)
                    return
                }

                if( -not $certificate.PrivateKey )
                {
                    Write-Error ('Access is denied to private key of certificate {0} ({1}; {2}).' -f $certificate.Thumbprint,$certificate.Subject,$Path)
                    return
                }

                [Security.AccessControl.CryptoKeySecurity]$keySecurity = $certificate.PrivateKey.CspKeyContainerInfo.CryptoKeySecurity
                if( -not $keySecurity )
                {
                    Write-Error ('Private key ACL not found for certificate {0} ({1}; {2}).' -f $certificate.Thumbprint,$certificate.Subject,$Path)
                    return
                }

                $rulesToRemove = @()
                if( $Clear )
                {
                    $rulesToRemove = $keySecurity.Access | 
                                        Where-Object { $_.IdentityReference.Value -ne $Identity } |
                                        
                                        Where-Object { $_.IdentityReference.Value -ne 'BUILTIN\Administrators' }
                    if( $rulesToRemove )
                    {
                        $rulesToRemove | ForEach-Object { 
                            Write-Verbose ('[{0} {1}] [{1}]  {2} -> ' -f $certificate.IssuedTo,$Path,$_.IdentityReference,$_.CryptoKeyRights)
                            if( -not $keySecurity.RemoveAccessRule( $_ ) )
                            {
                                Write-Error ('Failed to remove {0}''s {1} permissions on ''{2}'' (3) certificate''s private key.' -f $_.IdentityReference,$_.CryptoKeyRights,$Certificate.Subject,$Certificate.Thumbprint)
                            }
                        }
                    }
                }
                
                $certPath = Join-Path -Path 'cert:' -ChildPath (Split-Path -NoQualifier -Path $certificate.PSPath)

                $accessRule = New-Object 'Security.AccessControl.CryptoKeyAccessRule' ($Identity,$rights,$Type) |
                                Add-Member -MemberType NoteProperty -Name 'Path' -Value $certPath -PassThru

                if( $Force -or $rulesToRemove -or -not (Test-CPermission -Path $certPath -Identity $Identity -Permission $Permission -Exact) )
                {
                    $currentPerm = Get-CPermission -Path $certPath -Identity $Identity
                    if( $currentPerm )
                    {
                        $currentPerm = $currentPerm."$($providerName)Rights"
                    }
                    Write-Verbose -Message ('[{0} {1}] [{2}]  {3} -> {4}' -f $certificate.IssuedTo,$certPath,$accessRule.IdentityReference,$currentPerm,$accessRule.CryptoKeyRights)
                    $keySecurity.SetAccessRule( $accessRule )
                    Set-CryptoKeySecurity -Certificate $certificate -CryptoKeySecurity $keySecurity -Action ('grant {0} {1} permission(s)' -f $Identity,($Permission -join ','))
                }

                if( $PassThru )
                {
                    return $accessRule
                }
            }
    }
    else
    {
        
        
        
        $currentAcl = (Get-Item $Path -Force).GetAccessControl("Access")
    
        $inheritanceFlags = [Security.AccessControl.InheritanceFlags]::None
        $propagationFlags = [Security.AccessControl.PropagationFlags]::None
        $testPermissionParams = @{ }
        if( Test-Path $Path -PathType Container )
        {
            $inheritanceFlags = ConvertTo-CInheritanceFlag -ContainerInheritanceFlag $ApplyTo
            $propagationFlags = ConvertTo-CPropagationFlag -ContainerInheritanceFlag $ApplyTo
            $testPermissionParams.ApplyTo = $ApplyTo
        }
        else
        {
            if( $PSBoundParameters.ContainsKey( 'ApplyTo' ) )
            {
                Write-Warning "Can't apply inheritance/propagation rules to a leaf. Please omit `ApplyTo` parameter when `Path` is a leaf."
            }
        }
    
        $rulesToRemove = $null
        $Identity = Resolve-CIdentity -Name $Identity
        if( $Clear )
        {
            $rulesToRemove = $currentAcl.Access |
                                Where-Object { $_.IdentityReference.Value -ne $Identity } |
                                Where-Object { -not $_.IsInherited }
        
            if( $rulesToRemove )
            {
                foreach( $ruleToRemove in $rulesToRemove )
                {
                    Write-Verbose ('[{0}] [{1}]  {2} -> ' -f $Path,$Identity,$ruleToRemove."$($providerName)Rights")
                    [void]$currentAcl.RemoveAccessRule( $ruleToRemove )
                }
            }
        }

        $accessRule = New-Object "Security.AccessControl.$($providerName)AccessRule" $Identity,$rights,$inheritanceFlags,$propagationFlags,$Type |
                        Add-Member -MemberType NoteProperty -Name 'Path' -Value $Path -PassThru

        $missingPermission = -not (Test-CPermission -Path $Path -Identity $Identity -Permission $Permission @testPermissionParams -Exact)

        $setAccessRule = ($Force -or $missingPermission)
        if( $setAccessRule )
        {
            if( $Append )
            {
                $currentAcl.AddAccessRule( $accessRule )
            }
            else
            {
                $currentAcl.SetAccessRule( $accessRule )
            }
        }

        if( $rulesToRemove -or $setAccessRule )
        {
            $currentPerm = Get-CPermission -Path $Path -Identity $Identity
            if( $currentPerm )
            {
                $currentPerm = $currentPerm."$($providerName)Rights"
            }
            if( $Append )
            {
                Write-Verbose -Message ('[{0}] [{1}]  + {2}' -f $Path,$accessRule.IdentityReference,$accessRule."$($providerName)Rights")
            }
            else
            {
                Write-Verbose -Message ('[{0}] [{1}]  {2} -> {3}' -f $Path,$accessRule.IdentityReference,$currentPerm,$accessRule."$($providerName)Rights")
            }
            Set-Acl -Path $Path -AclObject $currentAcl
        }

        if( $PassThru )
        {
            return $accessRule
        }
    }
}

Set-Alias -Name 'Grant-Permissions' -Value 'Grant-CPermission'

