
function Install-CCertificate
{
    
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='FromFileInWindowsStore')]
    [OutputType([Security.Cryptography.X509Certificates.X509Certificate2])]
    param(
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='FromFileInWindowsStore')]
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='FromFileInCustomStore')]
        [string]
        
        $Path,
        
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='FromCertificateInWindowsStore')]
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='FromCertificateInCustomStore')]
        [Security.Cryptography.X509Certificates.X509Certificate2]
        
        $Certificate,
        
        [Parameter(Mandatory=$true)]
        [Security.Cryptography.X509Certificates.StoreLocation]
        
        
        
        $StoreLocation,
        
        [Parameter(Mandatory=$true,ParameterSetName='FromFileInWindowsStore')]
        [Parameter(Mandatory=$true,ParameterSetName='FromCertificateInWindowsStore')]
        [Security.Cryptography.X509Certificates.StoreName]
        
        
        
        $StoreName,

        [Parameter(Mandatory=$true,ParameterSetName='FromFileInCustomStore')]
        [Parameter(Mandatory=$true,ParameterSetName='FromCertificateInCustomStore')]
        [string]
        
        $CustomStoreName,

        [Parameter(ParameterSetName='FromFileInWindowsStore')]
        [Parameter(ParameterSetName='FromFileInCustomStore')]
        [Switch]
        
        $Exportable,
        
        [Parameter(ParameterSetName='FromFileInWindowsStore')]
        [Parameter(ParameterSetName='FromFileInCustomStore')]
        
        $Password,

        [Management.Automation.Runspaces.PSSession[]]
        
        
        
        $Session
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $Password -and $Password -isnot [securestring] )
    {
        Write-Warning -Message ('You passed a plain text password to `Install-CCertificate`. A future version of Carbon will remove support for plain-text passwords. Please pass a `SecureString` instead.')
        $Password = ConvertTo-SecureString -String $Password -AsPlainText -Force
    }
    
    if( $PSCmdlet.ParameterSetName -like 'FromFile*' )
    {   
        $resolvedPath = Resolve-Path -Path $Path        
        if( -not $resolvedPath )
        {
            return
        }

        $Path = $resolvedPath.ProviderPath
        
        $fileBytes = [IO.File]::ReadAllBytes($Path)
        $encodedCert = [Convert]::ToBase64String( $fileBytes )

        $keyFlags = [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::MachineKeySet
        if( $StoreLocation -eq [Security.Cryptography.X509Certificates.StoreLocation]::CurrentUser )
        {
            $keyFlags = [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::UserKeySet
        }
        $keyFlags = $keyFlags -bor [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet
    
        if( $Exportable )
        {
            $keyFlags = $keyFlags -bor [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable
        }

        $Certificate = Get-CCertificate -Path $Path -Password $Password -KeyStorageFlags $keyFlags
        $fromFile = $true
    }
    else
    {
        $encodedCert = [Convert]::ToBase64String( $Certificate.RawData )
        $keyFlags = 0
        $fromFile = $false
    }

    $invokeCommandArgs = @{ }
    if( $Session )
    {
        $invokeCommandArgs['Session'] = $Session
    }


    Invoke-Command @invokeCommandArgs -ScriptBlock {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$true)]
            [string]
            
            $EncodedCertificate,

            
            [securestring]
            $Password,

            [Parameter(Mandatory=$true)]
            [Security.Cryptography.X509Certificates.StoreLocation]
            $StoreLocation,
        
            $StoreName,

            [string]
            $CustomStoreName,

            [Security.Cryptography.X509Certificates.X509KeyStorageFlags]
            $KeyStorageFlags,

            [bool]
            $WhatIf,

            [Management.Automation.ActionPreference]
            $Verbosity
        )

        Set-StrictMode -Version 'Latest'

        $WhatIfPreference = $WhatIf
        $VerbosePreference = $Verbosity

        $tempDir = 'Carbon+Install-CCertificate+{0}' -f [IO.Path]::GetRandomFileName()
        $tempDir = Join-Path -Path $env:TEMP -ChildPath $tempDir
        New-Item -Path $tempDir -ItemType 'Directory' -WhatIf:$false | Out-Null

        try
        {
            $certBytes = [Convert]::FromBase64String( $EncodedCertificate )
            $certFilePath = Join-Path -Path $tempDir -ChildPath ([IO.Path]::GetRandomFileName())
            [IO.File]::WriteAllBytes( $certFilePath, $certBytes )

            $cert = New-Object 'Security.Cryptography.X509Certificates.X509Certificate2'
            $cert.Import( $certFilePath, $Password, $KeyStorageFlags )

            if( $CustomStoreName )
            {
                $store = New-Object 'Security.Cryptography.X509Certificates.X509Store' $CustomStoreName,$StoreLocation
            }
            else
            {
                $store = New-Object 'Security.Cryptography.X509Certificates.X509Store'  ([Security.Cryptography.X509Certificates.StoreName]$StoreName),$StoreLocation
            }

            $store.Open( ([Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite) )

            $description = $cert.FriendlyName
            if( -not $description )
            {
                $description = $cert.Subject
            }

            if( $PSCmdlet.ShouldProcess( ('install into {0}''s {1} store' -f $StoreLocation,$StoreName), ('{0} ({1})' -f $description,$cert.Thumbprint) ) )
            {
                Write-Verbose ('Installing certificate ''{0}'' ({1}) into {2}''s {3} store.' -f $description,$cert.Thumbprint,$StoreLocation,$StoreName)
                $store.Add( $cert )
            }
            $store.Close()
        }
        finally
        {
            Remove-Item -Path $tempDir -Recurse -ErrorAction Ignore -WhatIf:$false -Force
        }

    } -ArgumentList $encodedCert,$Password,$StoreLocation,$StoreName,$CustomStoreName,$keyFlags,$WhatIfPreference,$VerbosePreference

    return $Certificate
}

