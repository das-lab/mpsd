










if (!(Get-Module 'GroupPolicy') -or !(Get-Module 'Internal')) {
	Write-Error 'One or more required modules not loaded';
	return;
}

$bRemediate = $false;


$aDefaultGpos = @('Default Domain Controllers Policy');

$aGposToRead = Get-GPOReport -ReportType XML -All;

foreach ($sGpo in $aGposToRead) {
	$xGpo = ([xml]$sGpo).GPO;
	if ($aDefaultGpos -notcontains $xGpo.Name) { 
		$o = New-Object System.Object;
		$o | Add-Member -type NoteProperty -Name 'GPO' -Value $xGpo.Name;
		if ($xGpo.User.Enabled -eq 'true' -and !(Test-Member $xGpo.User ExtensionData)) {
			$o | Add-Member -type NoteProperty -Name 'UnpopulatedLink' -Value 'User';
			if ($bRemediate) {
				(Get-GPO $xGpo.Name).GPOStatus = 'UserSettingsDisabled';
				echo "Disabled user settings on GPO $($xGpo.Name)";
			} else {
				$o
			}
		}
		if ($xGpo.Computer.Enabled -eq 'true' -and !(Test-Member $xGpo.Computer ExtensionData)) {
			$o | Add-Member -type NoteProperty -Name 'UnpopulatedLink' -Value 'Computer' -Force;
			if ($bRemediate) {
				(Get-GPO $xGpo.Name).GPOStatus = 'ComputerSettingsDisabled';
				echo "Disabled computer settings on GPO $($xGpo.Name)";
			} else {
				$o
			}
		}
	}
}
