








Set-Variable -Name Command -Scope Global -Force
Set-Variable -Name Computer -Scope Global -Force
Set-Variable -Name Computers -Scope Global -Force
Set-Variable -Name i -Scope Global -Value 1 -Force
Set-Variable -Name Output -Scope Global -Force
Set-Variable -Name RelativePath -Scope Global -Force
Set-Variable -Name Results -Scope Global -Force
Set-Variable -Name Username -Scope Global -Force

Function RenameWindow ($Title) {

	
	Set-Variable -Name a -Scope Local -Force
	
	$a = (Get-Host).UI.RawUI
	$a.WindowTitle = $Title
	
	
	Remove-Variable -Name a -Scope Local -Force
}

Function GetRelativePath{
	$Global:RelativePath=(split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\"
}

cls
RenameWindow "Who's Logged On and Logged Off?"
GetRelativePath
$Results = @()
$Username = @()
$Computers = Get-Content -Path $Global:RelativePath"Computers.txt"
$Size = $Computers.Length
Foreach ($Computer in $Computers) {
	Write-Host "Scanning System "$i" of "$Size
	Write-Host
	Write-Host "System:"$Computer
	$Command = $Global:RelativePath+"PsLoggedon.exe -x -l \\$Computer"
	$Output = Invoke-Expression $Command
	If ($Output.SyncRoot[2] -eq "Users logged on locally:") {
		$Username += $Output.SyncRoot[3].Trim()
	} else {
		$Username += "N/A"
	}
	$Output = $Output.SyncRoot[2]
	$Output = $Output.Substring(0,$Output.Length-1)
	$Results += $Output
	$i = $i + 1
	cls
}
cls
for ($i=0 ; $i -lt $Results.length ; $i++) {
 	If ($Results[$i] -eq "No one is logged on locally") {
		Write-Host $Computers[$i]": "$Results[$i] -BackgroundColor Yellow -ForegroundColor Black
	} elseIf ($Results[$i] -eq "Users logged on locally") {
		Write-Host $Computers[$i]": "$Results[$i]" -- "$Username[$i]-ForegroundColor White
	} else {
		Write-Host $Computers[$i]": "$Results[$i]" -- "$Username[$i]-ForegroundColor Red
	}
}


Remove-Variable -Name Command -Scope Global -Force
Remove-Variable -Name Computer -Scope Global -Force
Remove-Variable -Name Computers -Scope Global -Force
Remove-Variable -Name i -Scope Global -Force
Remove-Variable -Name Output -Scope Global -Force
Remove-Variable -Name RelativePath -Scope Global -Force
Remove-Variable -Name Results -Scope Global -Force
Remove-Variable -Name Username -Scope Global -Force
 
