

function Get-MSUFileInfo {

	
	[CmdletBinding()]
	param
	(
		[System.IO.FileInfo]$FileName
	)
	
	
	$RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	
	$Executable = Join-Path -Path $env:windir -ChildPath "System32\expand.exe"
	
	$Directory = Join-Path -Path $RelativePath -ChildPath Expanded -ErrorAction SilentlyContinue
	
	Remove-Item -Path $Directory -Recurse -Force -ErrorAction SilentlyContinue
	
	New-Item -Path $Directory -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
	
	$Parameters = '-F:*properties.txt' + [char]32 + [char]34 + $FileName.FullName + [char]34 + [char]32 + [char]34 + $Directory + [char]34
	
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -WindowStyle Hidden -Wait -Passthru).ExitCode
	
	$ExpandedFile = Get-ChildItem -Path $Directory -Filter *properties.txt
	
	$MSUObject = New-Object System.Object
	$MSUObject | Add-Member -MemberType NoteProperty -Name AppliesTo -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*Applies to*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name BuildDate -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*Build Date*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name Company -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*Company*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name FileVersion -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*File Version*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name InstallationType -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*Installation Type*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name InstallerEngine -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*Installer Engine*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name InstallerVersion -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*Installer Version*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name KBArticle -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*KB Article Number*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name Language -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*Language*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name PackageType -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*Package Type*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name ProcessorArchitecture -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*Processor Architecture*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name ProductName -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*Product Name*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name SupportLink -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*Support Link*' }).split("=")[1].replace('"', '')
	
	Remove-Item -Path $Directory -Recurse -Force -ErrorAction SilentlyContinue
	Return $MSUObject
}

$MSUInfo = Get-MSUFileInfo -FileName "\\RSAT\Windows7\Windows6.1-KB958830-x64-RefreshPkg.msu"
$MSUInfo