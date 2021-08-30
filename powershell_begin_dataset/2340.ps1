function Get-ActiveDirectoryUserNameMatch($FirstName,$LastName,$MiddleInitial) {
	if ($MiddleInitial) {
		$Filter = { (initials -eq $MiddleInitial) -and (surname -eq $LastName) -and (givenname -eq $FirstName) }
		$MatchType = 'FML'
	} else {
		$Filter = { (surname -eq $LastName) -and (givenname -eq $FirstName) }
		$MatchType = 'FL'
	}
	$Param = @{ 'Filter' = $Filter; 'Properties' = 'DisplayName' }
	$Result = Get-ADUser @Param
	if ($Result) {
		$Result | Add-Member -Type 'NoteProperty' -Name 'MatchMethod' -Value $MatchType -Force
	} else {
		$UserCount = $AllAdUsers.Count
		for ($i=0; $i -lt $UserCount; $i++) {
			$FnameDistance = Get-LevenshteinDistance -first $FirstName -second $AllAdusers[$i].Givenname -ignoreCase
			$LnameDistance = Get-LevenshteinDistance -first $LastName -second $AllAdusers[$i].surname -ignoreCase
			$TotalDistance = $FnameDistance + $LnameDistance
			if ($i -eq 0) {
				$Result = $AllAdUsers[$i]
				$LowestDistance = $TotalDistance
			} elseif ($TotalDistance -lt $LowestDistance) {
				$Result = $AllAdUsers[$i]
				$LowestDistance = $TotalDistance
			}
		}
		$Result | Add-Member -Type 'NoteProperty' -Name 'MatchMethod' -Value 'LowestEditDistance' -Force
	}
	$Result
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
 
$AllAdUsers = Get-ADUser -Filter { (givenname -like '*') -and (surname -like '*') } -Properties 'DisplayName'
$Content = Get-Content 'C:\users.txt'
$UnknownSourceUsers = [system.Collections.ArrayList]@()
foreach ($Row in $Content) {
	$Split = $Row.Split(' ');
	$LastName = $Split[$Split.Count - 1];
	$FirstName = $Split[0];
	$MiddleInitial = @{ $true = $Split[1]; $false = '' }[($Split.Count -eq 3) -and ($Split[1].Length -eq 1)]
	if (($Split.Count -gt 3) -or ($Split.Count -lt 2) -or (($Split[1].Length -ne 1) -and ($Split.Count -eq 3))) {
		$UnknownSourceUsers.Add($Row) | Out-Null
	} else {
		$Output = @{
			'SourceFirstName' = $FirstName
			'SourceLastName' = $LastName
			'SourceMiddleInitial' = $MiddleInitial
			'ActiveDirectoryFirstname' = ''
			'ActiveDirectoryLastName' = ''
			'ActiveDirectoryDisplayName' = ''
			'ActiveDirectorySamAccountName' = ''
			'ActiveDirectoryStatus' = ''
			'ActiveDirectoryMatchMethod' = 'NoMatch'
		}
		$AdMatch = Get-ActiveDirectoryUserNameMatch -FirstName $FirstName -LastName $LastName -MiddleInitial $MiddleInitial
		if (!$AdMatch) {
			[pscustomobject]$Output | Export-Csv -Path johnoutput.csv -Append -NoTypeInformation
		} else {
			$Output.ActiveDirectoryDisplayName = $AdMatch.DisplayName
			$Output.ActiveDirectoryFirstName = $AdMatch.givenName
			$Output.ActiveDirectoryLastName = $AdMatch.surName
			$Output.ActiveDirectorySamAccountName = $AdMatch.SamAccountName
			$Output.ActiveDirectoryStatus = $AdMatch.Enabled
			$Output.ActiveDirectoryMatchMethod = $AdMatch.MatchMethod
			[pscustomobject]$Output | Export-Csv -Path output.csv -Append -NoTypeInformation
		}
		
	}
}
Write-Host 'Unrecognized name formats'
$UnknownSourceUsers
