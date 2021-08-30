
$File = "<Path to CSV file>\ProfileSizeReport.csv"

$Exclusions = ("Administrator", "Default", "Public")

$Profiles = Get-ChildItem -Path $env:SystemDrive"\Users" | Where-Object { $_ -notin $Exclusions }

$AllProfiles = @()

foreach ($Profile in $Profiles) {
	$object = New-Object -TypeName System.Management.Automation.PSObject
	
	$FolderSizes = [System.Math]::Round("{0:N2}" -f ((Get-ChildItem ($Profile.FullName + '\Documents'), ($Profile.FullName + '\Desktop') -Recurse | Measure-Object -Property Length -Sum -ErrorAction Stop).Sum))
	$object | Add-Member -MemberType NoteProperty -Name ComputerName -Value $env:COMPUTERNAME.ToUpper()
	$object | Add-Member -MemberType NoteProperty -Name Profile -Value $Profile
	$Object | Add-Member -MemberType NoteProperty -Name Size -Value $FolderSizes
	$AllProfiles += $object
}

[string]$Output = $null
foreach ($Entry in $AllProfiles) {
	[string]$Output += $Entry.ComputerName + ',' + $Entry.Profile + ',' + $Entry.Size + [char]13
}

$Output = $Output.Substring(0,$Output.Length-1)

Do {
	Try {
		$Output | Out-File -FilePath $File -Encoding UTF8 -Append -Force
		$Success = $true
	} Catch {
		$Success = $false
	}
} while ($Success = $false)
