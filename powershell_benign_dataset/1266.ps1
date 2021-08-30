
filter Protect-CString
{
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position=0, ValueFromPipeline = $true)]
        [object]
        
        
        
        $String,
        
        [Parameter(Mandatory=$true,ParameterSetName='DPAPICurrentUser')]
        
        [Switch]
        $ForUser,
        
        [Parameter(Mandatory=$true,ParameterSetName='DPAPILocalMachine')]
        
        [Switch]
        $ForComputer,

        [Parameter(Mandatory=$true,ParameterSetName='DPAPIForUser')]
        [Management.Automation.PSCredential]
        
        $Credential,

        [Parameter(Mandatory=$true,ParameterSetName='RSAByCertificate')]
        [Security.Cryptography.X509Certificates.X509Certificate2]
        
        $Certificate,

        [Parameter(Mandatory=$true,ParameterSetName='RSAByThumbprint')]
        [string]
        
        $Thumbprint,

        [Parameter(Mandatory=$true,ParameterSetName='RSAByPath')]
        [string]
        
        $PublicKeyPath,

        [Parameter(ParameterSetName='RSAByCertificate')]
        [Parameter(ParameterSetName='RSAByThumbprint')]
        [Parameter(ParameterSetName='RSAByPath')]
        [Switch]
        
        $UseDirectEncryptionPadding,

        [Parameter(Mandatory=$true,ParameterSetName='Symmetric')]
        
        [object]
        $Key
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Add-Type -AssemblyName 'System.Security'

    if( $String -is [System.Security.SecureString] )
    {
        $stringBytes = [Carbon.Security.SecureStringConverter]::ToBytes($String)   
    }
    else
    {
        $stringBytes = [Text.Encoding]::UTF8.GetBytes( $String.ToString() )
    }
    
    try
    {    

        if( $PSCmdlet.ParameterSetName -like 'DPAPI*' )
        {
            if( $PSCmdlet.ParameterSetName -eq 'DPAPIForUser' ) 
            {
                $protectStringPath = Join-Path -Path $CarbonBinDir -ChildPath 'Protect-String.ps1' -Resolve
                $encodedString = Protect-CString -String $String -ForComputer
                $argumentList = '-ProtectedString {0}' -f $encodedString
                Invoke-CPowerShell -ExecutionPolicy 'ByPass' -NonInteractive -FilePath $protectStringPath -ArgumentList $argumentList -Credential $Credential |
                    Select-Object -First 1
                return
            }
            else
            {
                $scope = [Security.Cryptography.DataProtectionScope]::CurrentUser
                if( $PSCmdlet.ParameterSetName -eq 'DPAPILocalMachine' )
                {
                    $scope = [Security.Cryptography.DataProtectionScope]::LocalMachine
                }

                $encryptedBytes = [Security.Cryptography.ProtectedData]::Protect( $stringBytes, $null, $scope )
            }
        }
        elseif( $PSCmdlet.ParameterSetName -like 'RSA*' )
        {
            if( $PSCmdlet.ParameterSetName -eq 'RSAByThumbprint' )
            {
                $Certificate = Get-ChildItem -Path ('cert:\*\*\{0}' -f $Thumbprint) -Recurse | Select-Object -First 1
                if( -not $Certificate )
                {
                    Write-Error ('Certificate with thumbprint ''{0}'' not found.' -f $Thumbprint)
                    return
                }
            }
            elseif( $PSCmdlet.ParameterSetName -eq 'RSAByPath' )
            {
                $Certificate = Get-CCertificate -Path $PublicKeyPath
                if( -not $Certificate )
                {
                    return
                }
            }

            $rsaKey = $Certificate.PublicKey.Key
            if( $rsaKey -isnot ([Security.Cryptography.RSACryptoServiceProvider]) )
            {
                Write-Error ('Certificate ''{0}'' (''{1}'') is not an RSA key. Found a public key of type ''{2}'', but expected type ''{3}''.' -f $Certificate.Subject,$Certificate.Thumbprint,$rsaKey.GetType().FullName,[Security.Cryptography.RSACryptoServiceProvider].FullName)
                return
            }

            try
            {
                $encryptedBytes = $rsaKey.Encrypt( $stringBytes, (-not $UseDirectEncryptionPadding) )
            }
            catch
            {
                if( $_.Exception.Message -match 'Bad Length\.' -or $_.Exception.Message -match 'The parameter is incorrect\.')
                {
                    [int]$maxLengthGuess = ($rsaKey.KeySize - (2 * 160 - 2)) / 8
                    Write-Error -Message ('Failed to encrypt. String is longer than maximum length allowed by RSA and your key size, which is {0} bits. We estimate the maximum string size you can encrypt with certificate ''{1}'' ({2}) is {3} bytes. You may still get errors when you attempt to decrypt a string within a few bytes of this estimated maximum.' -f $rsaKey.KeySize,$Certificate.Subject,$Certificate.Thumbprint,$maxLengthGuess)
                    return
                }
                else
                {
                    Write-Error -Exception $_.Exception
                    return
                }
            }
        }
        elseif( $PSCmdlet.ParameterSetName -eq 'Symmetric' )
        {
            $Key = ConvertTo-Key -InputObject $Key -From 'Protect-CString'
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

                $memoryStream = New-Object 'IO.MemoryStream'
                try
                {
                    $cryptoStream = New-Object 'Security.Cryptography.CryptoStream' $memoryStream,$aes.CreateEncryptor(),([Security.Cryptography.CryptoStreamMode]::Write)
                    try
                    {
                        $cryptoStream.Write($stringBytes,0,$stringBytes.Length)
                    }
                    finally
                    {
                        $cryptoStream.Dispose()
                    }

                    $encryptedBytes = Invoke-Command -ScriptBlock {
                                                                     $aes.IV
                                                                     $memoryStream.ToArray()
                                                                  }
                }
                finally
                {
                    $memoryStream.Dispose()
                }
            }
            finally
            {
                $aes.Dispose()
            }
        }

        return [Convert]::ToBase64String( $encryptedBytes )
    }
    finally
    {
        $stringBytes.Clear()
    }
}

