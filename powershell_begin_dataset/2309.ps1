


[CmdletBinding()]
param (
	[switch]$Replace,
	[Parameter(Mandatory)]
	[ValidateScript({ Test-Path $_ -PathType Leaf })]
	[string]$CsvFilePath,
	[Parameter(Mandatory)]
	[string]$ServerInstance,
	[Parameter(Mandatory)]
	[string]$Database,
	[string]$Schema = 'dbo',
	[Parameter(Mandatory)]
	[string]$Table
)

begin {
	$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
	Set-StrictMode -Version Latest
	try {
		
		$CsvRows = Import-Csv -Path $CsvFilePath
		$SqlTable = Get-SqlTable -Database (Get-SqlDatabase -sqlserver $Server -dbname $Database) -Name $Table -Schema $Schema
		if (Compare-Object -DifferenceObject ($CsvRows[0].Psobject.Properties.Name) -ReferenceObject ($SqlTable.Columns.Name)) {
			throw 'The field names in the CSV file and the SQL database are not equal'
		}
		
		
		$SqlRows = Get-SqlData -sqlserver $ServerInstance -dbname $Database -qry "SELECT * FROM $Table"
	} catch {
		Write-Error $_.Exception.Message
		exit
	}
}

process {
	try {
		
		
		$PrimaryKey = ($SqlTable.Columns | Where-Object { $_.InPrimaryKey }).Name
		
		
		
		$SqlIntCols = $SqlTable.Columns | where { @('smallint', 'int') -contains $_.DataType.Name }
		$SqlCharCols = $SqlTable.Columns | where { @('varchar', 'char') -contains $_.DataType.Name }
		
		foreach ($CsvRow in $CsvRows) {
			try {
				
				$SqlRow = $SqlRows | Where-Object { $_.$PrimaryKey -eq $CsvRow.$PrimaryKey }
				if ($SqlRow) {
					
					
					$FieldDiffs = [ordered]@{ }
					foreach ($CsvProp in ($CsvRow.PsObject.Properties | where { $_.Name -ne $PrimaryKey })) {
						foreach ($SqlProp in ($SqlRow.PsObject.Properties | where { $_.Name -ne $PrimaryKey })) {
							if (($CsvProp.Name -eq $SqlProp.Name) -and ($CsvProp.Value -ne $SqlProp.Value)) {
								$FieldDiffs["$($CsvProp.Name) - FROM"] = $SqlProp.Value;
								$FieldDiffs["$($CsvProp.Name) - TO"] = $CsvProp.Value
							}
						}
					}
					if (!($FieldDiffs.Keys | where { $_ })) {
						Write-Verbose "All fields are equal for row $($SqlRow.$PrimaryKey)"
					} else {
						$FieldDiffs['PrimaryKeyValue'] = $SqlRow.$PrimaryKey
						if (!$Replace.IsPresent) {
							[pscustomobject]$FieldDiffs
						} else {
							
							
							
							
							
							
							
							
							
							
							
							
							
							
						}
					}
				} else {
					Write-Verbose "No SQL row match found for CSV row $($CsvRow.$PrimaryKey)"
				}
			} catch {
				Write-Warning "Error Occurred: $($_.Exception.Message) in row $($CsvRow.$PrimaryKey)"
			}
		}
	} catch {
		Write-Error $_.Exception.Message
	}
}