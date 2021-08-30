

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$False,Position=0)]
        [ValidateSet("MD5","SHA1","SHA256","SHA384","SHA512","RIPEMD160")]
        [string]$HashType = "SHA256",
    [Parameter(Mandatory=$False,Position=1)]
        [String]$BasePaths,
    [Parameter(Mandatory=$False,Position=2)]
        [String]$extRegex="\.(exe|sys|dll|ps1|psd1|psm1|vbs|bat|cmd)$",
    [Parameter(Mandatory=$False,Position=3)]
        [int]$MinB=4096,
    [Parameter(Mandatory=$False,Position=4)]
        [int]$MaxB=10485760
) 

$ErrorActionPreference = "Continue"

function Get-LocalDrives
{
    
    Get-WmiObject win32_logicaldisk -Filter "DriveType=3" | Select-Object -ExpandProperty DeviceID | ForEach-Object {
        $disk = $_
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
			[ValidateSet("MD5","SHA1","SHA256","SHA384","SHA512","RIPEMD160")]
			[string]$HashType = "SHA256",
		[Parameter(Mandatory=$False,Position=2)]
			[int]$MinB=4096,
		[Parameter(Mandatory=$False,Position=3)]
			[int]$MaxB=10485760,
		[Parameter(Mandatory=$False,Position=4)]
			[string]$extRegex="\.(exe|sys|dll|ps1|psd1|psm1|vbs|bat|cmd|jpg|aspx|asp|class|java|war|tmp)$"
	)

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	$hashList = @()
	
	$Files = (
		Get-ChildItem -Force -Path $basePath -Recurse -ErrorAction SilentlyContinue | 
		? -FilterScript { 
			($_.Length -ge $MinB -and $_.Length -le $_.Length) -and 
			($_.Extension -match $extRegex) 
		} 
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

				
				Write-Debug -Message "Calculating hash of ${using:File.FullName}."
				if (Test-Path -LiteralPath $using:File.Fullname -PathType Leaf) {
					$FileData = [System.IO.File]::ReadAllBytes($using:File.FullName)
					$HashBytes = $hash.ComputeHash($FileData)
					$paddedHex = ""

                    $HashBytes | ForEach-Object {
                        $byte = $_
						$byteInHex = [String]::Format("{0:X}", $byte)
						$paddedHex += $byteInHex.PadLeft(2,"0")
					}
                
					Write-Debug -Message "Hash value was $paddedHex."
                    $($paddedHex + ":-:" + $using:File.FullName + ":-:" + $using:File.Length + ":-:" + $using:File.LastWriteTime)
				}
			}
            if ($entry) {
			    $workflow:hashList += ,$entry
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
			[ValidateSet("MD5","SHA1","SHA256","SHA384","SHA512","RIPEMD160")]
			[string]$HashType = "SHA256",
		[Parameter(Mandatory=$False,Position=2)]
			[int]$MinB=4096,
		[Parameter(Mandatory=$False,Position=3)]
			[int]$MaxB=10485760,
		[Parameter(Mandatory=$False,Position=4)]
			[string]$extRegex="\.(exe|sys|dll|ps1|psd1|psm1|vbs|bat|cmd)$"
	)

	
	

	$hashList = @()
	
	$Files = (
		Get-ChildItem -Force -Path $basePath -Recurse -ErrorAction SilentlyContinue | 
		? -FilterScript { 
			($_.Length -ge $MinB -and $_.Length -le $_.Length) -and 
			($_.Extension -match $extRegex) 
		} 
	)
	
	switch -CaseSensitive ($HashType) {
		"MD5"       { $hash = [System.Security.Cryptography.MD5]::Create() }
		"SHA1"      { $hash = [System.Security.Cryptography.SHA1]::Create() }
		"SHA256"    { $hash = [System.Security.Cryptography.SHA256]::Create() }
		"SHA384"    { $hash = [System.Security.Cryptography.SHA384]::Create() }
		"SHA512"    { $hash = [System.Security.Cryptography.SHA512]::Create() }
		"RIPEMD160" { $hash = [System.Security.Cryptography.RIPEMD160]::Create() }
	}
	
    foreach ($file in $Files) {
       
		Write-Debug -Message "Calculating hash of ${File.FullName}."
		if (Test-Path -LiteralPath $File.FullName -PathType Leaf) {
			$FileData = [System.IO.File]::ReadAllBytes($File.FullName)
			$HashBytes = $hash.ComputeHash($FileData)
			$paddedHex = ""

            foreach ($byte in $HashBytes) {
				$byteInHex = [String]::Format("{0:X}", $byte)
				$paddedHex += $byteInHex.PadLeft(2,"0")
			}
               
			Write-Debug -Message "Hash value was $paddedHex."

            $hashList += $($paddedHex + ":-:" + $file.FullName + ":-:" + $file.Length + ":-:" + $file.LastWriteTime)
		}
	}

	return ,$hashList
}

