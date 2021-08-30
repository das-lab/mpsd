function Out-EncryptedScript
{


    [CmdletBinding()] Param (
        [Parameter(Position = 0, Mandatory = $True)]
        [String]
        $ScriptPath,
    
        [Parameter(Position = 1, Mandatory = $True)]
        [String]
        $Password,
    
        [Parameter(Position = 2, Mandatory = $True)]
        [String]
        $Salt,
    
        [Parameter(Position = 3)]
        [ValidateLength(16, 16)]
        [String]
        $InitializationVector = ((1..16 | % {[Char](Get-Random -Min 0x41 -Max 0x5B)}) -join ''),
    
        [Parameter(Position = 4)]
        [String]
        $FilePath = '.\evil.ps1'
    )

    $AsciiEncoder = New-Object System.Text.ASCIIEncoding
    $ivBytes = $AsciiEncoder.GetBytes($InitializationVector)
    
    [Byte[]] $scriptBytes = Get-Content -Encoding Byte -ReadCount 0 -Path $ScriptPath
    $DerivedPass = New-Object System.Security.Cryptography.PasswordDeriveBytes($Password, $AsciiEncoder.GetBytes($Salt), "SHA1", 2)
    $Key = New-Object System.Security.Cryptography.TripleDESCryptoServiceProvider
    $Key.Mode = [System.Security.Cryptography.CipherMode]::CBC
    [Byte[]] $KeyBytes = $DerivedPass.GetBytes(16)
    $Encryptor = $Key.CreateEncryptor($KeyBytes, $ivBytes)
    $MemStream = New-Object System.IO.MemoryStream
    $CryptoStream = New-Object System.Security.Cryptography.CryptoStream($MemStream, $Encryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)
    $CryptoStream.Write($scriptBytes, 0, $scriptBytes.Length)
    $CryptoStream.FlushFinalBlock()
    $CipherTextBytes = $MemStream.ToArray()
    $MemStream.Close()
    $CryptoStream.Close()
    $Key.Clear()
    $Cipher = [Convert]::ToBase64String($CipherTextBytes)


$Output = @"
function de([String] `$b, [String] `$c)
{
`$a = "$Cipher";
`$encoding = New-Object System.Text.ASCIIEncoding;
`$dd = `$encoding.GetBytes("$InitializationVector");
`$aa = [Convert]::FromBase64String(`$a);
`$derivedPass = New-Object System.Security.Cryptography.PasswordDeriveBytes(`$b, `$encoding.GetBytes(`$c), "SHA1", 2);
[Byte[]] `$e = `$derivedPass.GetBytes(16);
`$f = New-Object System.Security.Cryptography.TripleDESCryptoServiceProvider;
`$f.Mode = [System.Security.Cryptography.CipherMode]::CBC;
[Byte[]] `$h = New-Object Byte[](`$aa.Length);
`$g = `$f.CreateDecryptor(`$e, `$dd);
`$i = New-Object System.IO.MemoryStream(`$aa, `$True);
`$j = New-Object System.Security.Cryptography.CryptoStream(`$i, `$g, [System.Security.Cryptography.CryptoStreamMode]::Read);
`$r = `$j.Read(`$h, 0, `$h.Length);
`$i.Close();
`$j.Close();
`$f.Clear();
if ((`$h.Length -gt 3) -and (`$h[0] -eq 0xEF) -and (`$h[1] -eq 0xBB) -and (`$h[2] -eq 0xBF)) { `$h = `$h[3..(`$h.Length-1)]; }
return `$encoding.GetString(`$h).TrimEnd([Char] 0);
}
"@

    
    Out-File -InputObject $Output -Encoding ASCII $FilePath

    Write-Verbose "Encrypted PS1 file saved to: $(Resolve-Path $FilePath)"
}
