$sDefaultGpoGuid = '{F6FE3FDE-4CD0-455D-B9BC-D134111BBF09}';

$sDefaultGpoGuid = "*$($sDefaultGpoGuid)*";
$ErrorActionPreference = "Stop";

$aComputerGPOs = Get-ADObject -Filter {(ObjectClass -eq "groupPolicyContainer")}



$test = @();

if ($aComputerGpos -ne $null) { 
	$aReport = @() 
	foreach ($oGpo in $aComputerGpos) { 
		[XML]$xGpoReport = Get-GPOReport -Guid $oGpo.Name -ReportType XML;
		try {
			if (($xGpoReport.GPO.Computer.Enabled -eq 'true') -and (Test-Member $xGpoReport.GPO.Computer 'ExtensionData')) {
				$aSettings = @();
				foreach ($oExt in $xGpoReport.GPO.Computer.ExtensionData) { 
					$aSettings += $oExt.Extension.ChildNodes 
				}
				if ($aSettings.Count -ne 0) {
					echo '11111111'
					echo "======NAME:$($xGpoReport.GPO.Name)========="
					$aSettings
					echo '22222222'
					foreach ($oSetting in $aSettings) {
						if ($oSetting.Name -match '^q\d+:RegistrySetting') {
							$xGpoReport.GPO.Name
							
							
							
							
							
							
							
							
							
							
						} elseif ($oSetting.Name -notmatch '^q\d+') {
							
						}
						







					}
				}
			}
		} catch {  
			Write-Error $_.Exception
		}
	}
}

$test | Select -Unique