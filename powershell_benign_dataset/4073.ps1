

[CmdletBinding()]
param ()

$Processor = [string]((Get-WmiObject win32_processor).Caption)
$Family = ($Processor.split(" ") | Where-Object { (($_ -notlike "*Intel*") -and ($_ -notlike "*x64*") -and ($_ -notlike "*Intel64*")) })[1]
$Model = ($Processor.split(" ") | Where-Object { (($_ -notlike "*Intel*") -and ($_ -notlike "x64")) })[3]
$Output = "Family: " + $Family
Write-Output -InputObject $Output
$Output = " Model: " + $Model
Write-Output -InputObject $Output
If ($Family -ge 6) {
	If ($Model -ge 42) {
		Write-Output -InputObject "Patch is compatible"
		Exit 0
	} else {
		Write-Output -InputObject "Patch in incompatible due to old model"
		Exit 1
	}
} else {
	Write-Output -InputObject "Patch in incompatible due to old family"
	Exit 1
}
