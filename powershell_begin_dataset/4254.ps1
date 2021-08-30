$psver = $PSVersionTable.psversion.Major
if ($psver -eq '2') {
    Write-Output "Powershell version 3 required"
}
function New-ZipFile {
	
	
	[CmdletBinding()]
	param(
		
		[Parameter(Position=0, Mandatory=$true)]
		$ZipFilePath,
 
		
		[Parameter(Position=1, Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
		[Alias("PSPath","Item")]
		[string[]]$InputObject = $Pwd,
 
		
		[Switch]$Append,
 
		
		
		
		
		[System.IO.Compression.CompressionLevel]$Compression = "Optimal"
	)
	begin {
		Add-Type -As System.IO.Compression.FileSystem
		
		[string]$File = Split-Path $ZipFilePath -Leaf
		[string]$Folder = $(if($Folder = Split-Path $ZipFilePath) { Resolve-Path $Folder } else { $Pwd })
		$ZipFilePath = Join-Path $Folder $File
		
		if(!$Append) {
			if(Test-Path $ZipFilePath) { Remove-Item $ZipFilePath }
		}
		$Archive = [System.IO.Compression.ZipFile]::Open( $ZipFilePath, "Update" )
	}
	process {
		foreach($path in $InputObject) {
			foreach($item in Resolve-Path $path) {
				
				Push-Location (Split-Path $item)
				
				foreach($file in Get-ChildItem $item -Recurse -File -Force | % FullName) {
					
					$relative = (Resolve-Path $file -Relative).TrimStart(".\")
					
					$null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($Archive, $file, $relative, $Compression)
				}
				Pop-Location
			}
		}
	}
	end {
		$Archive.Dispose()
		Get-Item $ZipFilePath
	}
}
     
     
function Expand-ZipFile {
	
	
	[CmdletBinding()]
	param(
		
		[Parameter(ValueFromPipelineByPropertyName=$true, Position=0, Mandatory=$true)]
		[Alias("PSPath")]
		$FilePath,
 
		
		[Parameter(Position=1)]
		$OutputPath = $Pwd,
 
		
		[Switch]$Force
	)
	process {
		$ZipFile = Get-Item $FilePath
		$Archive = [System.IO.Compression.ZipFile]::Open( $ZipFile, "Read" )
 
		
		if(Test-Path $OutputPath) {
			
			$Destination = Join-Path $OutputPath $ZipFile.BaseName
		} else {
			
			$Destination = $OutputPath
		}
 
		
		$ArchiveRoot = ($Archive.Entries[0].FullName -Split "/|\\")[0]
 
		Write-Verbose "Desired Destination: $Destination"
		Write-Verbose "Archive Root: $ArchiveRoot"
 
		
		if($Archive.Entries.FullName | Where-Object { @($_ -Split "/|\\")[0] -ne $ArchiveRoot }) {
			
			New-Item $Destination -Type Directory -Force
			[System.IO.Compression.ZipFileExtensions]::ExtractToDirectory( $Archive, $Destination )
		} else {
			
			[System.IO.Compression.ZipFileExtensions]::ExtractToDirectory( $Archive, $OutputPath )
 
			
			if($Archive.Entries.Count -eq 1) {
				
				if([System.IO.Path]::GetExtension($Destination)) {
					Move-Item (Join-Path $OutputPath $Archive.Entries[0].FullName) $Destination
				} else {
					Get-Item (Join-Path $OutputPath $Archive.Entries[0].FullName)
				}
			} elseif($Force) {
				
				if($ArchiveRoot -ne $ZipFile.BaseName) {
					Move-Item (join-path $OutputPath $ArchiveRoot) $Destination
					Get-Item $Destination
				}
			} else {
				Get-Item (Join-Path $OutputPath $ArchiveRoot)
			}
		}
 
		$Archive.Dispose()
	}
}


new-alias zip new-zipfile
new-alias unzip expand-zipfile
