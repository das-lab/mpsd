
[CmdletBinding()]
param
(
	[string]$DirectoryExclusionsFile = 'DirectoryExclusions.txt',
	[string]$FileExclusionsFile = 'FileExclusions.txt',
	[string]$RobocopySwitches = '/e /eta /r:1 /w:0 /TEE /MIR',
	[ValidateNotNullOrEmpty()][string]$DestinationUNC = '\\profiles\userprofiles'
)
function Get-RelativePath {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Invoke-RoboCopy {

	
	[CmdletBinding()][OutputType([string])]
	param
	(
		[ValidateNotNullOrEmpty()][string]$ComputerName,
		[ValidateNotNullOrEmpty()][string]$UserName
	)
	
	
	$RelativePath = Get-RelativePath
	$Executable = $Env:windir + "\system32\robocopy.exe"
	
	$DirectoryExclusions = Get-Content ($RelativePath + $DirectoryExclusionsFile)
	IF ($DirectoryExclusions -ne $null) {
		$ExcludeDir = "/xd"
		
		foreach ($Exclusion in $DirectoryExclusions) {
			$ExcludeDir += [char]32 + $Exclusion
		}
	}
	
	$FileExclusions = Get-Content ($RelativePath + $FileExclusionsFile)
	IF ($FileExclusions -ne $null) {
		$ExcludeFiles = "/xf"
		
		foreach ($Exclusion in $FileExclusions) {
			$ExcludeFiles += [char]32 + $Exclusion
		}
	}
	
	If ($DestinationUNC.Substring($DestinationUNC.Length - 1) -ne '\') {
		$Arguments = [char]34 + '\\' + $ComputerName + '\c$\users\' + $UserName + [char]34 + [char]32 + [char]34 + $DestinationUNC + '\' + $ComputerName + [char]34 + [char]32 + $RobocopySwitches + [char]32 + $ExcludeDir + [char]32 + $ExcludeFiles + [char]32 + '/LOG:' + [char]34 + $DestinationUNC + '\0RobocopyLogs\' + $ComputerName + '.log' + [char]34
	} else {
		$Arguments = [char]34 + '\\' + $ComputerName + '\c$\users\' + $UserName + [char]34 + [char]32 + [char]34 + $DestinationUNC + $ComputerName + [char]34 + [char]32 + $RobocopySwitches + [char]32 + $ExcludeDir + [char]32 + $ExcludeFiles + [char]32 + '/LOG:' + [char]34 + $DestinationUNC + '0RobocopyLogs\' + $ComputerName + '.log' + [char]34
	}
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Arguments -WindowStyle Minimized -Wait -Passthru).ExitCode
	Return $ErrCode
}

$ComputerName = Read-Host -Prompt 'Input computer name'
$UserName = Read-Host -Prompt 'Input user name'

If ((Get-Item -Path ('\\' + $ComputerName + '\c$') -ErrorAction SilentlyContinue) -eq $null) {
	Write-Host "Computer not reachable or incorrect computer name"
	Exit 1
}
If ((Get-Item -Path ('\\' + $Computername + '\c$\users\' + $Username) -ErrorAction SilentlyContinue) -eq $null) {
	Write-Host "Username is incorrect"
	Exit 1
}
$ErrCode = Invoke-RoboCopy -ComputerName $ComputerName -UserName $UserName
switch ($ErrCode) {
	0 { Write-Host '0 - No Changes' }
	1 { Write-Host '1 - OK Copy' }
	2 { Write-Host '2 - Extra content deleted' }
	3 { Write-Host '3 - OK Copy & Extra content deleted' }
	4 { Write-Host '4 - Mismatches' }
	5 { Write-Host '5 - OK Copy & mismatches'}
	6 { Write-Host '6 - Mismatches & Extra content deleted'}
	7 { Write-Host '7 - OK Copy & Mismatches & Extra content deleted'}
	8 { Write-Host '8 - Failed'}
	9 { Write-Host '9 - OK Copy & Failed'}
	10 { Write-Host '10 - Failed & Extra content deleted'}
	11 { Write-Host '11 - OK Copy & Failed & Extra content deleted'}
	12 { Write-Host '12 - Failed & Mismatches'}
	13 { Write-Host '13 - OK Copy & Failed & Mismatches'}
	14 { Write-Host '14 - Failed & Mismatches & Extra content deleted'}
	15 { Write-Host '15 - OK Copy & Failed & Mismatches & Extra content deleted'}
	16 { Write-Host '16 - Fatal Error'}
}
