
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()]
	[string]$SCCMModule,
	[ValidateNotNullOrEmpty()]
	[string]$SCCMServer,
	[ValidateNotNullOrEmpty()]
	[string]$SCCMSiteDescription,
	[ValidateNotNullOrEmpty()]
	[string]$SiteCode,
	[ValidateNotNullOrEmpty()]
	[string]$Collection,
	[ValidateNotNullOrEmpty()]
	[string]$SQLServer,
	[ValidateNotNullOrEmpty()]
	[string]$SQLDatabase
)

$List = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDatabase -Query ('SELECT Name, MachineID, CP_LastInstallationError FROM' + [char]32 + 'dbo.' + ((Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDatabase -Query ('Select ResultTableName FROM dbo.Collections WHERE CollectionName =' + [char]32 + [char]39 + $Collection + [char]39)).ResultTableName) + [char]32 + 'WHERE ClientVersion IS NULL AND CP_LastInstallationError = 120 Order By MachineID')
If ($List -ne '') {
	Import-Module -Name $SCCMModule -Force
	New-PSDrive -Name $SiteCode -PSProvider 'AdminUI.PS.Provider\CMSite' -Root $SCCMServer -Description $SCCMSiteDescription | Out-Null
	Set-Location -Path ($SiteCode + ':')
	
	$List | ForEach-Object { (Get-CMDevice -ResourceId $_.MachineID -Fast).Name }
	
	Remove-PSDrive -Name $SiteCode -Force
	Write-Output ($List.Name | Sort-Object)
} else {
	Exit 1
}
