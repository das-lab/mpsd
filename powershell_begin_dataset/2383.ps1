function Install-SqlServerCumulativeUpdate
{
	[CmdletBinding(SupportsShouldProcess)]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName,
		
		[Parameter(Mandatory, ParameterSetName = 'Number')]
		[ValidateNotNullOrEmpty()]
		[int]$Number,
		
		[Parameter(Mandatory, ParameterSetName = 'Latest')]
		[ValidateNotNullOrEmpty()]
		[switch]$Latest,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[switch]$Restart
	)
	process {
		try
		{
			if (Test-PendingReboot -ComputerName $ComputerName)
			{
				throw "The computer [$($ComputerName)] is pending a reboot. Reboot the computer before proceeding."
			}
			
			
			$currentVersion = Get-SQLServerVersion -ComputerName $ComputerName
			
			
			
			$arch = (Get-CimInstance -ComputerName $ComputerName -ClassName 'Win32_ComputerSystem' -Property 'SystemType').SystemType
			if ($arch -eq 'x64-based PC')
			{
				$arch = 'x64'
			}
			else
			{
				$arch = 'x86'
			}
			
			
			$params = @{
				'Architecture' = $arch
				'SqlServerVersion' = $currentVersion.MajorVersion
				'ServicePackNumber' = $currentVersion.ServicePack
			}
			if ($PSBoundParameters.ContainsKey('Number'))
			{
				$params.CumulativeUpdateNumber = $Number
			}
			elseif ($Latest.IsPresent)
			{
				$params.CumulativeUpdateNumber = (Get-LatestSqlServerCumulativeUpdateVersion -SqlServerVersion $currentVersion.MajorVersion -ServicePackNumber $currentVersion.ServicePack).CumulativeUpdate
			}
			
			if ($currentVersion.CumulativeUpdate -eq $params.CumulativeUpdateNumber)
			{
				throw "The computer [$($ComputerName)] already has the specified (or latest) cumulative update installed."
			}
			
			if (-not ($installer = Find-SqlServerCumulativeUpdateInstaller @params))
			{
				throw "Could not find installer for cumulative update [$($params.CumulativeUpdateNumber)]"
			}
			
			
			if ($PSCmdlet.ShouldProcess($ComputerName, "Install cumulative update [$($installer.Name)] for SQL Server [$($currentVersion.MajorVersion)]"))
			{
				$invProgParams = @{
					'ComputerName' = $ComputerName
					'Credential' = $Credential
				}
				
				$spExtractPath = 'C:\Windows\Temp\SQLCU'
				Invoke-Program @invProgParams -FilePath $installer.FullName -ArgumentList "/extract:`"$spExtractPath`" /quiet"
				
				
				Invoke-Program @invProgParams -FilePath "$spExtractPath\setup.exe" -ArgumentList '/quiet /allinstances'
				
				if ($Restart.IsPresent)
				{
					Restart-Computer -ComputerName $ComputerName -Wait -For WinRm -Force
				}
				
			}
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}

function TestSqlServerServicePack
{
	
	[OutputType([bool])]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[int]$ServicePackNumber
	)
	process {
		try
		{
			$currentVersion = Get-SQLServerVersion -ComputerName $ComputerName
			if ($currentVersion.ServicePack -lt $ServicePackNumber)
			{
				Write-Verbose -Message "The server [$($ComputerName)'s'] service pack [$($currentVersion.ServicePack)] is older than [$($ServicePackNumber)]"
				$false
			}
			else
			{
				Write-Verbose -Message "The server [$($ComputerName)'s'] service pack [$($currentVersion.ServicePack)] is newer or equal to [$($ServicePackNumber)]"
				$true
			}
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}

function Install-SqlServerServicePack
{
	
	[OutputType([void])]
	[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Latest')]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName,
		
		[Parameter(Mandatory, ParameterSetName = 'Number')]
		[ValidateNotNullOrEmpty()]
		[ValidateRange(1, 5)]
		[int]$Number,
		
		[Parameter(Mandatory, ParameterSetName = 'Latest')]
		[ValidateNotNullOrEmpty()]
		[switch]$Latest,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[switch]$Restart
	)
	process
	{
		try
		{
			
			$currentVersion = Get-SQLServerVersion -ComputerName $ComputerName
			
			
			if ($Latest.IsPresent)
			{
				$Number = (Get-LatestSqlServerServicePackVersion -SqlServerVersion $currentVersion.MajorVersion).ServicePack
			}
			
			
			$connParams = @{
				'ComputerName' = $ComputerName
			}
				
			Write-Verbose -Message "Installing SP on [$($ComputerName)]"
			
			
			
			$arch = (Get-CimInstance -ComputerName $ComputerName -ClassName 'Win32_ComputerSystem' -Property 'SystemType').SystemType
			if ($arch -eq 'x64-based PC')
			{
				$arch = 'x64'
			}
			else
			{
				$arch = 'x86'
			}
			
			
			$params = @{
				'Architecture' = $arch
				'SqlServerVersion' = $currentVersion.MajorVersion
				'Number' = $Number
			}
			
			if (TestSqlServerServicePack -ComputerName $ComputerName -ServicePackNumber $Number)
			{
				Write-Verbose -Message "The computer [$($ComputerName)] already has the specified (or latest) service pack installed."
			}
			else
			{
				if (-not ($installer = Find-SqlServerServicePackInstaller @params))
				{
					throw "Could not find installer for service pack [$($Number)] for version [$($currentVersion.MajorVersion)]"
				}
				
				if (Test-PendingReboot @connParams)
				{
					throw "The computer [$($ComputerName)] is pending a reboot. Reboot the computer before proceeding."
				}
				
				
				if ($PSCmdlet.ShouldProcess($ComputerName, "Install service pack [$($installer.Name)] for SQL Server [$($currentVersion.MajorVersion)]"))
				{
					$spExtractPath = 'C:\Windows\Temp\SQLSP'
					Invoke-Program @connParams -FilePath $installer.FullName -ArgumentList "/extract:`"$spExtractPath`" /quiet"
					
					
					Invoke-Program @connParams -FilePath "$spExtractPath\setup.exe" -ArgumentList '/q /allinstances'
					
					if ($Restart.IsPresent)
					{
						Restart-Computer @connParams -Wait -Force
					}
				}
			}
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
		finally
		{
			if ((Test-Path -Path Variable:\spExtractPath) -and $spExtractPath)
			{
				
				Invoke-Command @connParams -ScriptBlock { Remove-Item -Path $using:spExtractPath -Recurse -Force -ErrorAction SilentlyContinue }
			}
		}
	}
}