function Get-Hash {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$True,Position=0)]
			[String]$BasePath,
		[Parameter(Mandatory=$True,Position=1)]
			[ValidateSet("MD5","SHA1","SHA256","SHA384","SHA512","RIPEMD160")]
			[string]$HashType = "SHA256",
		[Parameter(Mandatory=$False,Position=2)]
			[int]$MinB=4096,
		[Parameter(Mandatory=$False,Position=3)]
			[int]$MaxB=10485760,
		[Parameter(Mandatory=$False,Position=4)]
			[string]$extRegex="\.(exe|sys|dll|ps1|psd1|psm1|vbs|bat|cmd)$"
	)
	
	
	
	
	if ((Test-Path env:\PROCESSOR_ARCHITEW6432) -and ([Intptr]::Size -eq 4)) {
		$sysRegex = $env:SystemDrive.ToString() + "\\($|windows($|\\($|system32($|\\))))"
		if ($BasePath -match $sysRegex) {
			Write-Verbose  "Searching %windir%\System32 with a 32-bit process on a 64-bit host can return false negatives. See comments in Get-FilesByHash.ps1 module for details."
		}
	}

	$HashType = $HashType.ToUpper()

    if ($psversiontable.version.major -gt 2.0) {
    	try {
	    	$hashList = Get-HashesWorkflow -BasePath $BasePath -HashType $HashType -extRegex $extRegex -MinB $MinB -MaxB $MaxB
	    }
	    catch {
		    Write-Verbose -Message "Workflows not supported. Running in single-threaded mode."
		    $hashList = Get-Hashes -BasePath $BasePath -HashType $HashType -extRegex $extRegex -MinB $MinB -MaxB $MaxB
	    }
    } else {
        Write-Verbose -Message "Workflows not supported. Running in single-threaded mode."
		$hashList = Get-Hashes -BasePath $BasePath -HashType $HashType -extRegex $extRegex -MinB $MinB -MaxB $MaxB
    }

    $o = "" | Select-Object File, Hash, Length, LastWritetime
    if ($hashList) {
        $hashList | ForEach-Object {
            $hash,$file,$length,$lastWritetime = $_ -split ":-:"
            $o.File = $file
            $o.Hash = $hash
            $o.Length = $length
            $o.LastWriteTime = $lastWritetime
            $o
        }
    } else {
        $o.File = $null
        $o.Hash = $null
        $o.Length = $null
        $o.LastWriteTime = $null
        $o
    }
}

if ($BasePaths.Length -eq 0) {
    Write-Verbose "No path specified, enumerating local drives."
    $BasePaths = Get-LocalDrives
}


$BasePaths | ForEach-Object {
    $basePath = $_
    Write-Verbose "Getting file hashes for $basePath."
    Get-Hash -BasePath $BasePath -HashType $HashType -extRegex $extRegex -MinB $MinB -MaxB $MaxB
}
