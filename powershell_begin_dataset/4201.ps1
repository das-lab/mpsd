
[CmdletBinding()]
param ()

function Get-MaximumResolution {
	
	$Monitors = @()
	
	$HardwareIDs = (Get-WmiObject Win32_PNPEntity | where-object { $_.PNPClass -eq "Monitor" }).HardwareID | ForEach-Object { $_.Split("\")[1] }
	foreach ($Monitor in $HardwareIDs) {
		
		$Object = New-Object -TypeName System.Management.Automation.PSObject
		
		$DriverFile = Get-ChildItem -path c:\windows\system32\driverstore -Filter *.inf -recurse | Where-Object { (Select-String -InputObject $_ -Pattern $Monitor -quiet) -eq $true }
		
		$MaxResolution = ((Get-Content -Path $DriverFile.FullName | Where-Object { $_ -like "*,,MaxResolution,,*" }).split('"')[1]).Split(",")
		
		$Object | Add-Member -MemberType NoteProperty -Name Model -Value $DriverFile.BaseName.ToUpper()
		
		$Object | Add-Member -MemberType NoteProperty -Name "Horizontal(X)" -Value $MaxResolution[0]
		
		$Object | Add-Member -MemberType NoteProperty -Name "Vertical(Y)" -Value $MaxResolution[1]
		
		$Monitors += $Object
	}
	Return $Monitors
}


$Monitors = Get-MaximumResolution
$Monitors
