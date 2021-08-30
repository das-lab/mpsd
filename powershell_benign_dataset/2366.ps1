
[CmdletBinding(DefaultParameterSetName = 'CSV')]
[OutputType('System.Management.Automation.PSCustomObject')]
param (
	[hashtable]$AdToSourceFieldMappings = @{ 'givenName' = 'FirstName'; 'Initials' = 'MiddleInitial'; 'surName' = 'LastName' },
	[hashtable]$AdToOutputFieldMappings = @{ 'givenName' = 'AD First Name'; 'Initials' = 'AD Middle Initial'; 'surName' = 'AD Last Name'; 'samAccountName' = 'AD Username' },
	[ValidateScript({Test-Path -Path $_ -PathType 'Leaf'})]
	[Parameter(Mandatory, ParameterSetName = 'CSV')]
	[ValidateScript({Test-Path -Path $_ -PathType 'Leaf' })]
	[string]$CsvFilePath
)

begin {
	$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
	Set-StrictMode -Version Latest
	try {
		
		function Test-MatchFirstNameLastName ($FirstName, $LastName) {
			if ($FirstName -and $LastName) {
				Write-Verbose -Message "$($MyInvocation.MyCommand) - Searching for AD user match based on first name '$FirstName', last name '$LastName'"
				$Match = $AdUsers | where { ($_.givenName -eq $FirstName) -and ($_.surName -eq $LastName) }
				if ($Match) {
					Write-Verbose "$($MyInvocation.MyCommand) - Match(es) found!"
					$Match
				} else {
					Write-Verbose "$($MyInvocation.MyCommand) - Match not found"
					$false	
				}
			} else {
				Write-Verbose "$($MyInvocation.MyCommand) - Match not found. Either first or last name is null"
				$false
			}
		}
	
		function Test-MatchFirstNameMiddleInitialLastName ($FirstName, $MiddleInitial, $LastName) {
			if ($FirstName -and $LastName -and $MiddleInitial) {
				Write-Verbose -Message "$($MyInvocation.MyCommand) - Searching for AD user match based on first name '$FirstName', middle initial '$MiddleInitial' and last name '$LastName'"
				$Match = $AdUsers | where { ($_.givenName -eq $FirstName) -and ($_.surName -eq $LastName) -and (($_.Initials -eq $MiddleInitial) -or ($_.Initials -eq "$MiddleInitial.")) }
				if ($Match) {
					Write-Verbose "$($MyInvocation.MyCommand) - Match(es) found!"
					$Match
				} else {
					Write-Verbose "$($MyInvocation.MyCommand) - Match not found"
					$false
				}
			} else {
				Write-Verbose "$($MyInvocation.MyCommand) - Match not found. Either first name, middle initial or last name is null"
				$false
			}
		}
		
		function Test-MatchFirstInitialLastName ($FirstName,$LastName) {
			Write-Verbose -Message "$($MyInvocation.MyCommand) - Searching for AD user match based on first initial '$($FirstName.Substring(0,1))' and last name '$LastName'"
			if ($FirstName -and $LastName) {
				$Match = $AdUsers | where { "$($FirstName.SubString(0, 1))$LastName" -eq $_.samAccountName }
				if ($Match) {
					Write-Verbose "$($MyInvocation.MyCommand) - Match(es) found!"
					$Match
				} else {
					Write-Verbose "$($MyInvocation.MyCommand) - Match not found"
					$false
				}
			} else {
				Write-Verbose "$($MyInvocation.MyCommand) - Match not found. Either first name or last name is null"
				$false
			}
		}
		
		
		
		
		
		
		
		
		
		function Test-CsvField {
			$CsvHeaders = (Get-Content $CsvFilePath | Select-Object -First 1).Split(',').Trim('"')
			$AdToSourceFieldMappings.Values | foreach {
				if (!($CsvHeaders -like $_)) {
					return $false
				}
			}
			$true
		}
		
		
		
		function Get-LevenshteinDistance {
			
			
			
			
			
			
			
			
			
			
			
			param ([string] $first, [string] $second, [switch] $ignoreCase)
			
			
			
			
			
			
			$len1 = $first.length
			$len2 = $second.length
			
			
			
			
			if ($len1 -eq 0) { return $len2 }
			
			if ($len2 -eq 0) { return $len1 }
			
			
			if ($ignoreCase -eq $true) {
				$first = $first.tolowerinvariant()
				$second = $second.tolowerinvariant()
			}
			
			
			$dist = new-object -type 'int[,]' -arg ($len1 + 1), ($len2 + 1)
			
			
			
			for ($i = 0; $i -le $len1; $i++) { $dist[$i, 0] = $i }
			for ($j = 0; $j -le $len2; $j++) { $dist[0, $j] = $j }
			
			$cost = 0
			
			for ($i = 1; $i -le $len1; $i++) {
				for ($j = 1; $j -le $len2; $j++) {
					if ($second[$j - 1] -ceq $first[$i - 1]) {
						$cost = 0
					} else {
						$cost = 1
					}
					
					
					
					
					
					
					
					
					$tempmin = [System.Math]::Min(([int]$dist[($i - 1), $j] + 1), ([int]$dist[$i, ($j - 1)] + 1))
					$dist[$i, $j] = [System.Math]::Min($tempmin, ([int]$dist[($i - 1), ($j - 1)] + $cost))
				}
			}
			
			
			return $dist[$len1, $len2];
		}
		
		
		
		function New-OutputRow ([object]$SourceRowData) {
			$OutputRow = [ordered]@{
				'Match' = $false;
				'MatchTest' = 'N/A'
			}
			$AdToOutputFieldMappings.Values | foreach {
				$OutputRow[$_] = 'N/A'
			}
			
			$SourceRowData.psobject.Properties | foreach {
				if ($_.Value) {
					$OutputRow[$_.Name] = $_.Value
				}
			}
			$OutputRow
		}
		
		function Add-ToOutputRow ([hashtable]$OutputRow, [object]$AdRowData, $MatchTest) {
			$AdToOutputFieldMappings.Keys | foreach {
				if ($AdRowData.$_) {
					$OutputRow[$AdToOutputFieldMappings[$_]] = $AdRowData.$_
				}
				$OutputRow.MatchTest = $MatchTest
			}
			$OutputRow
		}
		
		function Test-TestMatchValid ($FunctionParameters) {
			$Compare = Compare-Object -ReferenceObject $FunctionParameters -DifferenceObject ($AdToSourceFieldMappings.Values | % { $_ }) -IncludeEqual -ExcludeDifferent
			if (!$Compare) {
				$false
			} elseif ($Compare.Count -ne $FunctionParameters.Count) {
				$false
			} else {
				$true	
			}
		}
		
		function Get-FunctionParams ($Function) {
			$Function.Parameters.Keys | where { $AdToSourceFieldMappings.Values -contains $_ }
		}
		
		
		
		
		
		
		$MatchFunctionPriorities = @{
			'Test-MatchFirstNameMiddleInitialLastName' = 1
			'Test-MatchFirstNameLastName' = 2
			
			'Test-MatchFirstInitialLastName' = 4
		}
		
		if ($PSBoundParameters.CsvFilePath) {
			Write-Verbose -Message "Verifying all field names in the $CsvFilePath match $($AdToSourceFieldMappings.Values -join ',')"
			if (!(Test-CsvField)) {
				throw "One or more fields specified in the `$AdToSourceFieldMappings param do not exist in the CSV file $CsvFilePath"
			} else {
				Write-Verbose "The CSV file's field match source field mappings"
			}
		}
		
	} catch {
		Write-Error "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
		return
	}
	
	Write-Verbose -Message "Retrieving all Active Directory user objects..."
	$script:AdUsers = Get-ADUser -Filter * -Properties 'DisplayName','Initials'
}

