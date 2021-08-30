function Send-File
{
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string[]]$Path,
		
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$Destination,
		
		[Parameter(Mandatory)]
		[System.Management.Automation.Runspaces.PSSession]$Session
	)
	process
	{
		foreach ($p in $Path)
		{
			try
			{
				if ($p.StartsWith('\\'))
				{
					Write-Verbose -Message "[$($p)] is a UNC path. Copying locally first"
					Copy-Item -Path $p -Destination ([environment]::GetEnvironmentVariable('TEMP', 'Machine'))
					$p = "$([environment]::GetEnvironmentVariable('TEMP', 'Machine'))\$($p | Split-Path -Leaf)"
				}
				if (Test-Path -Path $p -PathType Container)
				{
					Write-Log -Source $MyInvocation.MyCommand -Message "[$($p)] is a folder. Sending all files"
					$files = Get-ChildItem -Path $p -File -Recurse
					$sendFileParamColl = @()
					foreach ($file in $Files)
					{
						$sendParams = @{
							'Session' = $Session
							'Path' = $file.FullName
						}
						if ($file.DirectoryName -ne $p) 
						{
							$subdirpath = $file.DirectoryName.Replace("$p\", '')
							$sendParams.Destination = "$Destination\$subDirPath"
						}
						else
						{
							$sendParams.Destination = $Destination
						}
						$sendFileParamColl += $sendParams
					}
					foreach ($paramBlock in $sendFileParamColl)
					{
						Send-File @paramBlock
					}
				}
				else
				{
					Write-Verbose -Message "Starting WinRM copy of [$($p)] to [$($Destination)]"
					
					$sourceBytes = [System.IO.File]::ReadAllBytes($p);
					$streamChunks = @();
					
					
					$streamSize = 1MB;
					for ($position = 0; $position -lt $sourceBytes.Length; $position += $streamSize)
					{
						$remaining = $sourceBytes.Length - $position
						$remaining = [Math]::Min($remaining, $streamSize)
						
						$nextChunk = New-Object byte[] $remaining
						[Array]::Copy($sourcebytes, $position, $nextChunk, 0, $remaining)
						$streamChunks +=, $nextChunk
					}
					$remoteScript = {
						if (-not (Test-Path -Path $using:Destination -PathType Container))
						{
							$null = New-Item -Path $using:Destination -Type Directory -Force
						}
						$fileDest = "$using:Destination\$($using:p | Split-Path -Leaf)"
						
						$destBytes = New-Object byte[] $using:length
						$position = 0
						
						
						foreach ($chunk in $input)
						{
							[GC]::Collect()
							[Array]::Copy($chunk, 0, $destBytes, $position, $chunk.Length)
							$position += $chunk.Length
						}
						
						[IO.File]::WriteAllBytes($fileDest, $destBytes)
						
						Get-Item $fileDest
						[GC]::Collect()
					}
					
					
					$Length = $sourceBytes.Length
					$streamChunks | Invoke-Command -Session $Session -ScriptBlock $remoteScript
					Write-Verbose -Message "WinRM copy of [$($p)] to [$($Destination)] complete"
				}
			}
			catch
			{
				Write-Error $_.Exception.Message
			}
		}
	}
	
}