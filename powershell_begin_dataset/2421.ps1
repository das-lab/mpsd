



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