process {
	try {
		
		
		
		$TestFunctions = Get-ChildItem function:\Test-Match* | where { !$_.Module }
		Write-Verbose "Found $($TestFunctions.Count) test functions in the script"
		$MatchTestsToRun = @()
		foreach ($TestFunction in $TestFunctions) {
			Write-Verbose -Message "Checking to see if we'll use the $($TestFunction.Name) function"
			if (Test-TestMatchValid -FunctionParameters ($TestFunction.Parameters.Keys | % { $_ })) {
				Write-Verbose -Message "The source data has all of the function $($TestFunction.Name)'s parameters. We'll try this one"
				$MatchTestsToRun += [System.Management.Automation.FunctionInfo]$TestFunction
			} else {
				Write-Verbose -Message "The parameters $($AdToSourceFieldMappings.Keys -join ',') are not adequate for the function $($TestFunction.Name)"
			}
		}
		
		
		
		$MatchTestsToRun | foreach {
			$Test = $_;
			foreach ($i in $MatchFunctionPriorities.GetEnumerator()) {
				if ($Test.Name -eq $i.Key) {
					Write-Verbose "Assigning a priority of $($i.Value) to function $($Test.Name)"
					$Test | Add-Member -NotePropertyName 'Priority' -NotePropertyValue $i.Value
				}
			}
		}
		$MatchTestsToRun = $MatchTestsToRun | Sort-Object Priority
		
		if ($CsvFilePath) {
			$DataRows = Import-Csv -Path $CsvFilePath	
		}
		
		
		
		foreach ($Row in $DataRows) {
			
				[hashtable]$OutputRow = New-OutputRow -SourceRowData $Row
				
				
				
				
				foreach ($Test in $MatchTestsToRun) {
					Write-Verbose -Message "Running function $($Test.Name)..."
					[array]$FuncParamKeys = Get-FunctionParams -Function $Test
					[hashtable]$FuncParams = @{ }
					[array]$FuncParamKeys | foreach {
						$Row.psObject.Properties | foreach {
							if ([array]$FuncParamKeys -contains [string]$_.Name) {
								$FuncParams[$_.Name] = $_.Value
							}
						}
					}
					Write-Verbose -Message "Passing the parameters '$($FuncParams.Keys -join ',')' with values '$($FuncParams.Values -join ',')' to the function $($Test.Name)"
					$AdTestResultObject = & $Test @FuncParams
					if ($AdTestResultObject) {
						$OutputRow.Match = $true
						foreach ($i in $AdTestResultObject) {
							$OutputRow = Add-ToOutputRow -AdRowData $i -OutputRow $OutputRow -MatchTest $Test.Name
						}
						break
					}
				}
			
			[pscustomobject]$OutputRow
		}
	} catch {
		Write-Error "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
	}
}