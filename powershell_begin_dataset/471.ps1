
[CmdletBinding()]
Param (
	[string]
	$Branch = "master",
	
	[switch]
	$UserMode,
	
	[ValidateSet('AllUsers', 'CurrentUser')]
	[string]
	$Scope = "AllUsers",
	
	[switch]
	$Force
)



$ModuleName = "PSFramework"


$BaseUrl = "https://github.com/PowershellFrameworkCollective/psframework"


$SubFolder = "PSFramework"



$doUserMode = $false
if ($UserMode) { $doUserMode = $true }
if ($install_CurrentUser) { $doUserMode = $true }
if ($Scope -eq 'CurrentUser') { $doUserMode = $true }

if ($install_Branch) { $Branch = $install_Branch }



function Compress-Archive
{
	
	[CmdletBinding(DefaultParameterSetName = "Path", SupportsShouldProcess = $true, HelpUri = "http://go.microsoft.com/fwlink/?LinkID=393252")]
	param
	(
		[parameter (mandatory = $true, Position = 0, ParameterSetName = "Path", ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[parameter (mandatory = $true, Position = 0, ParameterSetName = "PathWithForce", ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[parameter (mandatory = $true, Position = 0, ParameterSetName = "PathWithUpdate", ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[ValidateNotNullOrEmpty()]
		[string[]]
		$Path,

		[parameter (mandatory = $true, ParameterSetName = "LiteralPath", ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true)]
		[parameter (mandatory = $true, ParameterSetName = "LiteralPathWithForce", ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true)]
		[parameter (mandatory = $true, ParameterSetName = "LiteralPathWithUpdate", ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias("PSPath")]
		[string[]]
		$LiteralPath,

		[parameter (mandatory = $true,
					Position = 1,
					ValueFromPipeline = $false,
					ValueFromPipelineByPropertyName = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$DestinationPath,

		[parameter (
					mandatory = $false,
					ValueFromPipeline = $false,
					ValueFromPipelineByPropertyName = $false)]
		[ValidateSet("Optimal", "NoCompression", "Fastest")]
		[string]
		$CompressionLevel = "Optimal",

		[parameter(mandatory = $true, ParameterSetName = "PathWithUpdate", ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false)]
		[parameter(mandatory = $true, ParameterSetName = "LiteralPathWithUpdate", ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false)]
		[switch]
		$Update = $false,

		[parameter(mandatory = $true, ParameterSetName = "PathWithForce", ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false)]
		[parameter(mandatory = $true, ParameterSetName = "LiteralPathWithForce", ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false)]
		[switch]
		$Force = $false
	)

	BEGIN
	{
		Add-Type -AssemblyName System.IO.Compression -ErrorAction Ignore
		Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Ignore

		$zipFileExtension = ".zip"

		$LocalizedData = ConvertFrom-StringData @'
PathNotFoundError=The path '{0}' either does not exist or is not a valid file system path.
ExpandArchiveInValidDestinationPath=The path '{0}' is not a valid file system directory path.
InvalidZipFileExtensionError={0} is not a supported archive file format. {1} is the only supported archive file format.
ArchiveFileIsReadOnly=The attributes of the archive file {0} is set to 'ReadOnly' hence it cannot be updated. If you intend to update the existing archive file, remove the 'ReadOnly' attribute on the archive file else use -Force parameter to override and create a new archive file.
ZipFileExistError=The archive file {0} already exists. Use the -Update parameter to update the existing archive file or use the -Force parameter to overwrite the existing archive file.
DuplicatePathFoundError=The input to {0} parameter contains a duplicate path '{1}'. Provide a unique set of paths as input to {2} parameter.
ArchiveFileIsEmpty=The archive file {0} is empty.
CompressProgressBarText=The archive file '{0}' creation is in progress...
ExpandProgressBarText=The archive file '{0}' expansion is in progress...
AppendArchiveFileExtensionMessage=The archive file path '{0}' supplied to the DestinationPath patameter does not include .zip extension. Hence .zip is appended to the supplied DestinationPath path and the archive file would be created at '{1}'.
AddItemtoArchiveFile=Adding '{0}'.
CreateFileAtExpandedPath=Created '{0}'.
InvalidArchiveFilePathError=The archive file path '{0}' specified as input to the {1} parameter is resolving to multiple file system paths. Provide a unique path to the {2} parameter where the archive file has to be created.
InvalidExpandedDirPathError=The directory path '{0}' specified as input to the DestinationPath parameter is resolving to multiple file system paths. Provide a unique path to the Destination parameter where the archive file contents have to be expanded.
FileExistsError=Failed to create file '{0}' while expanding the archive file '{1}' contents as the file '{2}' already exists. Use the -Force parameter if you want to overwrite the existing directory '{3}' contents when expanding the archive file.
DeleteArchiveFile=The partially created archive file '{0}' is deleted as it is not usable.
InvalidDestinationPath=The destination path '{0}' does not contain a valid archive file name.
PreparingToCompressVerboseMessage=Preparing to compress...
PreparingToExpandVerboseMessage=Preparing to expand...
'@

		
		function GetResolvedPathHelper
		{
			param
			(
				[string[]]
				$path,

				[boolean]
				$isLiteralPath,

				[System.Management.Automation.PSCmdlet]
				$callerPSCmdlet
			)

			$resolvedPaths = @()

			
			foreach ($currentPath in $path)
			{
				try
				{
					if ($isLiteralPath)
					{
						$currentResolvedPaths = Resolve-Path -LiteralPath $currentPath -ErrorAction Stop
					}
					else
					{
						$currentResolvedPaths = Resolve-Path -Path $currentPath -ErrorAction Stop
					}
				}
				catch
				{
					$errorMessage = ($LocalizedData.PathNotFoundError -f $currentPath)
					$exception = New-Object System.InvalidOperationException $errorMessage, $_.Exception
					$errorRecord = CreateErrorRecordHelper "ArchiveCmdletPathNotFound" $null ([System.Management.Automation.ErrorCategory]::InvalidArgument) $exception $currentPath
					$callerPSCmdlet.ThrowTerminatingError($errorRecord)
				}

				foreach ($currentResolvedPath in $currentResolvedPaths)
				{
					$resolvedPaths += $currentResolvedPath.ProviderPath
				}
			}

			$resolvedPaths
		}

		function Add-CompressionAssemblies
		{

			if ($PSEdition -eq "Desktop")
			{
				Add-Type -AssemblyName System.IO.Compression
				Add-Type -AssemblyName System.IO.Compression.FileSystem
			}
		}

		function IsValidFileSystemPath
		{
			param
			(
				[string[]]
				$path
			)

			$result = $true;

			
			foreach ($currentPath in $path)
			{
				if (!([System.IO.File]::Exists($currentPath) -or [System.IO.Directory]::Exists($currentPath)))
				{
					$errorMessage = ($LocalizedData.PathNotFoundError -f $currentPath)
					ThrowTerminatingErrorHelper "PathNotFound" $errorMessage ([System.Management.Automation.ErrorCategory]::InvalidArgument) $currentPath
				}
			}

			return $result;
		}


		function ValidateDuplicateFileSystemPath
		{
			param
			(
				[string]
				$inputParameter,

				[string[]]
				$path
			)

			$uniqueInputPaths = @()

			
			foreach ($currentPath in $path)
			{
				$currentInputPath = $currentPath.ToUpper()
				if ($uniqueInputPaths.Contains($currentInputPath))
				{
					$errorMessage = ($LocalizedData.DuplicatePathFoundError -f $inputParameter, $currentPath, $inputParameter)
					ThrowTerminatingErrorHelper "DuplicatePathFound" $errorMessage ([System.Management.Automation.ErrorCategory]::InvalidArgument) $currentPath
				}
				else
				{
					$uniqueInputPaths += $currentInputPath
				}
			}
		}

		function CompressionLevelMapper
		{
			param
			(
				[string]
				$compressionLevel
			)

			$compressionLevelFormat = [System.IO.Compression.CompressionLevel]::Optimal

			
			switch ($compressionLevel.ToString())
			{
				"Fastest"
				{
					$compressionLevelFormat = [System.IO.Compression.CompressionLevel]::Fastest
				}
				"NoCompression"
				{
					$compressionLevelFormat = [System.IO.Compression.CompressionLevel]::NoCompression
				}
			}

			return $compressionLevelFormat
		}

		function CompressArchiveHelper
		{
			param
			(
				[string[]]
				$sourcePath,

				[string]
				$destinationPath,

				[string]
				$compressionLevel,

				[bool]
				$isUpdateMode
			)

			$numberOfItemsArchived = 0
			$sourceFilePaths = @()
			$sourceDirPaths = @()

			foreach ($currentPath in $sourcePath)
			{
				$result = Test-Path -LiteralPath $currentPath -PathType Leaf
				if ($result -eq $true)
				{
					$sourceFilePaths += $currentPath
				}
				else
				{
					$sourceDirPaths += $currentPath
				}
			}

			
			if ($sourceFilePaths.Count -eq 0 -and $sourceDirPaths.Count -gt 0)
			{
				$currentSegmentWeight = 100/[double]$sourceDirPaths.Count
				$previousSegmentWeight = 0
				foreach ($currentSourceDirPath in $sourceDirPaths)
				{
					$count = CompressSingleDirHelper $currentSourceDirPath $destinationPath $compressionLevel $true $isUpdateMode $previousSegmentWeight $currentSegmentWeight
					$numberOfItemsArchived += $count
					$previousSegmentWeight += $currentSegmentWeight
				}
			}

			
			elseIf ($sourceFilePaths.Count -gt 0 -and $sourceDirPaths.Count -eq 0)
			{
				
				
				$previousSegmentWeight = 0
				$currentSegmentWeight = 100

				$numberOfItemsArchived = CompressFilesHelper $sourceFilePaths $destinationPath $compressionLevel $isUpdateMode $previousSegmentWeight $currentSegmentWeight
			}
			
			elseif ($sourceFilePaths.Count -gt 0 -and $sourceDirPaths.Count -gt 0)
			{
				
				$currentSegmentWeight = 100/[double]($sourceDirPaths.Count + 1)
				$previousSegmentWeight = 0

				foreach ($currentSourceDirPath in $sourceDirPaths)
				{
					$count = CompressSingleDirHelper $currentSourceDirPath $destinationPath $compressionLevel $true $isUpdateMode $previousSegmentWeight $currentSegmentWeight
					$numberOfItemsArchived += $count
					$previousSegmentWeight += $currentSegmentWeight
				}

				$count = CompressFilesHelper $sourceFilePaths $destinationPath $compressionLevel $isUpdateMode $previousSegmentWeight $currentSegmentWeight
				$numberOfItemsArchived += $count
			}

			return $numberOfItemsArchived
		}

		function CompressFilesHelper
		{
			param
			(
				[string[]]
				$sourceFilePaths,

				[string]
				$destinationPath,

				[string]
				$compressionLevel,

				[bool]
				$isUpdateMode,

				[double]
				$previousSegmentWeight,

				[double]
				$currentSegmentWeight
			)

			$numberOfItemsArchived = ZipArchiveHelper $sourceFilePaths $destinationPath $compressionLevel $isUpdateMode $null $previousSegmentWeight $currentSegmentWeight

			return $numberOfItemsArchived
		}

		function CompressSingleDirHelper
		{
			param
			(
				[string]
				$sourceDirPath,

				[string]
				$destinationPath,

				[string]
				$compressionLevel,

				[bool]
				$useParentDirAsRoot,

				[bool]
				$isUpdateMode,

				[double]
				$previousSegmentWeight,

				[double]
				$currentSegmentWeight
			)

			[System.Collections.Generic.List[System.String]]$subDirFiles = @()

			if ($useParentDirAsRoot)
			{
				$sourceDirInfo = New-Object -TypeName System.IO.DirectoryInfo -ArgumentList $sourceDirPath
				$sourceDirFullName = $sourceDirInfo.Parent.FullName

				
				
				
				if ($sourceDirFullName.Length -eq 3)
				{
					$modifiedSourceDirFullName = $sourceDirFullName
				}
				else
				{
					$modifiedSourceDirFullName = $sourceDirFullName + "\"
				}
			}
			else
			{
				$sourceDirFullName = $sourceDirPath
				$modifiedSourceDirFullName = $sourceDirFullName + "\"
			}

			$dirContents = Get-ChildItem -LiteralPath $sourceDirPath -Recurse
			foreach ($currentContent in $dirContents)
			{
				$isContainer = $currentContent -is [System.IO.DirectoryInfo]
				if (!$isContainer)
				{
					$subDirFiles.Add($currentContent.FullName)
				}
				else
				{
					
					
					
					
					$files = $currentContent.GetFiles()
					if ($files.Count -eq 0)
					{
						$subDirFiles.Add($currentContent.FullName + "\")
					}
				}
			}

			$numberOfItemsArchived = ZipArchiveHelper $subDirFiles.ToArray() $destinationPath $compressionLevel $isUpdateMode $modifiedSourceDirFullName $previousSegmentWeight $currentSegmentWeight

			return $numberOfItemsArchived
		}

		function ZipArchiveHelper
		{
			param
			(
				[System.Collections.Generic.List[System.String]]
				$sourcePaths,

				[string]
				$destinationPath,

				[string]
				$compressionLevel,

				[bool]
				$isUpdateMode,

				[string]
				$modifiedSourceDirFullName,

				[double]
				$previousSegmentWeight,

				[double]
				$currentSegmentWeight
			)

			$numberOfItemsArchived = 0
			$fileMode = [System.IO.FileMode]::Create
			$result = Test-Path -LiteralPath $DestinationPath -PathType Leaf
			if ($result -eq $true)
			{
				$fileMode = [System.IO.FileMode]::Open
			}

			Add-CompressionAssemblies

			try
			{
				
				$archiveFileStreamArgs = @($destinationPath, $fileMode)
				$archiveFileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $archiveFileStreamArgs

				$zipArchiveArgs = @($archiveFileStream, [System.IO.Compression.ZipArchiveMode]::Update, $false)
				$zipArchive = New-Object -TypeName System.IO.Compression.ZipArchive -ArgumentList $zipArchiveArgs

				$currentEntryCount = 0
				$progressBarStatus = ($LocalizedData.CompressProgressBarText -f $destinationPath)
				$bufferSize = 4kb
				$buffer = New-Object Byte[] $bufferSize

				foreach ($currentFilePath in $sourcePaths)
				{
					if ($modifiedSourceDirFullName -ne $null -and $modifiedSourceDirFullName.Length -gt 0)
					{
						$index = $currentFilePath.IndexOf($modifiedSourceDirFullName, [System.StringComparison]::OrdinalIgnoreCase)
						$currentFilePathSubString = $currentFilePath.Substring($index, $modifiedSourceDirFullName.Length)
						$relativeFilePath = $currentFilePath.Replace($currentFilePathSubString, "").Trim()
					}
					else
					{
						$relativeFilePath = [System.IO.Path]::GetFileName($currentFilePath)
					}

					
					
					if ($isUpdateMode -eq $true -and $zipArchive.Entries.Count -gt 0)
					{
						$entryToBeUpdated = $null

						
						
						
						

						foreach ($currentArchiveEntry in $zipArchive.Entries)
						{
							if ($currentArchiveEntry.FullName -eq $relativeFilePath)
							{
								$entryToBeUpdated = $currentArchiveEntry
								break
							}
						}

						if ($entryToBeUpdated -ne $null)
						{
							$addItemtoArchiveFileMessage = ($LocalizedData.AddItemtoArchiveFile -f $currentFilePath)
							$entryToBeUpdated.Delete()
						}
					}

					$compression = CompressionLevelMapper $compressionLevel

					
					
					
					if (!$relativeFilePath.EndsWith("\", [StringComparison]::OrdinalIgnoreCase))
					{
						try
						{
							try
							{
								$currentFileStream = [System.IO.File]::Open($currentFilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
							}
							catch
							{
								
								
								$exception = $_.Exception
								if ($null -ne $_.Exception -and
									$null -ne $_.Exception.InnerException)
								{
									$exception = $_.Exception.InnerException
								}
								$errorRecord = CreateErrorRecordHelper "CompressArchiveUnauthorizedAccessError" $null ([System.Management.Automation.ErrorCategory]::PermissionDenied) $exception $currentFilePath
								Write-Error -ErrorRecord $errorRecord
							}

							if ($null -ne $currentFileStream)
							{
								$srcStream = New-Object System.IO.BinaryReader $currentFileStream

								$currentArchiveEntry = $zipArchive.CreateEntry($relativeFilePath, $compression)

								
								
								$currentArchiveEntry.LastWriteTime = (Get-Item -LiteralPath $currentFilePath).LastWriteTime

								$destStream = New-Object System.IO.BinaryWriter $currentArchiveEntry.Open()

								while ($numberOfBytesRead = $srcStream.Read($buffer, 0, $bufferSize))
								{
									$destStream.Write($buffer, 0, $numberOfBytesRead)
									$destStream.Flush()
								}

								$numberOfItemsArchived += 1
								$addItemtoArchiveFileMessage = ($LocalizedData.AddItemtoArchiveFile -f $currentFilePath)
							}
						}
						finally
						{
							If ($null -ne $currentFileStream)
							{
								$currentFileStream.Dispose()
							}
							If ($null -ne $srcStream)
							{
								$srcStream.Dispose()
							}
							If ($null -ne $destStream)
							{
								$destStream.Dispose()
							}
						}
					}
					else
					{
						$currentArchiveEntry = $zipArchive.CreateEntry("$relativeFilePath", $compression)
						$numberOfItemsArchived += 1
						$addItemtoArchiveFileMessage = ($LocalizedData.AddItemtoArchiveFile -f $currentFilePath)
					}

					if ($null -ne $addItemtoArchiveFileMessage)
					{
						Write-Verbose $addItemtoArchiveFileMessage
					}

					$currentEntryCount += 1
					ProgressBarHelper "Compress-Archive" $progressBarStatus $previousSegmentWeight $currentSegmentWeight $sourcePaths.Count  $currentEntryCount
				}
			}
			finally
			{
				If ($null -ne $zipArchive)
				{
					$zipArchive.Dispose()
				}

				If ($null -ne $archiveFileStream)
				{
					$archiveFileStream.Dispose()
				}

				
				Write-Progress -Activity "Compress-Archive" -Completed
			}

			return $numberOfItemsArchived
		}


		function ValidateArchivePathHelper
		{
			param
			(
				[string]
				$archiveFile
			)

			if ([System.IO.File]::Exists($archiveFile))
			{
				$extension = [system.IO.Path]::GetExtension($archiveFile)

				
				if ($extension -ne $zipFileExtension)
				{
					$errorMessage = ($LocalizedData.InvalidZipFileExtensionError -f $extension, $zipFileExtension)
					ThrowTerminatingErrorHelper "NotSupportedArchiveFileExtension" $errorMessage ([System.Management.Automation.ErrorCategory]::InvalidArgument) $extension
				}
			}
			else
			{
				$errorMessage = ($LocalizedData.PathNotFoundError -f $archiveFile)
				ThrowTerminatingErrorHelper "PathNotFound" $errorMessage ([System.Management.Automation.ErrorCategory]::InvalidArgument) $archiveFile
			}
		}


		function ExpandArchiveHelper
		{
			param
			(
				[string]
				$archiveFile,

				[string]
				$expandedDir,

				[ref]
				$expandedItems,

				[boolean]
				$force,

				[boolean]
				$isVerbose,

				[boolean]
				$isConfirm
			)

			Add-CompressionAssemblies

			try
			{
				
				
				$archiveFileStreamArgs = @($archiveFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
				$archiveFileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $archiveFileStreamArgs

				$zipArchiveArgs = @($archiveFileStream, [System.IO.Compression.ZipArchiveMode]::Read, $false)
				$zipArchive = New-Object -TypeName System.IO.Compression.ZipArchive -ArgumentList $zipArchiveArgs

				if ($zipArchive.Entries.Count -eq 0)
				{
					$archiveFileIsEmpty = ($LocalizedData.ArchiveFileIsEmpty -f $archiveFile)
					Write-Verbose $archiveFileIsEmpty
					return
				}

				$currentEntryCount = 0
				$progressBarStatus = ($LocalizedData.ExpandProgressBarText -f $archiveFile)

				
				foreach ($currentArchiveEntry in $zipArchive.Entries)
				{
					$currentArchiveEntryPath = Join-Path -Path $expandedDir -ChildPath $currentArchiveEntry.FullName
					$extension = [system.IO.Path]::GetExtension($currentArchiveEntryPath)

					
					
					if ($extension -eq [string]::Empty -and
						$currentArchiveEntryPath.EndsWith("\", [StringComparison]::OrdinalIgnoreCase))
					{
						$pathExists = Test-Path -LiteralPath $currentArchiveEntryPath

						
						
						
						if ($pathExists -eq $false)
						{
							New-Item $currentArchiveEntryPath -ItemType Directory -Confirm:$isConfirm | Out-Null

							if (Test-Path -LiteralPath $currentArchiveEntryPath -PathType Container)
							{
								$addEmptyDirectorytoExpandedPathMessage = ($LocalizedData.AddItemtoArchiveFile -f $currentArchiveEntryPath)
								Write-Verbose $addEmptyDirectorytoExpandedPathMessage

								$expandedItems.Value += $currentArchiveEntryPath
							}
						}
					}
					else
					{
						try
						{
							$currentArchiveEntryFileInfo = New-Object -TypeName System.IO.FileInfo -ArgumentList $currentArchiveEntryPath
							$parentDirExists = Test-Path -LiteralPath $currentArchiveEntryFileInfo.DirectoryName -PathType Container

							
							if ($parentDirExists -eq $false)
							{
								New-Item $currentArchiveEntryFileInfo.DirectoryName -ItemType Directory -Confirm:$isConfirm | Out-Null

								if (!(Test-Path -LiteralPath $currentArchiveEntryFileInfo.DirectoryName -PathType Container))
								{
									
									
									
									
									Continue
								}

								$expandedItems.Value += $currentArchiveEntryFileInfo.DirectoryName
							}

							$hasNonTerminatingError = $false

							
							
							if ($currentArchiveEntryFileInfo.Exists)
							{
								if ($force)
								{
									Remove-Item -LiteralPath $currentArchiveEntryFileInfo.FullName -Force -ErrorVariable ev -Verbose:$isVerbose -Confirm:$isConfirm
									if ($ev -ne $null)
									{
										$hasNonTerminatingError = $true
									}

									if (Test-Path -LiteralPath $currentArchiveEntryFileInfo.FullName -PathType Leaf)
									{
										
										
										
										
										Continue
									}
								}
								else
								{
									
									$errorMessage = ($LocalizedData.FileExistsError -f $currentArchiveEntryFileInfo.FullName, $archiveFile, $currentArchiveEntryFileInfo.FullName, $currentArchiveEntryFileInfo.FullName)
									$errorRecord = CreateErrorRecordHelper "ExpandArchiveFileExists" $errorMessage ([System.Management.Automation.ErrorCategory]::InvalidOperation) $null $currentArchiveEntryFileInfo.FullName
									Write-Error -ErrorRecord $errorRecord
									$hasNonTerminatingError = $true
								}
							}

							if (!$hasNonTerminatingError)
							{
								[System.IO.Compression.ZipFileExtensions]::ExtractToFile($currentArchiveEntry, $currentArchiveEntryPath, $false)

								
								
								
								
								$expandedItems.Value += $currentArchiveEntryPath

								$addFiletoExpandedPathMessage = ($LocalizedData.CreateFileAtExpandedPath -f $currentArchiveEntryPath)
								Write-Verbose $addFiletoExpandedPathMessage
							}
						}
						finally
						{
							If ($null -ne $destStream)
							{
								$destStream.Dispose()
							}

							If ($null -ne $srcStream)
							{
								$srcStream.Dispose()
							}
						}
					}

					$currentEntryCount += 1
					
					
					$previousSegmentWeight = 0
					$currentSegmentWeight = 100
					ProgressBarHelper "Expand-Archive" $progressBarStatus $previousSegmentWeight $currentSegmentWeight $zipArchive.Entries.Count  $currentEntryCount
				}
			}
			finally
			{
				If ($null -ne $zipArchive)
				{
					$zipArchive.Dispose()
				}

				If ($null -ne $archiveFileStream)
				{
					$archiveFileStream.Dispose()
				}

				
				Write-Progress -Activity "Expand-Archive" -Completed
			}
		}


		function ProgressBarHelper
		{
			param
			(
				[string]
				$cmdletName,

				[string]
				$status,

				[double]
				$previousSegmentWeight,

				[double]
				$currentSegmentWeight,

				[int]
				$totalNumberofEntries,

				[int]
				$currentEntryCount
			)

			if ($currentEntryCount -gt 0 -and
				$totalNumberofEntries -gt 0 -and
				$previousSegmentWeight -ge 0 -and
				$currentSegmentWeight -gt 0)
			{
				$entryDefaultWeight = $currentSegmentWeight/[double]$totalNumberofEntries

				$percentComplete = $previousSegmentWeight + ($entryDefaultWeight * $currentEntryCount)
				Write-Progress -Activity $cmdletName -Status $status -PercentComplete $percentComplete
			}
		}


		function CSVHelper
		{
			param
			(
				[string[]]
				$sourcePath
			)

			
			if ($sourcePath.Count -gt 1)
			{
				$sourcePathInCsvFormat = "`n"
				for ($currentIndex = 0; $currentIndex -lt $sourcePath.Count; $currentIndex++)
				{
					if ($currentIndex -eq $sourcePath.Count - 1)
					{
						$sourcePathInCsvFormat += $sourcePath[$currentIndex]
					}
					else
					{
						$sourcePathInCsvFormat += $sourcePath[$currentIndex] + "`n"
					}
				}
			}
			else
			{
				$sourcePathInCsvFormat = $sourcePath
			}

			return $sourcePathInCsvFormat
		}


		function ThrowTerminatingErrorHelper
		{
			param
			(
				[string]
				$errorId,

				[string]
				$errorMessage,

				[System.Management.Automation.ErrorCategory]
				$errorCategory,

				[object]
				$targetObject,

				[Exception]
				$innerException
			)

			if ($innerException -eq $null)
			{
				$exception = New-object System.IO.IOException $errorMessage
			}
			else
			{
				$exception = New-Object System.IO.IOException $errorMessage, $innerException
			}

			$exception = New-Object System.IO.IOException $errorMessage
			$errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $targetObject
			$PSCmdlet.ThrowTerminatingError($errorRecord)
		}


		function CreateErrorRecordHelper
		{
			param
			(
				[string]
				$errorId,

				[string]
				$errorMessage,

				[System.Management.Automation.ErrorCategory]
				$errorCategory,

				[Exception]
				$exception,

				[object]
				$targetObject
			)

			if ($null -eq $exception)
			{
				$exception = New-Object System.IO.IOException $errorMessage
			}

			$errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $targetObject
			return $errorRecord
		}
		

		$inputPaths = @()
		$destinationParentDir = [system.IO.Path]::GetDirectoryName($DestinationPath)
		if ($null -eq $destinationParentDir)
		{
			$errorMessage = ($LocalizedData.InvalidDestinationPath -f $DestinationPath)
			ThrowTerminatingErrorHelper "InvalidArchiveFilePath" $errorMessage ([System.Management.Automation.ErrorCategory]::InvalidArgument) $DestinationPath
		}

		if ($destinationParentDir -eq [string]::Empty)
		{
			$destinationParentDir = '.'
		}

		$achiveFileName = [system.IO.Path]::GetFileName($DestinationPath)
		$destinationParentDir = GetResolvedPathHelper $destinationParentDir $false $PSCmdlet

		if ($destinationParentDir.Count -gt 1)
		{
			$errorMessage = ($LocalizedData.InvalidArchiveFilePathError -f $DestinationPath, "DestinationPath", "DestinationPath")
			ThrowTerminatingErrorHelper "InvalidArchiveFilePath" $errorMessage ([System.Management.Automation.ErrorCategory]::InvalidArgument) $DestinationPath
		}

		IsValidFileSystemPath $destinationParentDir | Out-Null
		$DestinationPath = Join-Path -Path $destinationParentDir -ChildPath $achiveFileName

		
		$extension = [system.IO.Path]::GetExtension($DestinationPath)

		
		If ($extension -eq [string]::Empty)
		{
			$DestinationPathWithOutExtension = $DestinationPath
			$DestinationPath = $DestinationPathWithOutExtension + $zipFileExtension
			$appendArchiveFileExtensionMessage = ($LocalizedData.AppendArchiveFileExtensionMessage -f $DestinationPathWithOutExtension, $DestinationPath)
			Write-Verbose $appendArchiveFileExtensionMessage
		}
		else
		{
			
			if ($extension -ne $zipFileExtension)
			{
				$errorMessage = ($LocalizedData.InvalidZipFileExtensionError -f $extension, $zipFileExtension)
				ThrowTerminatingErrorHelper "NotSupportedArchiveFileExtension" $errorMessage ([System.Management.Automation.ErrorCategory]::InvalidArgument) $extension
			}
		}

		$archiveFileExist = Test-Path -LiteralPath $DestinationPath -PathType Leaf

		if ($archiveFileExist -and ($Update -eq $false -and $Force -eq $false))
		{
			$errorMessage = ($LocalizedData.ZipFileExistError -f $DestinationPath)
			ThrowTerminatingErrorHelper "ArchiveFileExists" $errorMessage ([System.Management.Automation.ErrorCategory]::InvalidArgument) $DestinationPath
		}

		
		
		if ($archiveFileExist -and $Update -eq $true)
		{
			$item = Get-Item -Path $DestinationPath
			if ($item.Attributes.ToString().Contains("ReadOnly"))
			{
				$errorMessage = ($LocalizedData.ArchiveFileIsReadOnly -f $DestinationPath)
				ThrowTerminatingErrorHelper "ArchiveFileIsReadOnly" $errorMessage ([System.Management.Automation.ErrorCategory]::InvalidOperation) $DestinationPath
			}
		}

		$isWhatIf = $psboundparameters.ContainsKey("WhatIf")
		if (!$isWhatIf)
		{
			$preparingToCompressVerboseMessage = ($LocalizedData.PreparingToCompressVerboseMessage)
			Write-Verbose $preparingToCompressVerboseMessage

			$progressBarStatus = ($LocalizedData.CompressProgressBarText -f $DestinationPath)
			ProgressBarHelper "Compress-Archive" $progressBarStatus 0 100 100 1
		}
	}
	PROCESS
	{
		if ($PsCmdlet.ParameterSetName -eq "Path" -or
			$PsCmdlet.ParameterSetName -eq "PathWithForce" -or
			$PsCmdlet.ParameterSetName -eq "PathWithUpdate")
		{
			$inputPaths += $Path
		}

		if ($PsCmdlet.ParameterSetName -eq "LiteralPath" -or
			$PsCmdlet.ParameterSetName -eq "LiteralPathWithForce" -or
			$PsCmdlet.ParameterSetName -eq "LiteralPathWithUpdate")
		{
			$inputPaths += $LiteralPath
		}
	}
	END
	{
		
		
		if (($PsCmdlet.ParameterSetName -eq "PathWithForce" -or
				$PsCmdlet.ParameterSetName -eq "LiteralPathWithForce") -and $archiveFileExist)
		{
			Remove-Item -Path $DestinationPath -Force -ErrorAction Stop
		}

		
		
		
		$isLiteralPathUsed = $false
		if ($PsCmdlet.ParameterSetName -eq "LiteralPath" -or
			$PsCmdlet.ParameterSetName -eq "LiteralPathWithForce" -or
			$PsCmdlet.ParameterSetName -eq "LiteralPathWithUpdate")
		{
			$isLiteralPathUsed = $true
		}

		ValidateDuplicateFileSystemPath $PsCmdlet.ParameterSetName $inputPaths
		$resolvedPaths = GetResolvedPathHelper $inputPaths $isLiteralPathUsed $PSCmdlet
		IsValidFileSystemPath $resolvedPaths | Out-Null

		$sourcePath = $resolvedPaths;

		
		
		$sourcePathInCsvFormat = CSVHelper $sourcePath
		if ($pscmdlet.ShouldProcess($sourcePathInCsvFormat))
		{
			try
			{
				
				
				
				
				
				$isArchiveFileProcessingComplete = $false

				$numberOfItemsArchived = CompressArchiveHelper $sourcePath $DestinationPath $CompressionLevel $Update

				$isArchiveFileProcessingComplete = $true
			}
			finally
			{
				
				
				
				
				if (($isArchiveFileProcessingComplete -eq $false) -or
					($numberOfItemsArchived -eq 0))
				{
					$DeleteArchiveFileMessage = ($LocalizedData.DeleteArchiveFile -f $DestinationPath)
					Write-Verbose $DeleteArchiveFileMessage

					
					if (Test-Path $DestinationPath)
					{
						Remove-Item -LiteralPath $DestinationPath -Force -Recurse -ErrorAction SilentlyContinue
					}
				}
			}
		}
	}
}

function Expand-Archive
{
	
	[CmdletBinding(
				   DefaultParameterSetName = "Path",
				   SupportsShouldProcess = $true,
				   HelpUri = "http://go.microsoft.com/fwlink/?LinkID=393253")]
	param
	(
		[parameter (
					mandatory = $true,
					Position = 0,
					ParameterSetName = "Path",
					ValueFromPipeline = $true,
					ValueFromPipelineByPropertyName = $true)]
		[ValidateNotNullOrEmpty()]
		[string]
		$Path,

		[parameter (
					mandatory = $true,
					ParameterSetName = "LiteralPath",
					ValueFromPipelineByPropertyName = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias("PSPath")]
		[string]
		$LiteralPath,

		[parameter (mandatory = $false,
					Position = 1,
					ValueFromPipeline = $false,
					ValueFromPipelineByPropertyName = $false)]
		[ValidateNotNullOrEmpty()]
		[string]
		$DestinationPath,

		[parameter (mandatory = $false,
					ValueFromPipeline = $false,
					ValueFromPipelineByPropertyName = $false)]
		[switch]
		$Force
	)

	BEGIN
	{
		Add-Type -AssemblyName System.IO.Compression -ErrorAction Ignore
		Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Ignore

		$zipFileExtension = ".zip"

		$LocalizedData = ConvertFrom-StringData @'
PathNotFoundError=The path '{0}' either does not exist or is not a valid file system path.
ExpandArchiveInValidDestinationPath=The path '{0}' is not a valid file system directory path.
InvalidZipFileExtensionError={0} is not a supported archive file format. {1} is the only supported archive file format.
ArchiveFileIsReadOnly=The attributes of the archive file {0} is set to 'ReadOnly' hence it cannot be updated. If you intend to update the existing archive file, remove the 'ReadOnly' attribute on the archive file else use -Force parameter to override and create a new archive file.
ZipFileExistError=The archive file {0} already exists. Use the -Update parameter to update the existing archive file or use the -Force parameter to overwrite the existing archive file.
DuplicatePathFoundError=The input to {0} parameter contains a duplicate path '{1}'. Provide a unique set of paths as input to {2} parameter.
ArchiveFileIsEmpty=The archive file {0} is empty.
CompressProgressBarText=The archive file '{0}' creation is in progress...
ExpandProgressBarText=The archive file '{0}' expansion is in progress...
AppendArchiveFileExtensionMessage=The archive file path '{0}' supplied to the DestinationPath patameter does not include .zip extension. Hence .zip is appended to the supplied DestinationPath path and the archive file would be created at '{1}'.
AddItemtoArchiveFile=Adding '{0}'.
CreateFileAtExpandedPath=Created '{0}'.
InvalidArchiveFilePathError=The archive file path '{0}' specified as input to the {1} parameter is resolving to multiple file system paths. Provide a unique path to the {2} parameter where the archive file has to be created.
InvalidExpandedDirPathError=The directory path '{0}' specified as input to the DestinationPath parameter is resolving to multiple file system paths. Provide a unique path to the Destination parameter where the archive file contents have to be expanded.
FileExistsError=Failed to create file '{0}' while expanding the archive file '{1}' contents as the file '{2}' already exists. Use the -Force parameter if you want to overwrite the existing directory '{3}' contents when expanding the archive file.
DeleteArchiveFile=The partially created archive file '{0}' is deleted as it is not usable.
InvalidDestinationPath=The destination path '{0}' does not contain a valid archive file name.
PreparingToCompressVerboseMessage=Preparing to compress...
PreparingToExpandVerboseMessage=Preparing to expand...
'@

		
		function GetResolvedPathHelper
		{
			param
			(
				[string[]]
				$path,

				[boolean]
				$isLiteralPath,

				[System.Management.Automation.PSCmdlet]
				$callerPSCmdlet
			)

			$resolvedPaths = @()

			
			foreach ($currentPath in $path)
			{
				try
				{
					if ($isLiteralPath)
					{
						$currentResolvedPaths = Resolve-Path -LiteralPath $currentPath -ErrorAction Stop
					}
					else
					{
						$currentResolvedPaths = Resolve-Path -Path $currentPath -ErrorAction Stop
					}
				}
				catch
				{
					$errorMessage = ($LocalizedData.PathNotFoundError -f $currentPath)
					$exception = New-Object System.InvalidOperationException $errorMessage, $_.Exception
					$errorRecord = CreateErrorRecordHelper "ArchiveCmdletPathNotFound" $null ([System.Management.Automation.ErrorCategory]::InvalidArgument) $exception $currentPath
					$callerPSCmdlet.ThrowTerminatingError($errorRecord)
				}

				foreach ($currentResolvedPath in $currentResolvedPaths)
				{
					$resolvedPaths += $currentResolvedPath.ProviderPath
				}
			}

			$resolvedPaths
		}

		function Add-CompressionAssemblies
		{

			if ($PSEdition -eq "Desktop")
			{
				Add-Type -AssemblyName System.IO.Compression
				Add-Type -AssemblyName System.IO.Compression.FileSystem
			}
		}

		function IsValidFileSystemPath
		{
			param
			(
				[string[]]
				$path
			)

			$result = $true;

			
			foreach ($currentPath in $path)
			{
				if (!([System.IO.File]::Exists($currentPath) -or [System.IO.Directory]::Exists($currentPath)))
				{
					$errorMessage = ($LocalizedData.PathNotFoundError -f $currentPath)
					ThrowTerminatingErrorHelper "PathNotFound" $errorMessage ([System.Management.Automation.ErrorCategory]::InvalidArgument) $currentPath
				}
			}

			return $result;
		}


		function ValidateDuplicateFileSystemPath
		{
			param
			(
				[string]
				$inputParameter,

				[string[]]
				$path
			)

			$uniqueInputPaths = @()

			
			foreach ($currentPath in $path)
			{
				$currentInputPath = $currentPath.ToUpper()
				if ($uniqueInputPaths.Contains($currentInputPath))
				{
					$errorMessage = ($LocalizedData.DuplicatePathFoundError -f $inputParameter, $currentPath, $inputParameter)
					ThrowTerminatingErrorHelper "DuplicatePathFound" $errorMessage ([System.Management.Automation.ErrorCategory]::InvalidArgument) $currentPath
				}
				else
				{
					$uniqueInputPaths += $currentInputPath
				}
			}
		}

		function CompressionLevelMapper
		{
			param
			(
				[string]
				$compressionLevel
			)

			$compressionLevelFormat = [System.IO.Compression.CompressionLevel]::Optimal

			
			switch ($compressionLevel.ToString())
			{
				"Fastest"
				{
					$compressionLevelFormat = [System.IO.Compression.CompressionLevel]::Fastest
				}
				"NoCompression"
				{
					$compressionLevelFormat = [System.IO.Compression.CompressionLevel]::NoCompression
				}
			}

			return $compressionLevelFormat
		}

		function CompressArchiveHelper
		{
			param
			(
				[string[]]
				$sourcePath,

				[string]
				$destinationPath,

				[string]
				$compressionLevel,

				[bool]
				$isUpdateMode
			)

			$numberOfItemsArchived = 0
			$sourceFilePaths = @()
			$sourceDirPaths = @()

			foreach ($currentPath in $sourcePath)
			{
				$result = Test-Path -LiteralPath $currentPath -PathType Leaf
				if ($result -eq $true)
				{
					$sourceFilePaths += $currentPath
				}
				else
				{
					$sourceDirPaths += $currentPath
				}
			}

			
			if ($sourceFilePaths.Count -eq 0 -and $sourceDirPaths.Count -gt 0)
			{
				$currentSegmentWeight = 100/[double]$sourceDirPaths.Count
				$previousSegmentWeight = 0
				foreach ($currentSourceDirPath in $sourceDirPaths)
				{
					$count = CompressSingleDirHelper $currentSourceDirPath $destinationPath $compressionLevel $true $isUpdateMode $previousSegmentWeight $currentSegmentWeight
					$numberOfItemsArchived += $count
					$previousSegmentWeight += $currentSegmentWeight
				}
			}

			
			elseIf ($sourceFilePaths.Count -gt 0 -and $sourceDirPaths.Count -eq 0)
			{
				
				
				$previousSegmentWeight = 0
				$currentSegmentWeight = 100

				$numberOfItemsArchived = CompressFilesHelper $sourceFilePaths $destinationPath $compressionLevel $isUpdateMode $previousSegmentWeight $currentSegmentWeight
			}
			
			elseif ($sourceFilePaths.Count -gt 0 -and $sourceDirPaths.Count -gt 0)
			{
				
				$currentSegmentWeight = 100/[double]($sourceDirPaths.Count + 1)
				$previousSegmentWeight = 0

				foreach ($currentSourceDirPath in $sourceDirPaths)
				{
					$count = CompressSingleDirHelper $currentSourceDirPath $destinationPath $compressionLevel $true $isUpdateMode $previousSegmentWeight $currentSegmentWeight
					$numberOfItemsArchived += $count
					$previousSegmentWeight += $currentSegmentWeight
				}

				$count = CompressFilesHelper $sourceFilePaths $destinationPath $compressionLevel $isUpdateMode $previousSegmentWeight $currentSegmentWeight
				$numberOfItemsArchived += $count
			}

			return $numberOfItemsArchived
		}

		function CompressFilesHelper
		{
			param
			(
				[string[]]
				$sourceFilePaths,

				[string]
				$destinationPath,

				[string]
				$compressionLevel,

				[bool]
				$isUpdateMode,

				[double]
				$previousSegmentWeight,

				[double]
				$currentSegmentWeight
			)

			$numberOfItemsArchived = ZipArchiveHelper $sourceFilePaths $destinationPath $compressionLevel $isUpdateMode $null $previousSegmentWeight $currentSegmentWeight

			return $numberOfItemsArchived
		}

		function CompressSingleDirHelper
		{
			param
			(
				[string]
				$sourceDirPath,

				[string]
				$destinationPath,

				[string]
				$compressionLevel,

				[bool]
				$useParentDirAsRoot,

				[bool]
				$isUpdateMode,

				[double]
				$previousSegmentWeight,

				[double]
				$currentSegmentWeight
			)

			[System.Collections.Generic.List[System.String]]$subDirFiles = @()

			if ($useParentDirAsRoot)
			{
				$sourceDirInfo = New-Object -TypeName System.IO.DirectoryInfo -ArgumentList $sourceDirPath
				$sourceDirFullName = $sourceDirInfo.Parent.FullName

				
				
				
				if ($sourceDirFullName.Length -eq 3)
				{
					$modifiedSourceDirFullName = $sourceDirFullName
				}
				else
				{
					$modifiedSourceDirFullName = $sourceDirFullName + "\"
				}
			}
			else
			{
				$sourceDirFullName = $sourceDirPath
				$modifiedSourceDirFullName = $sourceDirFullName + "\"
			}

			$dirContents = Get-ChildItem -LiteralPath $sourceDirPath -Recurse
			foreach ($currentContent in $dirContents)
			{
				$isContainer = $currentContent -is [System.IO.DirectoryInfo]
				if (!$isContainer)
				{
					$subDirFiles.Add($currentContent.FullName)
				}
				else
				{
					
					
					
					
					$files = $currentContent.GetFiles()
					if ($files.Count -eq 0)
					{
						$subDirFiles.Add($currentContent.FullName + "\")
					}
				}
			}

			$numberOfItemsArchived = ZipArchiveHelper $subDirFiles.ToArray() $destinationPath $compressionLevel $isUpdateMode $modifiedSourceDirFullName $previousSegmentWeight $currentSegmentWeight

			return $numberOfItemsArchived
		}

		function ZipArchiveHelper
		{
			param
			(
				[System.Collections.Generic.List[System.String]]
				$sourcePaths,

				[string]
				$destinationPath,

				[string]
				$compressionLevel,

				[bool]
				$isUpdateMode,

				[string]
				$modifiedSourceDirFullName,

				[double]
				$previousSegmentWeight,

				[double]
				$currentSegmentWeight
			)

			$numberOfItemsArchived = 0
			$fileMode = [System.IO.FileMode]::Create
			$result = Test-Path -LiteralPath $DestinationPath -PathType Leaf
			if ($result -eq $true)
			{
				$fileMode = [System.IO.FileMode]::Open
			}

			Add-CompressionAssemblies

			try
			{
				
				$archiveFileStreamArgs = @($destinationPath, $fileMode)
				$archiveFileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $archiveFileStreamArgs

				$zipArchiveArgs = @($archiveFileStream, [System.IO.Compression.ZipArchiveMode]::Update, $false)
				$zipArchive = New-Object -TypeName System.IO.Compression.ZipArchive -ArgumentList $zipArchiveArgs

				$currentEntryCount = 0
				$progressBarStatus = ($LocalizedData.CompressProgressBarText -f $destinationPath)
				$bufferSize = 4kb
				$buffer = New-Object Byte[] $bufferSize

				foreach ($currentFilePath in $sourcePaths)
				{
					if ($modifiedSourceDirFullName -ne $null -and $modifiedSourceDirFullName.Length -gt 0)
					{
						$index = $currentFilePath.IndexOf($modifiedSourceDirFullName, [System.StringComparison]::OrdinalIgnoreCase)
						$currentFilePathSubString = $currentFilePath.Substring($index, $modifiedSourceDirFullName.Length)
						$relativeFilePath = $currentFilePath.Replace($currentFilePathSubString, "").Trim()
					}
					else
					{
						$relativeFilePath = [System.IO.Path]::GetFileName($currentFilePath)
					}

					
					
					if ($isUpdateMode -eq $true -and $zipArchive.Entries.Count -gt 0)
					{
						$entryToBeUpdated = $null

						
						
						
						

						foreach ($currentArchiveEntry in $zipArchive.Entries)
						{
							if ($currentArchiveEntry.FullName -eq $relativeFilePath)
							{
								$entryToBeUpdated = $currentArchiveEntry
								break
							}
						}

						if ($entryToBeUpdated -ne $null)
						{
							$addItemtoArchiveFileMessage = ($LocalizedData.AddItemtoArchiveFile -f $currentFilePath)
							$entryToBeUpdated.Delete()
						}
					}

					$compression = CompressionLevelMapper $compressionLevel

					
					
					
					if (!$relativeFilePath.EndsWith("\", [StringComparison]::OrdinalIgnoreCase))
					{
						try
						{
							try
							{
								$currentFileStream = [System.IO.File]::Open($currentFilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
							}
							catch
							{
								
								
								$exception = $_.Exception
								if ($null -ne $_.Exception -and
									$null -ne $_.Exception.InnerException)
								{
									$exception = $_.Exception.InnerException
								}
								$errorRecord = CreateErrorRecordHelper "CompressArchiveUnauthorizedAccessError" $null ([System.Management.Automation.ErrorCategory]::PermissionDenied) $exception $currentFilePath
								Write-Error -ErrorRecord $errorRecord
							}

							if ($null -ne $currentFileStream)
							{
								$srcStream = New-Object System.IO.BinaryReader $currentFileStream

								$currentArchiveEntry = $zipArchive.CreateEntry($relativeFilePath, $compression)

								
								
								$currentArchiveEntry.LastWriteTime = (Get-Item -LiteralPath $currentFilePath).LastWriteTime

								$destStream = New-Object System.IO.BinaryWriter $currentArchiveEntry.Open()

								while ($numberOfBytesRead = $srcStream.Read($buffer, 0, $bufferSize))
								{
									$destStream.Write($buffer, 0, $numberOfBytesRead)
									$destStream.Flush()
								}

								$numberOfItemsArchived += 1
								$addItemtoArchiveFileMessage = ($LocalizedData.AddItemtoArchiveFile -f $currentFilePath)
							}
						}
						finally
						{
							If ($null -ne $currentFileStream)
							{
								$currentFileStream.Dispose()
							}
							If ($null -ne $srcStream)
							{
								$srcStream.Dispose()
							}
							If ($null -ne $destStream)
							{
								$destStream.Dispose()
							}
						}
					}
					else
					{
						$currentArchiveEntry = $zipArchive.CreateEntry("$relativeFilePath", $compression)
						$numberOfItemsArchived += 1
						$addItemtoArchiveFileMessage = ($LocalizedData.AddItemtoArchiveFile -f $currentFilePath)
					}

					if ($null -ne $addItemtoArchiveFileMessage)
					{
						Write-Verbose $addItemtoArchiveFileMessage
					}

					$currentEntryCount += 1
					ProgressBarHelper "Compress-Archive" $progressBarStatus $previousSegmentWeight $currentSegmentWeight $sourcePaths.Count  $currentEntryCount
				}
			}
			finally
			{
				If ($null -ne $zipArchive)
				{
					$zipArchive.Dispose()
				}

				If ($null -ne $archiveFileStream)
				{
					$archiveFileStream.Dispose()
				}

				
				Write-Progress -Activity "Compress-Archive" -Completed
			}

			return $numberOfItemsArchived
		}


		function ValidateArchivePathHelper
		{
			param
			(
				[string]
				$archiveFile
			)

			if ([System.IO.File]::Exists($archiveFile))
			{
				$extension = [system.IO.Path]::GetExtension($archiveFile)

				
				if ($extension -ne $zipFileExtension)
				{
					$errorMessage = ($LocalizedData.InvalidZipFileExtensionError -f $extension, $zipFileExtension)
					ThrowTerminatingErrorHelper "NotSupportedArchiveFileExtension" $errorMessage ([System.Management.Automation.ErrorCategory]::InvalidArgument) $extension
				}
			}
			else
			{
				$errorMessage = ($LocalizedData.PathNotFoundError -f $archiveFile)
				ThrowTerminatingErrorHelper "PathNotFound" $errorMessage ([System.Management.Automation.ErrorCategory]::InvalidArgument) $archiveFile
			}
		}


		function ExpandArchiveHelper
		{
			param
			(
				[string]
				$archiveFile,

				[string]
				$expandedDir,

				[ref]
				$expandedItems,

				[boolean]
				$force,

				[boolean]
				$isVerbose,

				[boolean]
				$isConfirm
			)

			Add-CompressionAssemblies

			try
			{
				
				
				$archiveFileStreamArgs = @($archiveFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
				$archiveFileStream = New-Object -TypeName System.IO.FileStream -ArgumentList $archiveFileStreamArgs

				$zipArchiveArgs = @($archiveFileStream, [System.IO.Compression.ZipArchiveMode]::Read, $false)
				$zipArchive = New-Object -TypeName System.IO.Compression.ZipArchive -ArgumentList $zipArchiveArgs

				if ($zipArchive.Entries.Count -eq 0)
				{
					$archiveFileIsEmpty = ($LocalizedData.ArchiveFileIsEmpty -f $archiveFile)
					Write-Verbose $archiveFileIsEmpty
					return
				}

				$currentEntryCount = 0
				$progressBarStatus = ($LocalizedData.ExpandProgressBarText -f $archiveFile)

				
				foreach ($currentArchiveEntry in $zipArchive.Entries)
				{
					$currentArchiveEntryPath = Join-Path -Path $expandedDir -ChildPath $currentArchiveEntry.FullName
					$extension = [system.IO.Path]::GetExtension($currentArchiveEntryPath)

					
					
					if ($extension -eq [string]::Empty -and
						$currentArchiveEntryPath.EndsWith("\", [StringComparison]::OrdinalIgnoreCase))
					{
						$pathExists = Test-Path -LiteralPath $currentArchiveEntryPath

						
						
						
						if ($pathExists -eq $false)
						{
							New-Item $currentArchiveEntryPath -ItemType Directory -Confirm:$isConfirm | Out-Null

							if (Test-Path -LiteralPath $currentArchiveEntryPath -PathType Container)
							{
								$addEmptyDirectorytoExpandedPathMessage = ($LocalizedData.AddItemtoArchiveFile -f $currentArchiveEntryPath)
								Write-Verbose $addEmptyDirectorytoExpandedPathMessage

								$expandedItems.Value += $currentArchiveEntryPath
							}
						}
					}
					else
					{
						try
						{
							$currentArchiveEntryFileInfo = New-Object -TypeName System.IO.FileInfo -ArgumentList $currentArchiveEntryPath
							$parentDirExists = Test-Path -LiteralPath $currentArchiveEntryFileInfo.DirectoryName -PathType Container

							
							if ($parentDirExists -eq $false)
							{
								New-Item $currentArchiveEntryFileInfo.DirectoryName -ItemType Directory -Confirm:$isConfirm | Out-Null

								if (!(Test-Path -LiteralPath $currentArchiveEntryFileInfo.DirectoryName -PathType Container))
								{
									
									
									
									
									Continue
								}

								$expandedItems.Value += $currentArchiveEntryFileInfo.DirectoryName
							}

							$hasNonTerminatingError = $false

							
							
							if ($currentArchiveEntryFileInfo.Exists)
							{
								if ($force)
								{
									Remove-Item -LiteralPath $currentArchiveEntryFileInfo.FullName -Force -ErrorVariable ev -Verbose:$isVerbose -Confirm:$isConfirm
									if ($ev -ne $null)
									{
										$hasNonTerminatingError = $true
									}

									if (Test-Path -LiteralPath $currentArchiveEntryFileInfo.FullName -PathType Leaf)
									{
										
										
										
										
										Continue
									}
								}
								else
								{
									
									$errorMessage = ($LocalizedData.FileExistsError -f $currentArchiveEntryFileInfo.FullName, $archiveFile, $currentArchiveEntryFileInfo.FullName, $currentArchiveEntryFileInfo.FullName)
									$errorRecord = CreateErrorRecordHelper "ExpandArchiveFileExists" $errorMessage ([System.Management.Automation.ErrorCategory]::InvalidOperation) $null $currentArchiveEntryFileInfo.FullName
									Write-Error -ErrorRecord $errorRecord
									$hasNonTerminatingError = $true
								}
							}

							if (!$hasNonTerminatingError)
							{
								[System.IO.Compression.ZipFileExtensions]::ExtractToFile($currentArchiveEntry, $currentArchiveEntryPath, $false)

								
								
								
								
								$expandedItems.Value += $currentArchiveEntryPath

								$addFiletoExpandedPathMessage = ($LocalizedData.CreateFileAtExpandedPath -f $currentArchiveEntryPath)
								Write-Verbose $addFiletoExpandedPathMessage
							}
						}
						finally
						{
							If ($null -ne $destStream)
							{
								$destStream.Dispose()
							}

							If ($null -ne $srcStream)
							{
								$srcStream.Dispose()
							}
						}
					}

					$currentEntryCount += 1
					
					
					$previousSegmentWeight = 0
					$currentSegmentWeight = 100
					ProgressBarHelper "Expand-Archive" $progressBarStatus $previousSegmentWeight $currentSegmentWeight $zipArchive.Entries.Count  $currentEntryCount
				}
			}
			finally
			{
				If ($null -ne $zipArchive)
				{
					$zipArchive.Dispose()
				}

				If ($null -ne $archiveFileStream)
				{
					$archiveFileStream.Dispose()
				}

				
				Write-Progress -Activity "Expand-Archive" -Completed
			}
		}


		function ProgressBarHelper
		{
			param
			(
				[string]
				$cmdletName,

				[string]
				$status,

				[double]
				$previousSegmentWeight,

				[double]
				$currentSegmentWeight,

				[int]
				$totalNumberofEntries,

				[int]
				$currentEntryCount
			)

			if ($currentEntryCount -gt 0 -and
				$totalNumberofEntries -gt 0 -and
				$previousSegmentWeight -ge 0 -and
				$currentSegmentWeight -gt 0)
			{
				$entryDefaultWeight = $currentSegmentWeight/[double]$totalNumberofEntries

				$percentComplete = $previousSegmentWeight + ($entryDefaultWeight * $currentEntryCount)
				Write-Progress -Activity $cmdletName -Status $status -PercentComplete $percentComplete
			}
		}


		function CSVHelper
		{
			param
			(
				[string[]]
				$sourcePath
			)

			
			if ($sourcePath.Count -gt 1)
			{
				$sourcePathInCsvFormat = "`n"
				for ($currentIndex = 0; $currentIndex -lt $sourcePath.Count; $currentIndex++)
				{
					if ($currentIndex -eq $sourcePath.Count - 1)
					{
						$sourcePathInCsvFormat += $sourcePath[$currentIndex]
					}
					else
					{
						$sourcePathInCsvFormat += $sourcePath[$currentIndex] + "`n"
					}
				}
			}
			else
			{
				$sourcePathInCsvFormat = $sourcePath
			}

			return $sourcePathInCsvFormat
		}


		function ThrowTerminatingErrorHelper
		{
			param
			(
				[string]
				$errorId,

				[string]
				$errorMessage,

				[System.Management.Automation.ErrorCategory]
				$errorCategory,

				[object]
				$targetObject,

				[Exception]
				$innerException
			)

			if ($innerException -eq $null)
			{
				$exception = New-object System.IO.IOException $errorMessage
			}
			else
			{
				$exception = New-Object System.IO.IOException $errorMessage, $innerException
			}

			$exception = New-Object System.IO.IOException $errorMessage
			$errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $targetObject
			$PSCmdlet.ThrowTerminatingError($errorRecord)
		}


		function CreateErrorRecordHelper
		{
			param
			(
				[string]
				$errorId,

				[string]
				$errorMessage,

				[System.Management.Automation.ErrorCategory]
				$errorCategory,

				[Exception]
				$exception,

				[object]
				$targetObject
			)

			if ($null -eq $exception)
			{
				$exception = New-Object System.IO.IOException $errorMessage
			}

			$errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $targetObject
			return $errorRecord
		}
		

		$isVerbose = $psboundparameters.ContainsKey("Verbose")
		$isConfirm = $psboundparameters.ContainsKey("Confirm")

		$isDestinationPathProvided = $true
		if ($DestinationPath -eq [string]::Empty)
		{
			$resolvedDestinationPath = $pwd
			$isDestinationPathProvided = $false
		}
		else
		{
			$destinationPathExists = Test-Path -Path $DestinationPath -PathType Container
			if ($destinationPathExists)
			{
				$resolvedDestinationPath = GetResolvedPathHelper $DestinationPath $false $PSCmdlet
				if ($resolvedDestinationPath.Count -gt 1)
				{
					$errorMessage = ($LocalizedData.InvalidExpandedDirPathError -f $DestinationPath)
					ThrowTerminatingErrorHelper "InvalidDestinationPath" $errorMessage ([System.Management.Automation.ErrorCategory]::InvalidArgument) $DestinationPath
				}

				
				
				$suppliedDestinationPath = Resolve-Path -Path $DestinationPath
				if ($suppliedDestinationPath.Provider.Name -ne "FileSystem")
				{
					$errorMessage = ($LocalizedData.ExpandArchiveInValidDestinationPath -f $DestinationPath)
					ThrowTerminatingErrorHelper "InvalidDirectoryPath" $errorMessage ([System.Management.Automation.ErrorCategory]::InvalidArgument) $DestinationPath
				}
			}
			else
			{
				$createdItem = New-Item -Path $DestinationPath -ItemType Directory -Confirm:$isConfirm -Verbose:$isVerbose -ErrorAction Stop
				if ($createdItem -ne $null -and $createdItem.PSProvider.Name -ne "FileSystem")
				{
					Remove-Item "$DestinationPath" -Force -Recurse -ErrorAction SilentlyContinue
					$errorMessage = ($LocalizedData.ExpandArchiveInValidDestinationPath -f $DestinationPath)
					ThrowTerminatingErrorHelper "InvalidDirectoryPath" $errorMessage ([System.Management.Automation.ErrorCategory]::InvalidArgument) $DestinationPath
				}

				$resolvedDestinationPath = GetResolvedPathHelper $DestinationPath $true $PSCmdlet
			}
		}

		$isWhatIf = $psboundparameters.ContainsKey("WhatIf")
		if (!$isWhatIf)
		{
			$preparingToExpandVerboseMessage = ($LocalizedData.PreparingToExpandVerboseMessage)
			Write-Verbose $preparingToExpandVerboseMessage

			$progressBarStatus = ($LocalizedData.ExpandProgressBarText -f $DestinationPath)
			ProgressBarHelper "Expand-Archive" $progressBarStatus 0 100 100 1
		}
	}
	PROCESS
	{
		switch ($PsCmdlet.ParameterSetName)
		{
			"Path"
			{
				$resolvedSourcePaths = GetResolvedPathHelper $Path $false $PSCmdlet

				if ($resolvedSourcePaths.Count -gt 1)
				{
					$errorMessage = ($LocalizedData.InvalidArchiveFilePathError -f $Path, $PsCmdlet.ParameterSetName, $PsCmdlet.ParameterSetName)
					ThrowTerminatingErrorHelper "InvalidArchiveFilePath" $errorMessage ([System.Management.Automation.ErrorCategory]::InvalidArgument) $Path
				}
			}
			"LiteralPath"
			{
				$resolvedSourcePaths = GetResolvedPathHelper $LiteralPath $true $PSCmdlet

				if ($resolvedSourcePaths.Count -gt 1)
				{
					$errorMessage = ($LocalizedData.InvalidArchiveFilePathError -f $LiteralPath, $PsCmdlet.ParameterSetName, $PsCmdlet.ParameterSetName)
					ThrowTerminatingErrorHelper "InvalidArchiveFilePath" $errorMessage ([System.Management.Automation.ErrorCategory]::InvalidArgument) $LiteralPath
				}
			}
		}

		ValidateArchivePathHelper $resolvedSourcePaths

		if ($pscmdlet.ShouldProcess($resolvedSourcePaths))
		{
			$expandedItems = @()

			try
			{
				
				
				
				
				
				$isArchiveFileProcessingComplete = $false

				
				
				
				
				if (!$isDestinationPathProvided)
				{
					$archiveFile = New-Object System.IO.FileInfo $resolvedSourcePaths
					$resolvedDestinationPath = Join-Path -Path $resolvedDestinationPath -ChildPath $archiveFile.BaseName
					$destinationPathExists = Test-Path -LiteralPath $resolvedDestinationPath -PathType Container

					if (!$destinationPathExists)
					{
						New-Item -Path $resolvedDestinationPath -ItemType Directory -Confirm:$isConfirm -Verbose:$isVerbose -ErrorAction Stop | Out-Null
					}
				}

				ExpandArchiveHelper $resolvedSourcePaths $resolvedDestinationPath ([ref]$expandedItems) $Force $isVerbose $isConfirm

				$isArchiveFileProcessingComplete = $true
			}
			finally
			{
				
				
				if ($isArchiveFileProcessingComplete -eq $false)
				{
					if ($expandedItems.Count -gt 0)
					{
						
						
						$expandedItems | ForEach-Object { Remove-Item $_ -Force -Recurse }
					}
				}
			}
		}
	}
}

function Write-LocalMessage
{
    [CmdletBinding()]
    Param (
        [string]$Message
    )

    if (Test-Path function:Write-PSFMessage) { Write-PSFMessage -Level Important -Message $Message }
    else { Write-Host $Message }
}


try
{
	[System.Net.ServicePointManager]::SecurityProtocol = "Tls12"

	Write-LocalMessage -Message "Downloading repository from '$($BaseUrl)/archive/$($Branch).zip'"
	Invoke-WebRequest -Uri "$($BaseUrl)/archive/$($Branch).zip" -UseBasicParsing -OutFile "$($env:TEMP)\$($ModuleName).zip" -ErrorAction Stop
	
	Write-LocalMessage -Message "Creating temporary project folder: '$($env:TEMP)\$($ModuleName)'"
	$null = New-Item -Path $env:TEMP -Name $ModuleName -ItemType Directory -Force -ErrorAction Stop
	
	Write-LocalMessage -Message "Extracting archive to '$($env:TEMP)\$($ModuleName)'"
	Expand-Archive -Path "$($env:TEMP)\$($ModuleName).zip" -DestinationPath "$($env:TEMP)\$($ModuleName)" -ErrorAction Stop
	
	$basePath = Get-ChildItem "$($env:TEMP)\$($ModuleName)\*" | Select-Object -First 1
	if ($SubFolder) { $basePath = "$($basePath)\$($SubFolder)" }
	
	
	$manifest = "$($basePath)\$($ModuleName).psd1"
	$manifestData = Invoke-Expression ([System.IO.File]::ReadAllText($manifest))
	$moduleVersion = $manifestData.ModuleVersion
	Write-LocalMessage -Message "Download concluded: $($ModuleName) | Branch $($Branch) | Version $($moduleVersion)"
	
	
	$path = "$($env:ProgramFiles)\WindowsPowerShell\Modules\$($ModuleName)"
	if ($doUserMode) { $path = "$(Split-Path $profile.CurrentUserAllHosts)\Modules\$($ModuleName)" }
	if ($PSVersionTable.PSVersion.Major -ge 5) { $path += "\$moduleVersion" }
	
	if ((Test-Path $path) -and (-not $Force))
	{
		Write-LocalMessage -Message "Module already installed, interrupting installation"
		return
	}
	
	Write-LocalMessage -Message "Creating folder: $($path)"
	$null = New-Item -Path $path -ItemType Directory -Force -ErrorAction Stop
	
	Write-LocalMessage -Message "Copying files to $($path)"
	foreach ($file in (Get-ChildItem -Path $basePath))
	{
		Move-Item -Path $file.FullName -Destination $path -ErrorAction Stop
	}
	
	Write-LocalMessage -Message "Cleaning up temporary files"
	Remove-Item -Path "$($env:TEMP)\$($ModuleName)" -Force -Recurse
	Remove-Item -Path "$($env:TEMP)\$($ModuleName).zip" -Force
	
	Write-LocalMessage -Message "Installation of the module $($ModuleName), Branch $($Branch), Version $($moduleVersion) completed successfully!"
}
catch
{
	Write-LocalMessage -Message "Installation of the module $($ModuleName) failed!"
	
	Write-LocalMessage -Message "Cleaning up temporary files"
	Remove-Item -Path "$($env:TEMP)\$($ModuleName)" -Force -Recurse
	Remove-Item -Path "$($env:TEMP)\$($ModuleName).zip" -Force
	
	throw
}