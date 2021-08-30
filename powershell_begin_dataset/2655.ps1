
[CmdletBinding()]
Param (
    [switch]$RelaunchToolkitAsUser = $false
)






[string]$appDeployToolkitExtName = 'PSAppDeployToolkitExt'
[string]$appDeployExtScriptFriendlyName = 'App Deploy Toolkit Extensions'
[version]$appDeployExtScriptVersion = [version]'1.5.0'
[string]$appDeployExtScriptDate = '11/02/2014'
[hashtable]$appDeployExtScriptParameters = $PSBoundParameters















If (-not $RelaunchToolkitAsUser) {
	If (-not [string]::IsNullOrEmpty($scriptParentPath)) {
		Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] dot-source invoked by [$(((Get-Variable -Name MyInvocation).Value).ScriptName)]" -Source $appDeployToolkitExtName
	}
	Else {
		Write-Log -Message "Script [$($MyInvocation.MyCommand.Definition)] invoked directly" -Source $appDeployToolkitExtName
	}
}



