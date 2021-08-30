

param( 
	$SQLServer = 'PSQLRPT2',
	[string]$ScriptDir = 'C:\Users\MMessano\Desktop\DMartInterum',
	$Beta = 0,
	[String[]] $DatabaseList,
	$FilePrefix = 'Log',
	[switch]$Log
)

$DQuery = "SELECT CDCReportDB FROM ClientConnectionCDC WHERE Beta = " + $Beta + " ORDER BY 1"

$Databases = Invoke-Sqlcmd -ServerInstance $SQLServer -Database PA_DMart -Query $DQuery 

$DataScripts = Get-ChildItem -Path $ScriptDir -Filter *Data*.sql | sort-object -desc

cls

if ($Databases) {
	foreach ($DB IN $Databases) {
		Write-Host "Begin" $DB[0]
			if ($DataScripts) {
				foreach ( $DataScript IN $DataScripts ) {
					Invoke-SQLCMD -ServerInstance $SQLServer -Database $DB[0] -InputFile $DataScript.FullName -QueryTimeout 120
					Write-Host "`tApplied " $DataScript.FullName "to the" $DB[0]"database"on" $SQLServer."
				}
			}
		}



	Write-Host "End" $DB[0]
}

