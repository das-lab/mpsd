


[CmdletBinding()]
[OutputType()]
param
(
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$Class,
	
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string[]]$ComputerName = $env:COMPUTERNAME,
	
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[pscredential]$Credential,
	
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$Namespace = 'root\cimv2',
	
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[switch]$FriendlyProperties,
	
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[ValidateRange(0, 4)]
	[int]$Impersonation,
	
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[ValidateRange(0, 6)]
	[int]$Authentication
	
)
begin
{
	$FriendlyPropNames = @{
		'BuildNumber' = 'Build Number'
		'CodeSet' = 'Code Set'
		'CurrentLanguage' = 'Current Language'
		'IdentificationCode' = 'Identification Code'
		'InstallableLanguages' = 'Installable Languages'
		'LanguageEdition' = 'Language Edition'
		'OtherTargetOS' = 'Other Target OS'
		'SerialNumber' = 'Serial Number'
		'SMBIOSBIOSVersion' = 'SMBIOS BIOS Version'
		'SMBIOSMajorVersion' = 'SMBIOS Major Version'
		'SMBIOSMinorVersion' = 'SMBIOS Minor Version'
		'SMBIOSPresent' = 'SMBIOS Present'
		'BIOSVersion' = 'BIOS Version'
		'InstallDate' = 'Install Date'
		'ListOfLanguages' = 'List of Languages'
		'PrimaryBIOS' = 'Primary BIOS'
	}
	
	$FriendlyBiosChars = @{
		'28' = 'Int 14h, Serial Services are supported'
		'19' = 'EDD (Enhanced Disk Drive) Specification is supported'
		'4' = 'ISA is supported'
		'3' = 'BIOS Characteristics Not Supported'
		'38' = '1394 boot is supported'
		'27' = 'Int 9h, 8042 Keyboard services are supported'
		'2' = 'Unknown'
		'39' = 'Smart Battery supported'
		'26' = 'Int 5h, Print Screen Service is supported'
		'1' = 'Reserved'
		'25' = "Int 13h - 3.5' / 2.88 MB Floppy Services are supported"
		'0' = 'Reserved'
		'24' = "Int 13h - 3.5' / 720 KB Floppy Services are  supported"
		'12' = 'BIOS shadowing is allowed'
		'23' = "Int 13h - 5.25' /1.2MB Floppy Services are supported"
		'13' = 'VL-VESA is supported'
		'34' = 'AGP is supported'
		'22' = "Int 13h - 5.25' / 360 KB Floppy Services are supported"
		'10' = 'APM is supported'
		'35' = 'I2O boot is supported'
		'21' = "Int 13h - Japanese Floppy for Toshiba 1.2mb (3.5', 360 RPM) is supported"
		'11' = 'BIOS is Upgradeable (Flash)'
		'36' = 'LS-120 boot is supported'
		'20' = "Int 13h - Japanese Floppy for NEC 9800 1.2mb (3.5', 1k Bytes/Sector, 360 RPM) is supported"
		'16' = 'Selectable Boot is supported'
		'37' = 'ATAPI ZIP Drive boot is supported'
		'17' = 'BIOS ROM is socketed'
		'30' = 'Int 10h, CGA/Mono Video Services are supported'
		'14' = 'ESCD support is available'
		'31' = 'NEC PC-98'
		'15' = 'Boot from CD is supported'
		'9' = 'Plug and Play is supported'
		'32' = 'ACPI supported'
		'8' = 'PC Card (PCMCIA) is supported'
		'33' = 'USB Legacy is supported'
		'7' = 'PCI is supported'
		'6' = 'EISA is supported'
		'29' = 'Int 17h, printer services are supported'
		'18' = 'Boot From PC Card (PCMCIA) is supported'
		'5' = 'MCA is supported'
	}
	
	$FriendlyOsNames = @{
		'54' = 'HP MPE'
		'28' = 'IRIX'
		'19' = 'WINCE'
		'4' = 'DGUX'
		'55' = 'NextStep'
		'3' = 'ATTUNIX'
		'52' = 'MiNT'
		'38' = 'XENIX'
		'27' = 'Sequent'
		'2' = 'MACOS'
		'53' = 'BeOS'
		'41' = 'BSDUNIX'
		'39' = 'VM/ESA'
		'26' = 'SCO OpenServer'
		'1' = 'Other'
		'50' = 'IxWorks'
		'40' = 'Interactive UNIX'
		'25' = 'SCO UnixWare'
		'0' = 'Unknown'
		'61' = 'TPF'
		'51' = 'VxWorks'
		'43' = 'NetBSD'
		'24' = 'Reliant UNIX'
		'12' = 'OS/2'
		'60' = 'VSE'
		'42' = 'FreeBSD'
		'23' = 'DC/OS'
		'13' = 'JavaVM'
		'45' = 'OS9'
		'34' = 'TandemNT'
		'22' = 'OSF'
		'10' = 'MVS'
		'44' = 'GNU Hurd'
		'35' = 'BS2000'
		'21' = 'NetWare'
		'11' = 'OS400'
		'47' = 'Inferno'
		'36' = 'LINUX'
		'20' = 'NCR3000'
		'16' = 'WIN95'
		'46' = 'MACH Kernel'
		'37' = 'Lynx'
		'17' = 'WIN98'
		'49' = 'EPOC'
		'30' = 'SunOS'
		'14' = 'MSDOS'
		'48' = 'QNX'
		'31' = 'U6000'
		'15' = 'WIN3x'
		'9' = 'AIX'
		'58' = 'Windows 2000'
		'32' = 'ASERIES'
		'8' = 'HPUX'
		'59' = 'Dedicated'
		'33' = 'TandemNSK'
		'7' = 'OpenVMS'
		'56' = 'PalmPilot'
		'6' = 'Digital Unix'
		'57' = 'Rhapsody'
		'29' = 'Solaris'
		'18' = 'WINNT'
		'5' = 'DECNT'
	}
	
	$FriendlySwElement = @{
		'3' = 'Running'
		'2' = 'Executable'
		'1' = 'Installable'
		'0' = 'Deployable'
	}
}
process
{
	try
	{
		$connParams = @{}
		if ($PSBoundParameters.ContainsKey('Credential'))
		{
			$connParams.Credential = $Credential
		}
		foreach ($computer in $ComputerName)
		{
			try
			{
				$connParams.ComputerName = $computer
				if (-not (Test-Connection -ComputerName $computer -Quiet -Count 1))
				{
					throw "The computer [$computer] is offline and cannot be queried"
				}
				Write-Verbose -Message "The computer [$($computer)] is online. Proceeding..."
				$wmiParams = $connParams + @{
					'Namespace' = $Namespace
					'Class' = $Class
					'Property' = '*'
				}
				if ($PSBoundParameters.ContainsKey('Authentication'))
				{
					$wmiParams.Authentication = $Authentication
				}
				if ($PSBoundParameters.ContainsKey('Impersonation'))
				{
					$wmiParams.Impersonation = $Impersonation
				}
				Write-Verbose -Message "Querying the WMI class [$($Class)] in namespace [$($Namespace)] on computer [$($computer)]"
				if (-not $FriendlyProperties.IsPresent)
				{
					Get-WmiObject @wmiParams | Select-Object *
				}
				else
				{
					$output = [ordered]@{}
					(Get-WmiObject @wmiParams).psbase.psobject.baseobject.properties | foreach {
						if ($FriendlyPropNames[$_.Name])
						{
							$output[$FriendlyPropNames[$_.Name]] = $_.Value
						}
						elseif ($_.Value -and $_.Value.ToString().EndsWith('000000+000'))
						{
							$output[$_.Name] = [Management.ManagementDateTimeconverter]::ToDateTime($_.Value)
						}
						elseif ($_.Name -eq 'BIOSCharacteristics')
						{
							$output['BIOS Characteristics'] = $_.Value | foreach { $FriendlyBiosChars[[string]$_] }
						}
						elseif ($_.Name -eq 'TargetOperatingSystem')
						{
							$output['Target Operating System'] = $FriendlyOsNames[[string]$_.Value]
						}
						elseif ($_.Name -eq 'SoftwareElementState')
						{
							$output['Software Element State'] = $FriendlySwElement[[string]$_.Value]
						}
						else
						{
							$output[$_.Name] = $_.Value
						}
					}
					[pscustomobject]$output
				}
			}
			catch
			{
				Write-Error "Unable to query WMI on [$computer] - $($_.Exception.Message)"
			}
		}
	}
	catch
	{
		Write-Error $_.Exception.Message
	}
	finally
	{
		Write-Verbose -Message 'WMIX script by GoverLAN complete'
	}
}