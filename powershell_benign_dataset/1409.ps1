
filter Unprotect-CString
{
    
    [CmdletBinding(DefaultParameterSetName='DPAPI')]
    param(
        [Parameter(Mandatory = $true, Position=0, ValueFromPipeline = $true)]
        [string]
        
        $ProtectedString,

        [Parameter(Mandatory=$true,ParameterSetName='RSAByCertificate')]
        [Security.Cryptography.X509Certificates.X509Certificate2]
        
        $Certificate,

        [Parameter(Mandatory=$true,ParameterSetName='RSAByThumbprint')]
        [string]
        
        $Thumbprint,

        [Parameter(Mandatory=$true,ParameterSetName='RSAByPath')]
        [string]
        
        $PrivateKeyPath,

        [Parameter(ParameterSetName='RSAByPath')]
        
        $Password,

        [Parameter(ParameterSetName='RSAByCertificate')]
        [Parameter(ParameterSetName='RSAByThumbprint')]
        [Parameter(ParameterSetName='RSAByPath')]
        [Switch]
        
        $UseDirectEncryptionPadding,

        [Parameter(Mandatory=$true,ParameterSetName='Symmetric')]
        [object]
        
        $Key,

        [Switch]
        
        $AsSecureString
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    Add-Type -AssemblyName 'System.Security'
    
    [byte[]]$encryptedBytes = [Convert]::FromBase64String($ProtectedString)
    if( $PSCmdlet.ParameterSetName -eq 'DPAPI' )
    {
        $decryptedBytes = [Security.Cryptography.ProtectedData]::Unprotect( $encryptedBytes, $null, 0 )
    }
    elseif( $PSCmdlet.ParameterSetName -like 'RSA*' )
    {
        if( $PSCmdlet.ParameterSetName -like '*ByPath' )
        {
            $passwordParam = @{ }
            if( $Password )
            {
                $passwordParam = @{ Password = $Password }
            }
            $Certificate = Get-CCertificate -Path $PrivateKeyPath @passwordParam
            if( -not $Certificate )
            {
                return
            }
        }
        elseif( $PSCmdlet.ParameterSetName -like '*ByThumbprint' )
        {
            $certificates = Get-ChildItem -Path ('cert:\*\*\{0}' -f $Thumbprint) -Recurse 
            if( -not $certificates )
            {
                Write-Error ('Certificate ''{0}'' not found.' -f $Thumbprint)
                return
            }

            $Certificate = $certificates | Where-Object { $_.HasPrivateKey } | Select-Object -First 1
            if( -not $Certificate )
            {
                Write-Error ('Certificate ''{0}'' ({1}) doesn''t have a private key.' -f $certificates[0].Subject, $Thumbprint)
                return
            }
        }

        if( -not $Certificate.HasPrivateKey )
        {
            Write-Error ('Certificate ''{0}'' ({1}) doesn''t have a private key. When decrypting with RSA, secrets are encrypted with the public key, and decrypted with a private key.' -f $Certificate.Subject,$Certificate.Thumbprint)
            return
        }

        if( -not $Certificate.PrivateKey )
        {
            Write-Error ('Certificate ''{0}'' ({1}) has a private key, but it is currently null or not set. This usually means your certificate was imported or generated incorrectly. Make sure you''ve generated an RSA public/private key pair and are using the private key. If the private key is in the Windows certificate stores, make sure it was imported correctly (`Get-ChildItem $pathToCert | Select-Object -Expand PrivateKey` isn''t null).' -f $Certificate.Subject,$Certificate.Thumbprint)
            return
        }

        [Security.Cryptography.RSACryptoServiceProvider]$privateKey = $null
        if( $Certificate.PrivateKey -isnot [Security.Cryptography.RSACryptoServiceProvider] )
        {
            Write-Error ('Certificate ''{0}'' (''{1}'') is not an RSA key. Found a private key of type ''{2}'', but expected type ''{3}''.' -f $Certificate.Subject,$Certificate.Thumbprint,$Certificate.PrivateKey.GetType().FullName,[Security.Cryptography.RSACryptoServiceProvider].FullName)
            return
        }

        try
        {
            $privateKey = $Certificate.PrivateKey
            $decryptedBytes = $privateKey.Decrypt( $encryptedBytes, (-not $UseDirectEncryptionPadding) )
        }
        catch
        {
            if( $_.Exception.Message -match 'Error occurred while decoding OAEP padding' )
            {
                [int]$maxLengthGuess = ($privateKey.KeySize - (2 * 160 - 2)) / 8
                Write-Error (@'
Failed to decrypt string using certificate '{0}' ({1}). This can happen when:
 * The string to decrypt is too long because the original string you encrypted was at or near the maximum allowed by your key's size, which is {2} bits. We estimate the maximum string size you can encrypt is {3} bytes. You may get this error even if the original encrypted string is within a couple bytes of that maximum.
 * The string was encrypted with a different key
 * The string isn't encrypted

{4}: {5}
'@ -f $Certificate.Subject, $Certificate.Thumbprint,$privateKey.KeySize,$maxLengthGuess,$_.Exception.GetType().FullName,$_.Exception.Message)
                return
            }
            elseif( $_.Exception.Message -match '(Bad Data|The parameter is incorrect)\.' )
            {
                Write-Error (@'
Failed to decrypt string using certificate '{0}' ({1}). This usually happens when the padding algorithm used when encrypting/decrypting is different. Check the `-UseDirectEncryptionPadding` switch is the same for both calls to `Protect-CString` and `Unprotect-CString`.

{2}: {3}
'@ -f $Certificate.Subject,$Certificate.Thumbprint,$_.Exception.GetType().FullName,$_.Exception.Message)
                return
            }
            Write-Error -Exception $_.Exception
            return
        }
    }
    elseif( $PSCmdlet.ParameterSetName -eq 'Symmetric' )
    {
        $Key = ConvertTo-Key -InputObject $Key -From 'Unprotect-CString'
        if( -not $Key )
        {
            return
        }
                
        $aes = New-Object 'Security.Cryptography.AesCryptoServiceProvider'
        try
        {
            $aes.Padding = [Security.Cryptography.PaddingMode]::PKCS7
            $aes.KeySize = $Key.Length * 8
            $aes.Key = $Key
            $iv = New-Object 'Byte[]' $aes.IV.Length
            [Array]::Copy($encryptedBytes,$iv,16)

            $encryptedBytes = $encryptedBytes[16..($encryptedBytes.Length - 1)]
            $encryptedStream = New-Object 'IO.MemoryStream' (,$encryptedBytes)
            try
            {
                $decryptor = $aes.CreateDecryptor($aes.Key, $iv)
                try
                {
                    $cryptoStream = New-Object 'Security.Cryptography.CryptoStream' $encryptedStream,$decryptor,([Security.Cryptography.CryptoStreamMode]::Read)
                    try
                    {
                        $decryptedBytes = New-Object 'byte[]' ($encryptedBytes.Length)
                        [void]$cryptoStream.Read($decryptedBytes, 0, $decryptedBytes.Length)
                    }
                    finally
                    {
                        $cryptoStream.Dispose()
                    }
                }
                finally
                {
                    $decryptor.Dispose()
                }

            }
            finally
            {
                $encryptedStream.Dispose()
            }
        }
        finally
        {
            $aes.Dispose()
        }
    }

    try
    {
        if( $AsSecureString )
        {
            $secureString = New-Object 'Security.SecureString'
            [char[]]$chars = [Text.Encoding]::UTF8.GetChars( $decryptedBytes )
            for( $idx = 0; $idx -lt $chars.Count ; $idx++ )
            {
                $secureString.AppendChar( $chars[$idx] )
                $chars[$idx] = 0
            }

            $secureString.MakeReadOnly()
            return $secureString
        }
        else
        {
            [Text.Encoding]::UTF8.GetString( $decryptedBytes )
        }
    }
    finally
    {
        [Array]::Clear( $decryptedBytes, 0, $decryptedBytes.Length )
    }
}

