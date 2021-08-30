

param( 
	$SQLServer = 'STGSQLDOC710',
	$ScriptDir = '\\xfs3\DataManagement\Footprints\31177',
	$Beta = 1,
	[String[]] $DatabaseList,
	$FilePrefix = 'Log',
	[switch]$Log
)

$SQuery = "SELECT StageDB FROM ClientConnection WHERE Beta = " + $Beta
$DQuery = "SELECT ReportDB FROM ClientConnection WHERE Beta = " + $Beta + " ORDER BY 1"

$Query = $SQuery + " UNION " + $DQuery

$Databases = Invoke-Sqlcmd -ServerInstance $SQLServer -Database PA_DMart -Query $Query 

$DataScripts = Get-ChildItem -Path $ScriptDir -Filter *Data*.sql | sort-object -desc
$StageScripts = Get-ChildItem -Path $ScriptDir -Filter *Stage*.sql | sort-object -desc



if ($Databases) {
	foreach ($i IN $Databases) {
		Write-Host "Begin" $i[0]
		if ($i[0].EndsWith("Stage")) {
			
			if ($StageScripts) {
				foreach ( $StageScript IN $StageScripts ) {
					Invoke-SQLCMD -ServerInstance $SQLServer -Database $i[0] -InputFile $StageScript.FullName
					Write-Host "`tApplied " $StageScript.fullname "to the" $i[0]"database"on" $SQLServer."
				}
			}
		}
		elseif ($i[0].EndsWith("Data")) {
			
			if ($DataScripts) {
				foreach ( $DataScript IN $DataScripts ) {
					Invoke-SQLCMD -ServerInstance $SQLServer -Database $i[0] -InputFile $DataScript.FullName
					Write-Host "`tApplied " $DataScript.FullName "to the" $i[0]"database"on" $SQLServer."
				}
			}
		}
		else {
			Write-Host "WTF " $i[0] " is not a Data or Stage database."
		}
	Write-Host "End" $i[0]
	}
}