function Get-SQLServerVersion
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName
	)
	process
	{
		try
		{
			$sqlInstance = Get-SQLInstance -ComputerName $ComputerName
			if (-not $sqlInstance)
			{
				throw 'Server query failed.'
			}
			else
			{
				$currentVersion = ConvertTo-VersionObject -Version $sqlInstance.Version
				$currentVersion | Add-Member -Name 'Edition' -MemberType NoteProperty -Value $sqlInstance.Edition
				$currentVersion
			}
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}

function ConvertTo-VersionObject
{
	
	[OutputType([System.Management.Automation.PSCustomObject])]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[version]$Version
	)
	process
	{
		try
		{
			$impCsvParams = @{
				'Path' = "$PSScriptRoot\sqlversions.csv"
			}

			$filterScript = { $_.FullVersion -le "$($Version.Major).00.$($Version.Build)" }

			$selectParams = @{
				'Last' = 1
				'Property' = '*', @{ Name = 'ServicePack'; Expression = { if ($_.ServicePack -eq 0) { $null } else { $_.ServicePack} } }
				'ExcludeProperty' = 'ServicePack'

			}
			(Import-Csv @impCsvParams | Sort-Object FullVersion).Where($filterScript) | Select-Object @selectParams
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}

function Get-SQLInstance
{

	
	[CmdletBinding()]
	param
	(
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias('__Server', 'DNSHostName', 'IPAddress')]
		[string[]]$ComputerName = $Env:COMPUTERNAME,
		
		[Parameter()]
		[ValidateSet('SSDS', 'SSAS', 'SSRS')]
		[string[]]$Component = @('SSDS', 'SSAS', 'SSRS')
	)
	
	begin
	{
		$componentNameMap = @(
			[pscustomobject]@{
				ComponentName	= 'SSAS';
				DisplayName		= 'Analysis Services';
				RegKeyName		= "OLAP";
			},
			[pscustomobject]@{
				ComponentName	= 'SSDS';
				DisplayName		= 'Database Engine';
				RegKeyName		= 'SQL';
			},
			[pscustomobject]@{
				ComponentName	= 'SSRS';
				DisplayName		= 'Reporting Services';
				RegKeyName		= 'RS';
			}
		);
	}
	
	process
	{
		foreach ($computer in $ComputerName)
		{
			try
			{
				
				$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer);
				$baseKeys = "SOFTWARE\\Microsoft\\Microsoft SQL Server", "SOFTWARE\\Wow6432Node\\Microsoft\\Microsoft SQL Server";
				if ($reg.OpenSubKey($baseKeys[0]))
				{
					$regPath = $baseKeys[0];
				}
				elseif ($reg.OpenSubKey($baseKeys[1]))
				{
					$regPath = $baseKeys[1];
				}
				else
				{
					continue;
				}
				
				
				
				$computer = $computer -replace '(.*?)\..+', '$1';
				
				$regKey = $reg.OpenSubKey("$regPath");
				if ($regKey.GetSubKeyNames() -contains "Instance Names")
				{
					foreach ($componentName in $Component)
					{
						$componentRegKeyName = $componentNameMap |
						Where-Object { $_.ComponentName -eq $componentName } |
						Select-Object -ExpandProperty RegKeyName;
						$regKey = $reg.OpenSubKey("$regPath\\Instance Names\\{0}" -f $componentRegKeyName);
						if ($regKey)
						{
							foreach ($regValueName in $regKey.GetValueNames())
							{
								Get-SQLInstanceDetail -RegPath $regPath -Reg $reg -RegKey $regKey -Instance $regValueName;
							}
						}
					}
				}
				elseif ($regKey.GetValueNames() -contains 'InstalledInstances')
				{
					$isCluster = $false;
					$regKey.GetValue('InstalledInstances') | ForEach-Object {
						Get-SQLInstanceDetail -RegPath $regPath -Reg $reg -RegKey $regKey -Instance $_;
					};
				}
				else
				{
					continue;
				}
			}
			catch
			{
				Write-Error ("{0}: {1}" -f $computer, $_.Exception.ToString());
			}
		}
	}
}

