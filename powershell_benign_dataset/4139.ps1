
[CmdletBinding()]
param ()

Remove-Item -Path ($env:windir + '\temp\ActivityLog.xml') -ErrorAction SilentlyContinue -Force
Remove-Item -Path ($env:windir + '\temp\inventory.xml') -ErrorAction SilentlyContinue -Force

$ErrCode = (Start-Process -FilePath ((Get-ChildItem -Path $env:ProgramFiles, ${env:ProgramFiles(x86)} -Filter 'dcu-cli.exe' -Recurse).FullName) -ArgumentList ('/log ' + $env:windir + '\temp') -Wait).ExitCode

$File = (Get-Content -Path ($env:windir + '\temp\ActivityLog.xml')).Trim()

If (('<message>CLI: No application component updates found.</message>' -in $File) -and (('<message>CLI: No available updates can be installed.</message>' -in $File) -or ('<message>CLI: No updates are available.</message>' -in $File))) {
	Remove-Item -Path ($env:windir + '\temp\ActivityLog.xml') -ErrorAction SilentlyContinue -Force
	Remove-Item -Path ($env:windir + '\temp\inventory.xml') -ErrorAction SilentlyContinue -Force
	Remove-Item -Path ($env:TEMP + '\RebootCount.log') -ErrorAction SilentlyContinue -Force
} else {
	
	If ((Test-Path ($env:TEMP + '\RebootCount.log')) -eq $false) {
		New-Item -Path ($env:TEMP + '\RebootCount.log') -ItemType File -Value 0 -Force
	}
	
	If (([int](Get-Content -Path ($env:TEMP + '\RebootCount.log'))) -lt 5) {
		
		$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
		
		$TSEnv.Value('SMSTSRebootRequested') = $true
		
		$TSEnv.Value('SMSTSRetryRequested') = $true
		
		New-Item -Path ($env:TEMP + '\RebootCount.log') -ItemType File -Value ([int](Get-Content -Path ($env:TEMP + '\RebootCount.log')) + 1) -Force
	
	} else {
		Remove-Item -Path ($env:windir + '\temp\ActivityLog.xml') -ErrorAction SilentlyContinue -Force
		Remove-Item -Path ($env:windir + '\temp\inventory.xml') -ErrorAction SilentlyContinue -Force
		Remove-Item -Path ($env:TEMP + '\RebootCount.log') -ErrorAction SilentlyContinue -Force
	}
}
