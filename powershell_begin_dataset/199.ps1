Function Get-VMhostHbaInfo
{



	[CmdletBinding()]
	PARAM (
		[Parameter(
				   Mandatory = $true,
				   ValueFromPipeline = $true)]
		[String] $VMhost,
		[Parameter()]
		[ValidateScript({ Test-path -Path $_ -PathType Leaf })]
		[string] $PlinkPath = "C:\Program Files (x86)\PuTTY\plink.exe",
		[Parameter(
				   HelpMessage = "Enter the ESXi account used for SSH connection/command.",
				   Mandatory = $true)]
		[string] $Username,
		[Parameter(
				   HelpMessage = "Enter the ESXi account's password.",
				   Mandatory = $true)]
		[string] $Password
	)
	BEGIN
	{
		TRY
		{
			
			IF (-not (Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction 'SilentlyContinue'))
			{
				Write-Verbose -Message "BEGIN - Loading Vmware Snapin VMware.VimAutomation.Core..."
				Add-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction Stop -ErrorVariable ErrorBeginAddPssnapin
			}

			
			IF (-not ($global:DefaultVIServer.count -gt 0))
			{
				Write-Verbose -Message "BEGIN - Currently not connected to a vCenter..."
				Connect-VIServer -Server (Read-Host -Prompt "You are not connected to a VMware vCenter, Please enter the FQDN or IP of the vCenter") -ErrorAction Stop -ErrorVariable ErrorBeginConnectViServer
			}
		}
		CATCH
		{

			IF ($ErrorBeginAddPssnapin)
			{
				Write-Warning -Message "BEGIN - VMware Snapin VMware.VimAutomation.Core does not seem to be available"
				Write-Error -message $Error[0].Exception.Message
			}
			IF ($ErrorBeginConnectViServer)
			{
				Write-Warning -Message "BEGIN - Couldnt connect to the Vcenter"
				Write-Error -message $Error[0].Exception.Message
			}
		}
	}
	PROCESS
	{
		TRY
		{
			Write-verbose -Message "PROCESS - $Vmhost - Retrieving General Information ..."
			$hostsview = Get-View -ViewType HostSystem -Property ("runtime", "name", "config", "hardware") -Filter @{ "Name" = "$VMhost" } -ErrorAction Stop -ErrorVariable ErrorProcessGetView

			IF ($hostsview)
			{
				IF ($hostsview.runtime.PowerState -match "poweredOn")
				{
					Write-verbose -Message "PROCESS - $($hostview.name) - Status is Powered On"
					$esx = $hostsview | where-object { $_.runtime.PowerState -match "poweredOn" }
					FOREACH ($hba in ($esx.Config.StorageDevice.HostBusAdapter | Where-Object { $_.GetType().Name -eq "HostFibreChannelHba" }))
					{
						Write-Verbose -Message "PROCESS - $($esx.name) - Retrieving HBA information ..."
						$line = "" | Select-Object -Property HostName, HostProduct, HbaDevice, HbaWWN, HbaDriver, HbaModel, HbaFirmwareVersion, HWModel
						$line.HostName = $esx.name
						$line.HostProduct = $esx.config.product.fullName
						$line.HbaDevice = $hba.device
						$line.HbaWWN = ([regex]::matches("{0:x}" -f $hba.PortWorldWideName, '.{2}') | Foreach-object { $_.value }) -join ':'
						$line.HbaDriver = $hba.driver
						$line.HbaModel = $hba.model
						$line.HWModel = $esx.hardware.systemInfo.model


						Write-Verbose -Message "PROCESS - $($esx.name) - Retrieving HBA Advance information - checking SSH Service..."
						IF (((Get-View -ViewType HostSystem -ErrorAction Stop -ErrorVariable ErrorProcessGetViewTypeService -Filter @{ "Name" = $($ESX.name) }).config.service.service |where-object { $_.key -eq 'tsm-ssh' }).running)
						{
							if ($hba.driver -match "lpfc")
							{
								$remoteCommand = "head -9 /proc/scsi/lpfc*/* | grep -B1 $($line.HbaWWN) | grep -i 'firmware version' | sed 's/Firmware Version:\{0,1\} \(.*\)/\1/'"
							}
							elseif ($hba.driver -match "qla")
							{
								$remoteCommand = "head -8 /proc/scsi/qla*/* | grep -B2 $($hba.device) | grep -i 'firmware version' | head -1 | sed 's/.*Firmware version \(.*\), Driver version.*/\1/'"
							}
							$tmpStr = [string]::Format('& "{0}" {1} "{2}"', $PlinkPath, "-ssh " + $Username + "@" + $esx.Name + " -pw $Password", $remoteCommand + ";exit")

							
							$line.HbaFirmwareVersion = Invoke-Expression $tmpStr
						}
						ELSE
						{
							Write-Warning -Message "PROCESS - $($esx.name) - SSH Server is not enabled"
							$line.HbaFirmwareVersion = ""
						}

						Write-Verbose -Message "PROCESS - $($esx.name) - Output Result"
						Write-Output $line
					}
				}
				ELSE
				{
					Write-verbose -Message "PROCESS - Host: $($hostview.name) - Powered Off"
				}
			} 
			ELSE
			{
				Write-Verbose -Message "PROCESS - Can't find any host"
			}
		}
		CATCH
		{
			Write-Warning -Message "PROCESS - Something Wrong happened"
			IF ($ErrorProcessGetView) { Write-Error -Message "PROCESS - Error while getting the host information" }
			IF ($ErrorProcessGetViewTypeService) { Write-Error -Message "PROCESS - Error while getting the host services information" }
			Write-Error -Message $($Error[0].Exception.Message)
		}
	} 
	END
	{
		Write-Verbose -Message "END - End of Get-VMhostHbaInfo"
	}
}