function Get-SQLInstanceDetail
{
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[string[]]$Instance,
		
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[Microsoft.Win32.RegistryKey]$RegKey,
		
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[Microsoft.Win32.RegistryKey]$reg,
		
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$RegPath
	)
	process
	{
		
		foreach ($sqlInstance in $Instance)
		{
			$nodes = New-Object System.Collections.ArrayList;
			$clusterName = $null;
			$isCluster = $false;
			$instanceValue = $regKey.GetValue($sqlInstance);
			$instanceReg = $reg.OpenSubKey("$regPath\\$instanceValue");
			if ($instanceReg.GetSubKeyNames() -contains 'Cluster')

			{
				$isCluster = $true;
				$instanceRegCluster = $instanceReg.OpenSubKey('Cluster');
				$clusterName = $instanceRegCluster.GetValue('ClusterName');
				Write-Verbose -Message "Getting cluster node names";
				$clusterReg = $reg.OpenSubKey("Cluster\\Nodes");
				$clusterNodes = $clusterReg.GetSubKeyNames();
				if ($clusterNodes)
				{
					foreach ($clusterNode in $clusterNodes)
					{
						$null = $nodes.Add($clusterReg.OpenSubKey($clusterNode).GetValue("NodeName").ToUpper());
					}
				}
			}
			
			
			$instanceRegSetup = $instanceReg.OpenSubKey("Setup")
			
			
			try
			{
				$instanceDir = $instanceRegSetup.GetValue("SqlProgramDir");
				if (([System.IO.Path]::GetPathRoot($instanceDir) -ne $instanceDir) -and $instanceDir.EndsWith("\"))
				{
					$instanceDir = $instanceDir.Substring(0, $instanceDir.Length - 1);
				}
			}
			catch
			{
				$instanceDir = $null;
			}
			
			
			
			try
			{
				$edition = $instanceRegSetup.GetValue("Edition");
			}
			catch
			{
				$edition = $null;
			}
			
			
			
			try
			{
				
				$version = $instanceRegSetup.GetValue("Version");
				if ($version.Split('.')[0] -eq '11')
				{
					$verKey = $reg.OpenSubKey('SOFTWARE\\Microsoft\\Microsoft SQL Server\\110\\SQLServer2012\\CurrentVersion')
					$version = $verKey.GetValue('Version')
				}
				elseif ($version.Split('.')[0] -eq '12')
				{
					$verKey = $reg.OpenSubKey('SOFTWARE\\Microsoft\\Microsoft SQL Server\\120\\SQLServer2014\\CurrentVersion')
					$version = $verKey.GetValue('Version')
				}
			}
			catch
			{
				$version = $null;
			}
			
			
			
			
			
			[pscustomobject]@{
				ComputerName = $computer.ToUpper();
				InstanceType = {
					$componentNameMap | Where-Object { $_.ComponentName -eq $componentName } |
					Select-Object -ExpandProperty DisplayName
				}.InvokeReturnAsIs();
				InstanceName = $sqlInstance;
				InstanceID = $instanceValue;
				InstanceDir = $instanceDir;
				Edition = $edition;
				Version = $version;
				Caption = {
					switch -regex ($version)
					{
						"^11"		{ "SQL Server 2012"; break }
						"^10\.5"	{ "SQL Server 2008 R2"; break }
						"^10"		{ "SQL Server 2008"; break }
						"^9"		{ "SQL Server 2005"; break }
						"^8"		{ "SQL Server 2000"; break }
						default { "Unknown"; }
					}
				}.InvokeReturnAsIs();
				IsCluster = $isCluster;
				IsClusterNode = ($nodes -contains $computer);
				ClusterName = $clusterName;
				ClusterNodes = ($nodes -ne $computer);
				FullName = {
					if ($sqlInstance -eq "MSSQLSERVER")
					{
						$computer.ToUpper();
					}
					else
					{
						"$($computer.ToUpper())\$($sqlInstance)";
					}
				}.InvokeReturnAsIs();
			}
			
		}
		
	}
}

function Test-PendingReboot
{
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[pscredential]$Credential
	)
	process {
		try
		{
			$icmParams = @{
				'ComputerName' = $ComputerName
			}
			if ($PSBoundParameters.ContainsKey('Credential')) {
				$icmParams.Credential = $Credential
			}
			
			$OperatingSystem = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_OperatingSystem -Property BuildNumber, CSName
			
			
			If ($OperatingSystem.BuildNumber -ge 6001)
			{
				$PendingReboot = Invoke-Command @icmParams -ScriptBlock { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing' -Name 'RebootPending' -ErrorAction SilentlyContinue }
				if ($PendingReboot)
				{
					Write-Verbose -Message 'Reboot pending detected in the Component Based Servicing registry key'
					return $true
				}
			}
			
			
			$PendingReboot = Invoke-Command @icmParams -ScriptBlock { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -Name 'RebootRequired' -ErrorAction SilentlyContinue }
			if ($PendingReboot)
			{
				Write-Verbose -Message 'WUAU has a reboot pending'
				return $true
			}
			
			
			$PendingReboot = Invoke-Command @icmParams -ScriptBlock { Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue }
			if ($PendingReboot -and $PendingReboot.PendingFileRenameOperations)
			{
				Write-Verbose -Message 'Reboot pending in the PendingFileRenameOperations registry value'
				return $true
			}
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}

function Find-SqlServerServicePackInstaller
{
	[CmdletBinding(DefaultParameterSetName = 'Latest')]
	[OutputType('System.IO.FileInfo')]
	param
	(
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('2008R2', '2012', '2014')]
		[string]$SqlServerVersion,
		
		[Parameter(ParameterSetName = 'Specific')]
		[ValidateNotNullOrEmpty()]
		[ValidateRange(1, 5)]
		[int]$Number,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('x86', 'x64')]
		[string]$Architecture = 'x64',
		
		[Parameter(ParameterSetName = 'Latest')]
		[ValidateNotNullOrEmpty()]
		[switch]$Latest,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$SqlServerInstallerBasePath = '\\SOme\unc\path\here'
		
	)
	process
	{
		try
		{
			
			
			$servicePacks = Get-ChildItem -Path $SqlServerInstallerBasePath | Where-Object { $_.Name -match '^\d{4}' } | Get-ChildItem -Filter 'Updates' | Get-ChildItem -Filter 'SQLServer*-SP?-*.exe'
			
			if ($PSBoundParameters.ContainsKey('SqlServerVersion'))
			{
				$filter = 'SQLServer{0}' -f $SqlServerVersion
			}
			
			if ($PSBoundParameters.ContainsKey('Number'))
			{
				$filter += '-SP{0}-' -f $Number
			}
			
			if ($PSBoundParameters.ContainsKey('Architecture'))
			{
				$filter += '(.+)?{0}\.exe$' -f $Architecture
			}
			Write-Verbose -Message "Using filter [$($filter)]..."
			
			if ($filter)
			{
				$servicePacks = @($servicePacks).Where{ $_.Name -match $filter }
			}
			
			if ($Latest.IsPresent)
			{
				$servicePacks | Sort-Object { $_.Name } -Descending | Select-Object -First 1
			}
			else
			{
				$servicePacks
			}
			
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}

function Find-SqlServerCumulativeUpdateInstaller
{
	[CmdletBinding(DefaultParameterSetName = 'Latest')]
	[OutputType('System.IO.FileInfo')]
	param
	(
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('2008R2', '2012', '2014')]
		[string]$SqlServerVersion,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidateRange(1, 5)]
		[int]$ServicePackNumber,
		
		[Parameter(ParameterSetName = 'Specific')]
		[ValidateNotNullOrEmpty()]
		[int]$CumulativeUpdateNumber,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('x86', 'x64')]
		[string]$Architecture = 'x64',
		
		[Parameter(ParameterSetName = 'Latest')]
		[ValidateNotNullOrEmpty()]
		[switch]$Latest,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$SqlServerInstallerBasePath = '\\some\unc\path\here'
		
	)
	process
	{
		try
		{
			
			
			$cumulUpdates = Get-ChildItem -Path $SqlServerInstallerBasePath | Where-Object { $_.Name -match '^\d{4}' } | Get-ChildItem -Filter 'Updates' | Get-ChildItem -Filter 'SQLServer*-SP?CU*.exe'
			
			if ($PSBoundParameters.ContainsKey('SqlServerVersion'))
			{
				$filter = 'SQLServer{0}' -f $SqlServerVersion
			}
			
			if ($PSBoundParameters.ContainsKey('ServicePackNumber'))
			{
				$filter += '-SP{0}' -f $ServicePackNumber
			}
			
			if ($PSBoundParameters.ContainsKey('CumulativeUpdateNumber'))
			{
				$filter += 'CU{0}.+' -f ([string]$CumulativeUpdateNumber).PadLeft(2, '0')
			}
			
			if ($PSBoundParameters.ContainsKey('Architecture'))
			{
				$filter += '(.+)?{0}\.exe$' -f $Architecture
			}
			Write-Verbose -Message "Using filter [$($filter)]..."
			
			if (-not $filter)
			{
				$cumulUpdates
			}
			else
			{
				@($cumulUpdates).Where{ $_.Name -match $filter }
			}
			
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}

function Get-LatestSqlServerCumulativeUpdateVersion
{
	[OutputType([pscustomobject])]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('2008R2', '2012', '2014')]
		[string]$SqlServerVersion,
		
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateRange(1, 5)]
		[int]$ServicePackNumber
	)
	process
	{
		try
		{
			(Import-Csv -Path "$PSScriptRoot\sqlversions.csv").where({
				$_.MajorVersion -eq $SqlServerVersion -and $_.ServicePack -eq $ServicePackNumber
			}) | sort-object { [int]$_.cumulativeupdate } -Descending | Select-Object -first 1
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}

function Get-LatestSqlServerServicePackVersion
{
	[OutputType([pscustomobject])]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('2008R2', '2012', '2014')]
		[string]$SqlServerVersion
	)
	process
	{
		try
		{
			(Import-Csv -Path "$PSScriptRoot\sqlversions.csv").where({ $_.MajorVersion -eq $SqlServerVersion }) | sort-object servicepack -Descending | Select-Object -first 1
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}

function Update-SqlServer
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidateSet(1, 2, 3, 4, 5, 'Latest')]
		[string]$ServicePack = 'Latest',
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidateSet(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 'Latest')]
		[string]$CumulativeUpdate = 'Latest',
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[pscredential]$Credential
	)
	process {
		try
		{
			$spParams = @{
				'ComputerName' = $ComputerName
				'Restart' = $true	
			}
			if ($ServicePack -eq 'Latest')
			{
				$spParams.Latest = $true
			}
			else
			{
				$spParams.Number = $ServicePack	
			}
			Install-SqlServerServicePack @spParams
				
			$cuParams = @{
				'ComputerName' = $ComputerName
				'Restart' = $true
			}
			if ($CumulativeUpdate -eq 'Latest')
			{
				$cuParams.Latest = $true
			}
			else
			{
				$cuParams.Number = $CumulativeUpdate
			}
			Install-SqlServerCumulativeUpdate @cuParams
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}

function Invoke-Program
{
	[CmdletBinding()]
	[OutputType([System.Management.Automation.PSObject])]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$FilePath,

		[Parameter()]
		[string]$ComputerName = 'localhost',

		[Parameter()]
		[pscredential]$Credential,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$ArgumentList,

		[Parameter()]
		[bool]$ExpandStrings = $false,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$WorkingDirectory,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[uint32[]]$SuccessReturnCodes = @(0, 3010)
	)
	process
	{
		try
		{
			
			$null = Clear-DNSClientCache;
			
			$icmParams = @{
				ComputerName = $ComputerName;
			}

			$icmParams.Authentication = 'CredSSP'
			if ($PSBoundParameters.ContainsKey('Credential'))
			{
				$icmParams.Credential = $Credential	
			}
			
			Write-Verbose -Message "Acceptable success return codes are [$($SuccessReturnCodes -join ',')]"
			
			$icmParams.ScriptBlock = {
				$VerbosePreference = $using:VerbosePreference
				
				try
				{
					$processStartInfo = New-Object System.Diagnostics.ProcessStartInfo;
					$processStartInfo.FileName = $Using:FilePath;
					if ($Using:ArgumentList)
					{
						$processStartInfo.Arguments = $Using:ArgumentList;
						if ($Using:ExpandStrings)
						{
							$processStartInfo.Arguments = $ExecutionContext.InvokeCommand.ExpandString($Using:ArgumentList);
						}
					}
					if ($Using:WorkingDirectory)
					{
						$processStartInfo.WorkingDirectory = $Using:WorkingDirectory;
						if ($Using:ExpandStrings)
						{
							$processStartInfo.WorkingDirectory = $ExecutionContext.InvokeCommand.ExpandString($Using:WorkingDirectory);
						}
					}
					$processStartInfo.UseShellExecute = $false; 
					$ps = New-Object System.Diagnostics.Process;
					$ps.StartInfo = $processStartInfo;
					Write-Verbose -Message "Starting process path [$($processStartInfo.FileName)] - Args: [$($processStartInfo.Arguments)] - Working dir: [$($Using:WorkingDirectory)]"
					$null = $ps.Start();
					$ps.WaitForExit();
					
					
					if ($ps.ExitCode -notin $Using:SuccessReturnCodes)
					{
						throw "Error running program: $($ps.ExitCode)";
					}
				}
				catch
				{
					Write-Error $_.Exception.ToString();
				}
			}
			
			
			Write-Verbose -Message "Running command line [$FilePath $ArgumentList] on $ComputerName";
			
			$params = @{
				'ComputerName' = $ComputerName
				'Credential' = $Credential
			}
			$result = Invoke-Command @icmParams
			
			
			if ($err)
			{
				throw $err;
			}
		}
		catch
		{
			Write-Error -Message $_.Exception.Message
		}
	}
}