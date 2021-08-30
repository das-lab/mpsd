function findOldADComputers () {
	$aOldComputers = @();
	$aAllAdComputers = Get-ADComputer -Filter * -Properties LastLogonDate,PasswordLastSet | Where { $_.Enabled -eq $true };
	foreach ($oAdComputer in $aAllAdComputers) { 
		if ($oAdComputer.lastLogonDate -ne $null) {
			if ($oAdComputer.lastLogonDate -lt [DateTime]::Now.Subtract([TimeSpan]::FromDays(60))) {
				if ($oAdComputer.PasswordLastSet -lt [DateTime]::Now.Subtract([TimeSpan]::FromDays(60))) {
					$aOldComputers += $oAdComputer.Name;
				}
			}
		}
	}
	return $aOldComputers;
}

$sOldPcFilePath 	= 'C:\Users\abertram\desktop\projects\ad_cleanup\Get-Old-Ad-Accounts-Files\old_computer_accounts.txt';
$sOnlinePcFilePath 	= 'C:\Users\abertram\desktop\projects\ad_cleanup\Get-Old-Ad-Accounts-Files\online_pcs.txt';

if (Test-Path $sOnlinePcFilePath) {
	$aPastOnlinePcs = Get-Content $sOnlinePcFilePath;
} else {
	$aPastOnlinePcs = @();
}

if (Test-Path $sOldPcFilePath) {
	Remove-Item $sOldPcFilePath -Force
}

$aCurrentOldPcs = findOldAdComputers;

$aDnsQueryResults = Get-DnsARecord $aCurrentOldPcs;
foreach ($i in $aDnsQueryResults) {
	$sPc = $i[0];
	$bResult = $i[1];
	if ($bResult) { 
		if (!(Test-Ping $sPc)) { 
			if ($aPastOnlinePcs -notcontains $sPc) { 
				Write-Debug "$sPc has a DNS record but is offline";
				Add-Content $sOldPcFilePath $sPc;
			}
		} else {
			Write-Debug "$sPc has a DNS record and is online";
			if ($aPastOnlinePcs -notcontains $sPc) {
				Add-Content $sOnlinePcFilePath $sPc;
			}
		}
	} else {
		Write-Debug "$sPc has no DNS record"
		Add-Content $sOldPcFilePath $sPc;
	}
}