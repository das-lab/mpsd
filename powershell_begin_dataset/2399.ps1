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
	begin
	{
		function Test-UncPath
		{
			[CmdletBinding()]
			[OutputType([bool])]
			param
			(
				[Parameter(Mandatory)]
				[ValidateNotNullOrEmpty()]
				[string]$Path
				
			)
			process
			{
				if ($Path -like '\\*')
				{
					$true
				}
				else
				{
					$false
				}
			}
		}
	}
	process
	{
		foreach ($p in $Path)
		{
			try
			{
				if (Test-UncPath -Path $p)
				{
					Write-Verbose -Message "[$($p)] is a UNC path. Copying locally first"
					Copy-Item -Path $p -Destination ([environment]::GetEnvironmentVariable('TEMP', 'Machine')) -Force -Recurse
					$p = "$([environment]::GetEnvironmentVariable('TEMP', 'Machine'))\$($p | Split-Path -Leaf)"
				}
				if (Test-Path -Path $p -PathType Container)
				{
					Write-Verbose -Message "[$($p)] is a folder. Sending all files"
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
				throw $_
			}
		}
	}
	
}

function Test-LocalComputer
{
	
	
	[CmdletBinding()]
	[OutputType([bool])]
	param
	(
		[Parameter(Mandatory)]
		[string]$ComputerName
	)
	begin
	{
		$LocalComputerLabels = @(
		'.',
		'localhost',
		[System.Net.Dns]::GetHostName(),
		[System.Net.Dns]::GetHostEntry('').HostName
		)
	}
	process
	{
		try
		{
			if ($LocalComputerLabels -contains $ComputerName)
			{
				Write-Verbose -Message "The computer reference [$($ComputerName)] is a local computer"
				$true
			}
			else
			{
				Write-Verbose -Message "The computer reference [$($ComputerName)] is a remote computer"
				$false
			}
		}
		catch
		{
			throw $_
		}
	}
}

function Import-CertificateSigningRequestResponse
{
	
	[CmdletBinding()]
	param
	(
		
		[Parameter(Mandatory)]
		[ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
		[string]$FilePath,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('Machine', 'User')]
		[string]$CertificateLocation = 'Machine',
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName = $env:COMPUTERNAME,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[pscredential]$Credential,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$CertReqFilePath = "$env:SystemRoot\system32\certreq.exe"
	)
	process
	{
		try
		{
			if (-not (Test-LocalComputer -ComputerName $ComputerName))
			{
				$sessParams = @{
					'ComputerName' = $ComputerName
				}
				
				$remoteFilePath = "C:\$([System.IO.Path]::GetFileName($FilePath))"
				$session = New-PSSession @sessParams
				
				$null = Send-File -Session $session -Path $FilePath -Destination 'C:\'
				
				Invoke-Command -Session $session -ScriptBlock { Start-Process -FilePath $using:CertReqFilePath -Args "-accept -$using:CertificateLocation `"$using:remoteFilePath`""}
			}
			else
			{
				Start-Process -FilePath $CertReqFilePath -Args "-accept -$CertificateLocation `"$FilePath`"" -Wait -NoNewWindow
			}
		}
		catch
		{
			throw $_
		}
		finally
		{
			Invoke-Command -Session $session -ScriptBlock {Remove-Item -Path $using:remoteFilePath -ErrorAction Ignore}
			Remove-PSSession -Session $session -ErrorAction Ignore
		}
	}
}