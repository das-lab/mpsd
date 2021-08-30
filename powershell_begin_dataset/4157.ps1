
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()]
	[string]$SCCMModule = '<UNCPath>\ConfigurationManager.psd1',
	[ValidateNotNullOrEmpty()]
	[string]$SCCMServer = '<FQDN of SCCM Server>',
	[ValidateNotNullOrEmpty()]
	[string]$SCCMSiteDescription = '<SCCM Server Description>',
	[ValidateNotNullOrEmpty()]
	[string]$SiteCode = '<Three letter SCCM Site Code>'
)

Import-Module -Name $SCCMModule -Force
New-PSDrive -Name $SiteCode -PSProvider 'AdminUI.PS.Provider\CMSite' -Root $SCCMServer -Description $SCCMSiteDescription | Out-Null
Set-Location -Path ($SiteCode + ':')
$List = Get-CMCollectionMember -CollectionName 'All Systems'
Remove-PSDrive -Name $SiteCode -Force
Write-Output $List.Name
