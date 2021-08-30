function Copy-FileWithHashCheck {
	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $True)]
		[Alias('Fullname')]
		[string]$SourceFilePath,
		[Parameter(Mandatory = $true)]
		[ValidateScript({ Test-Path -Path $_ -PathType Container })]
		[string]$DestinationFolderPath,
		[Parameter()]
		[switch]$Force
	)
	begin {
		function Test-HashEqual ($FilePath1, $FilePath2) {
			$SourceHash = Get-MyFileHash -Path $FilePath1
			$DestHash = Get-MyFileHash -Path $FilePath2
			if ($SourceHash.SHA256 -ne $DestHash.SHA256) {
				$false
			} else {
				$true
			}
		}
		
		function Get-MyFileHash {
    	
			[CmdletBinding()]
			Param (
				[Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $True)]
				[Alias("PSPath", "FullName")]
				[string[]]$Path,
				
				[Parameter(Position = 1)]
				[ValidateSet("MD5", "SHA1", "SHA256", "SHA384", "SHA512", "RIPEMD160")]
				[string[]]$Algorithm = "SHA256"
			)
			Process {
				ForEach ($item in $Path) {
					try {
						$item = (Resolve-Path $item).ProviderPath
						If (-Not ([uri]$item).IsAbsoluteUri) {
							Write-Verbose ("{0} is not a full path, using current directory: {1}" -f $item, $pwd)
							$item = (Join-Path $pwd ($item -replace "\.\\", ""))
						}
						If (Test-Path $item -Type Container) {
							Write-Warning ("Cannot calculate hash for directory: {0}" -f $item)
							Return
						}
						$object = New-Object PSObject -Property @{
							Path = $item
						}
						
						$stream = ([IO.StreamReader]$item).BaseStream
						foreach ($Type in $Algorithm) {
							[string]$hash = -join ([Security.Cryptography.HashAlgorithm]::Create($Type).ComputeHash($stream) |
							ForEach { "{0:x2}" -f $_ })
							$null = $stream.Seek(0, 0)
							
							$object = Add-Member -InputObject $Object -MemberType NoteProperty -Name $Type -Value $Hash -PassThru
						}
						$object.pstypenames.insert(0, 'System.IO.FileInfo.Hash')
						
						Write-Output $object
						
						
						$stream.Close()
					} catch {
						Write-Log -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel '3'
						$false
					}
				}
			}
		}
	}
	process {
		try {
			$CopyParams = @{ 'Path' = $SourceFilePath; 'Destination' = $DestinationFolderPath }
			
			
			$DestFilePath = "$DestinationFolderPath\$($SourceFilePath | Split-Path -Leaf)"
			if (Test-Path -Path $DestFilePath -PathType 'Leaf') {
				if (Test-HashEqual -FilePath1 $SourceFilePath -FilePath2 $DestFilePath) {
					Write-Verbose -Message "The file $SourceFilePath is already in $DestinationFolderPath and is the same. No need to copy"
					return $true
				} elseif (!$Force.IsPresent) {
					throw "A file called $SourceFilePath is already in $DestinationFolderPath but is not the same file being copied."
				} else {
					$CopyParams.Force = $true
				}
			}
			
			Write-Verbose "Copying file $SourceFilePath..."
			Copy-Item @CopyParams
			if (Test-HashEqual -FilePath1 $SourceFilePath -FilePath2 $DestFilePath) {
				Write-Verbose -Message "The file $SourceFilePath was successfully copied to $DestinationFolderPath"
				return $true
			} else {
				throw "Attempted to copy the file $SourceFilePath to $DestinationFolderPath but failed the hash check"
			}
			
		} catch {
			Write-Error -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
			$false
		}
	}
}