
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()]
	[string]$File = 'C:\WinPE\SCCM.iso'
)

Import-Module Dism

$Directory = $File.substring(0, $File.LastIndexOf('\'))

$Drive = ((Mount-DiskImage -ImagePath $File) | Get-Volume).DriveLetter

Remove-Item -Path ($Directory + '\Mount') -Recurse -Force -ErrorAction SilentlyContinue

New-Item -Path ($Directory + '\Mount') -ItemType Directory -Force

Remove-Item -Path ($Directory + '\boot.wim') -ErrorAction SilentlyContinue -Force

Copy-Item -Path ($Drive + ':\sources\boot.wim') -Destination $Directory -Force

Set-ItemProperty -Path ($Directory + '\boot.wim') -Name IsReadOnly -Value $false

Mount-WindowsImage -ImagePath ($Directory + '\boot.wim') -Index 1 -Path ($Directory + '\Mount')

Copy-Item -Path ($Drive + ':\SMS\data') -Destination ($Directory + '\Mount\sms') -Recurse -Force

Dismount-WindowsImage -Path ($Directory + '\Mount') -Save

Dismount-DiskImage -ImagePath $File

Remove-Item -Path ((Get-ChildItem -Path ($Directory + '\' + ((Get-ChildItem -path $File -ErrorAction SilentlyContinue).Basename) + '.wim')).FullName) -Force -ErrorAction SilentlyContinue

Rename-Item -Path ($Directory + '\boot.wim') -NewName ((Get-ChildItem -Path $File).BaseName + '.wim') -Force

Remove-Item -Path ($Directory + '\Mount') -Recurse -Force -ErrorAction SilentlyContinue
