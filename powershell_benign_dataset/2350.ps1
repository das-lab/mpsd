function convertDsnToPathFormat($sDsn) {
	$sDsn = $sDsn.Replace(',<domainDNhere>','');
	$sDsn = $sDsn.Replace('OU=','');
	$aDsn = $sDsn.Split(',');
	[array]::Reverse($aDsn);
	$sPath = $aDsn -join '/';
	return '<domain name>/' + $sPath;
}

$aAllGpos = Get-GPOReport -all -ReportType XML;
$aFilteredGpos = @();
$aLinkedOuGPos = @();
foreach ($xGpo in $aAllGpos) {
	$xGpo = ([xml]$xGpo).GPO;
	if (Test-Member $xGpo 'LinksTo') {  
		$sGpoName = $xGpo.Name;
		if ($xGpo.LinksTo -is [array]) { 
			$aLinkedOus = $xGpo.LinksTo | Select-Object SOMPath | % { $_.SOMPath }
		} else {
			$aLinkedOus = , @($xGpo.LinksTo.SOMPath);
		}
		$aLinkedOuGPos += , @($sGpoName,$aLinkedOus);
	}
}

$aObjects = Get-ADObject -Filter "ObjectClass -eq 'user' -or ObjectClass -eq 'computer' -or ObjectClass -eq 'group' -or ObjectClass -eq 'organizationalUnit'";

$aOuDns = @();
foreach ($o in $aObjects) {
	$sDn = $o.DistinguishedName;
	if ($sDn -like '*OU=*') {
		$sOuDn = $sDn.Substring($sDn.IndexOf('OU='));
		$aOuDns += $sOuDn;
	}
}

$a0CountOus = $aOuDns | Group-Object | Where-Object { $_.Count -eq 1 } | % { $_.Name };
$aFiltered0CountOUs = @();
foreach ($sOu in $a0CountOus) {
	if (!(Get-ADObject -Filter "ObjectClass -eq 'organizationalUnit'" | where { $_.DistinguishedName -like "*$sOu*" -and $_.DistinguishedName -ne $sOu })) {
		$aFiltered0CountOUs += convertDsnToPathFormat $sOu;
	}
}

foreach ($aGpo in $aLinkedOuGpos) {
	foreach ($i in $aFiltered0CountOUs) {
		if (($aGpo[1] -contains $i) -and ($aGpo[1] -notcontains '<domain name>')) {
			$aGpo[0];
		}
	}
}