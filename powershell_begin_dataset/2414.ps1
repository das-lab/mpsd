
[CmdletBinding()]
param (
	[Parameter(Mandatory)]
	[string]$Name,
	[Parameter(Mandatory)]
	[string]$Manufacturer,
	[Parameter(Mandatory)]
	[ValidatePattern('[-+]?([0-9]*\.[0-9]+|[0-9]+)')]
	[string]$SoftwareVersion,
	[Parameter()]
	[string]$Owner = 'Adam Bertram',
	[Parameter()]
	[string]$SupportContact = 'Adam Bertram',
	[Parameter(Mandatory)]
	[ValidateScript({ Test-Path -Path $_ -PathType Container })]
	[string]$SourceFolderPath,
	[Parameter(Mandatory)]
	[string]$InstallationProgram,
	[Parameter()]
	[ValidateScript({ Test-Path -Path $_ -PathType Container })]
	[string]$RootPackageFolderPath = '\\server\dfs\softwarelibrary\software_packages',
	[Parameter()]
	[ValidateScript({ Test-Path -Path $_ -PathType 'Leaf' })]
	[string]$IconLocationFilePath,
	[Parameter()]
	[string]$InstallationBehaviorType = 'InstallForSystem',
	[Parameter()]
	[string]$InstallationProgramVisibility = 'Hidden',
	[Parameter()]
	[string]$MaximumAllowedRunTimeMinutes = '15',
	[Parameter()]
	[string]$EstimatedInstallationTimeMinutes = '5',
	[Parameter()]
	[string]$RebootBehavior = 'ForceReboot',
	[Parameter()]
	[string]$DistributionPointGroup = 'All DPs',
	[Parameter()]
	[string]$SiteCode = 'UHP',
	[Parameter()]
	[string]$InstallScriptTemplateFilePath = '\\server\dfs\softwarelibrary\software_packages\_Template_Files\install.ps1'
	
)

begin {
	$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
	Set-StrictMode -Version Latest
	try {
		Write-Verbose 'Ensuring the ConfigurationManager module is available and importing it...'
		
		if (!(Test-Path "$(Split-Path $env:SMS_ADMIN_UI_PATH -Parent)\ConfigurationManager.psd1")) {
			throw 'Configuration Manager module not found.  Is the admin console intalled?'
		} elseif (!(Get-Module 'ConfigurationManager')) {
			Import-Module "$(Split-Path $env:SMS_ADMIN_UI_PATH -Parent)\ConfigurationManager.psd1"
		}
		Write-Verbose 'Performing prereq setup things...'
		$Location = (Get-Location).Path
		
		
		$PackageFolderName = "$($Manufacturer.Replace(' ','_'))_$($Name.Replace(' ','_'))_$($SoftwareVersion.Replace(' ','_'))"
		$ContentFolderPath = "$RootPackageFolderPath\$PackageFolderName"
	} catch {
		Write-Error $_.Exception.Message
	}
}

process {
	try {
		
		
		Write-Verbose "Creating the content folder '$ContentFolderPath'..."
		if (!(Test-Path $ContentFolderPath)) {
			mkdir $ContentFolderPath | Out-Null
		} else {
			throw "The folder at '$ContentFolderPath' already exists."
		}
		
		
		Write-Verbose "Copying files from source folder '$SourceFolderPath' to '$ContentFolderPath'..."
		Copy-Item -Path "$SourceFolderPath\*" -Destination $ContentFolderPath -Recurse -Force
		
		
		Write-Verbose "Copying the installer template fiel at '$InstallScriptTemplateFilePath' to '$ContentFolderPath'..."
		Copy-Item -Path $InstallScriptTemplateFilePath -Destination $ContentFolderPath
		
		
		Write-Verbose "Creating the application '$Name'..."
		$NewCmApplicationParams = @{
			'Name' = $Name;
			'Owner' = $Owner;
			'SupportContact' = $SupportContact;
			'IconLocationFile' = $IconLocationFilePath;
			'Publisher' = $Manufacturer;
			'SoftwareVersion' = $SoftwareVersion
		}
		Set-Location "$($SiteCode):"
		New-CMApplication @NewCmApplicationParams | Out-Null
		
		
		Write-Verbose 'Creating the deployment type...'
		$AddCmDeploymentTypeParams = @{
			'ApplicationName' = $ApplicationName;
			'ScriptInstaller' = $true;
			'ManualSpecifyDeploymentType' = $true;
			'DeploymentTypeName' = "Deploy $Name";
			'InstallationProgram' = $InstallationProgram;
			'ContentLocation' = $ContentFolderPath;
			
			
			'InstallationBehaviorType' = $InstallationBehaviorType;
			'InstallationProgramVisibility' = $InstallationProgramVisibility;
			'MaximumAllowedRunTimeMinutes' = $MaximumAllowedRunTimeMinutes;
			'EstimatedInstallationTimeMinutes' = $EstimatedInstallationTimeMinutes;
			
			
			
		}
		Add-CMDeploymentType @AddCmDeploymentTypeParams
		
		
		Write-Verbose 'Setting reboot behavior for the deployment type...'
		$SetCmDeploymentTypeParams = @{
			'RebootBehavior' = $RebootBehavior;
			'DeploymentTypeName' = "Deploy $ApplicationName";
			'ApplicationName' = $ApplicationName;
			'MsiOrScriptInstaller' = $true;
		}
		Set-CMDeploymentType @SetCmDeploymentTypeParams
		
		
		Write-Verbose 'Distributing content...'
		Start-CMContentDistribution -DistributionPointGroupName $DistributionPointGroup -PackageName $Name
		
		
		Write-Verbose 'Creating the OSD package...'
		$PackageConversionScriptFilePath = 'C:\Dropbox\Powershell\scripts\complete\Convert-CMApplicationToPackage.ps1'
		if (Test-Path $PackageConversionScriptFilePath) {
			& $PackageConversionScriptFilePath -ApplicationName $Name -SkipRequirements -DistributeContent -OsdFriendlyPowershellSyntax
		} else {
			Write-Warning "OSD package could not be created because the script '$PackageConversionScriptFilePath' does not exist"
		}
		
		Write-Verbose 'Done.'
		
		
	} catch {
		Write-Error $_.Exception.Message
		exit
	}
}