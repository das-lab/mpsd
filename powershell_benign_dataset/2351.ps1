
$sUnionEmployeesFilePath = 'Union Lawson Employees.csv';
$sUapEmployeesFilePath = 'UAPEmployees.csv';
$sOutputFilePath = 'old-non-employee-AD-user-accounts.tsv';
$iDefinedOldDays = 90;
$dDaysAgo = [DateTime]::Now.Subtract([TimeSpan]::FromDays($iDefinedOldDays));




$aUnionContent = Get-Content $sUnionEmployeesFilePath;
$aUnionNoHeader = Get-Content $sUnionEmployeesFilePath | Select-Object -Skip 1;
$aUapContent = Get-Content $sUapEmployeesFilePath;
$aUapNoHeader = Get-Content $sUapEmployeesFilePath | Select-Object -Skip 1;


$sHeaderRow = $aUnionContent[0];
$sHeaderRow = $sHeaderRow.Replace('EMPLOYEE','EmployeeID');
$sHeaderRow = $sHeaderRow.Replace('LAST_NAME','Surname');
$sHeaderRow = $sHeaderRow.Replace('FIRST_NAME','GivenName');
$sHeaderRow = $sHeaderRow.Replace('R_NAME','Department');
$sHeaderRow = $sHeaderRow.Replace('MIDDLE_INIT','Initials');
$sHeaderRow = $sHeaderRow.Replace('LAWSON_PAPOSITION.DESCRIPTION','Title');
$sHeaderRow = $sHeaderRow.Replace('LAWSON_EMSTATUS.DESCRIPTION','HireStatus');
Set-Content $sUnionEmployeesFilePath -Value $sHeaderRow,$aUnionContent[1..($aUnionContent.Count)];


$sHeaderRow = $aUapContent[0];
if ($sHeaderRow -notmatch "^.*,HireStatus$") {
	$sHeaderRow = "$sHeaderRow,HireStatus";
}
Set-Content $sUapEmployeesFilePath -Value $sHeaderRow,$aUapContent[1..($aUapContent.Count)];


$aUnionEmployeesCsv = Import-Csv $sUnionEmployeesFilePath;
$aUapEmployeesCsv = Import-Csv $sUapEmployeesFilePath;


$global:aEmployeesFromCsv = $aUnionEmployeesCsv + $aUapEmployeesCsv;
$global:iEmpCount = $aEmployeesFromCsv.Count;


$aOldUsers = Get-ADUser -Filter {(Enabled -eq 'True') -and (LastLogonDate -le $dDaysAgo) -and (PasswordLastSet -le $dDaysAgo)} -Properties EmployeeID,LastLogonDate,PasswordLastSet,Department,Initials;

$iAdUserCount = $aOldUsers.Count;

function isActiveEmployee($oAdUser) {
	for ($i = 0; $i -lt $iEmpCount; $i++) {
		if ($oAdUser.EmployeeID -and $aEmployeesFromCsv[$i].EmployeeID) {
			if ($oAdUser.EmployeeID -eq $aEmployeesFromCsv[$i].EmployeeID) {
				return @($true,$oAdUser,$aEmployeesFromCsv[$i].HireStatus);
			}
		}
		if ($aEmployeesFromCsv[$i].Surname -and $aEmployeesFromCsv[$i].GivenName) { 
			if ($oAdUser.GivenName -match '^[^0-9]*$') { 
				if ($oAdUser.Surname -match '^[^-]*$') { 
					$sLNameLike = '*' + $aEmployeesFromCsv[$i].Surname.Trim() + '*';
					$sFNameLike = '*' + $aEmployeesFromCsv[$i].GivenName.Trim() + '*';
					if ($oAdUser.Surname -like $sLNameLike) { 
						if ($oAdUser.GivenName -like $sFNameLike) { 
							return @($true,$oAdUser,$aEmployeesFromCsv[$i].HireStatus);
						}
					}
				}
			}
		}
	}
	return @($false,$oAdUser,$null);
}

function createCustomObject($oAdUser,$sHireStatus) {
	$hProps = @{
		EmployeeID=$oAdUser.EmployeeID;
		LastLogonDate=$oAdUser.LastLogonDate;
		PasswordLastSet=$oAdUser.PasswordLastSet;
		SamAccount=$oAdUser.SamAccountName;
		FirstName=$oAdUser.GivenName;
		LastName=$oAdUser.Surname;
		Department=$oAdUser.Department;
		HireStatus=$sHireStatus
	};
	
	$obj = New-Object -TypeName PSObject -Property $hProps;
	return $obj;
}

for ($i = 0; $i -lt $iAdUserCount; $i++) {
	$aIsActiveEmployee = isActiveEmployee $aOldUsers[$i];
	if (!$aIsActiveEmployee[0]) {
		$oUser = createCustomObject $aOldUsers[$i] 'N/A';
	} elseif ($aIsActiveEmployee[2] -eq 'TERMINATED') {
		$oUser = createCustomObject $aOldUsers[$i] 'Terminated';
	} else {
		$oUser = createCustomObject $aOldUsers[$i] 'Active';
	}
	Write-ObjectToCsv -Object $oUser -CsvPath $sOutputFilePath -Delimiter "`t";
}

Write-Host 'Done' -ForegroundColor Green