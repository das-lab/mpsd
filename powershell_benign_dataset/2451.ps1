
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