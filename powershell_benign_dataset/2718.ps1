

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