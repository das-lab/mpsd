
[CmdletBinding()]
param
(
		[string]$ConsoleTitle = 'NIC Advanced Properties',
		[ValidateSet('Off', 'On')][string]$EnergyEfficientEthernet,
		[ValidateSet('Disabled', 'Tx Enabled', 'Rx Enabled', 'Rx & Tx Enabled')][string]$FlowControl,
		[ValidateSet('Disabled', '4088 Bytes', '9014 Bytes')][string]$JumboPacket,
		[ValidateSet('Disabled', 'Enabled')][string]$LegacySwitchCompatibilityMode,
		[ValidateSet('Disabled', 'Enabled')][string]$LinkSpeedBatterySaver,
		[ValidateSet('Priority & VLAN Disabled', 'Priority Enabled', 'VLAN Enabled', 'Priority & VLAN Enabled')][string]$PriorityVLAN,
		[ValidateSet('Disabled', 'Enabled')][string]$ProtocolARPOffload,
		[ValidateSet('Disabled', 'Enabled')][string]$ProtocolNSOffload,
		[ValidateSet('Auto Negotiation', '10 Mbps Half Duplex', '10 Mbps Full Duplex', '100 Mbps Half Duplex', '100 Mbps Full Duplex', '1.0 Gbps Full Duplex')][string]$SpeedDuplex,
		[ValidateSet('Disabled', 'Enabled')][string]$SystemIdlePowerSaver,
		[ValidateSet('Disabled', 'Enabled')][string]$WakeOnMagicPacket,
		[ValidateSet('Disabled', 'Enabled')][string]$WakeOnPatternMatch
)

function Get-PhysicalNICs {

	
	[CmdletBinding()]
	param ()
	
	
	$NICs = Get-WmiObject Win32_NetworkAdapter -filter "AdapterTypeID = '0' `
	AND PhysicalAdapter = 'true' `
	AND NOT Description LIKE '%Centrino%' `
	AND NOT Description LIKE '%wireless%' `
	AND NOT Description LIKE '%virtual%' `
	AND NOT Description LIKE '%WiFi%' `
	AND NOT Description LIKE '%Bluetooth%'"
	Return $NICs
}

function Get-Platform {

	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	if (Get-WmiObject -Class win32_battery -ComputerName "localhost") {
		$Platform = "Laptop"
	} else {
		$Platform = "Desktop"
	}
	Return $Platform
}

function Set-NICRegistryKey {

	
	[CmdletBinding()]
	param
	(
			$NetworkAdapters
	)
	
	$NetworkAdapterKey = "HKLM:\system\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}"
	foreach ($NetworkAdapter in $NetworkAdapters) {
		If ([int]$NetworkAdapter.DeviceID -lt 10) {
			$NetworkAdapterSubKey = $NetworkAdapterKey + "\" + "000" + $NetworkAdapter.DeviceID
		} else {
			$NetworkAdapterSubKey = $NetworkAdapterKey + "\" + "00" + $NetworkAdapter.DeviceID
		}
		$AdapterProperties = Get-ItemProperty $NetworkAdapterSubKey
		
		If ($EnergyEfficientEthernet -ne "") {
			$AdaptorProperty = 'EEELinkAdvertisement'
			Write-Host "Energy Efficient Ethernet....." -NoNewline
			If ($EnergyEfficientEthernet -eq "On") {
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value 1
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				If ($Value.$AdaptorProperty -eq 1) {
					Write-Host $EnergyEfficientEthernet -ForegroundColor Yellow
				} else {
					Write-Host "Failed" -ForegroundColor Red
				}
			} else {
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value 0
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				If ($Value.$AdaptorProperty -eq 0) {
					Write-Host $EnergyEfficientEthernet -ForegroundColor Yellow
				} else {
					Write-Host "Failed" -ForegroundColor Red
				}
			}
		}
		
		If ($FlowControl -ne "") {
			$AdaptorProperty = '*FlowControl'
			Write-Host "Flow Control....." -NoNewline
			switch ($FlowControl) {
				"Disabled" {
					$AdapterPropertyValue = 0
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value $AdapterPropertyValue
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					If ($Value.$AdaptorProperty -eq $AdapterPropertyValue) {
						Write-Host $FlowControl -ForegroundColor Yellow
					} else {
						Write-Host "Failed" -ForegroundColor Red
					}
				}
				"Tx Enabled" {
					$AdapterPropertyValue = 1
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value $AdapterPropertyValue
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					If ($Value.$AdaptorProperty -eq $AdapterPropertyValue) {
						Write-Host $FlowControl -ForegroundColor Yellow
					} else {
						Write-Host "Failed" -ForegroundColor Red
					}
				}
				"Rx Enabled" {
					$AdapterPropertyValue = 2
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value $AdapterPropertyValue
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					If ($Value.$AdaptorProperty -eq $AdapterPropertyValue) {
						Write-Host $FlowControl -ForegroundColor Yellow
					} else {
						Write-Host "Failed" -ForegroundColor Red
					}
				}
				"Rx & Tx Enabled" {
					$AdapterPropertyValue = 3
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value $AdapterPropertyValue
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					If ($Value.$AdaptorProperty -eq $AdapterPropertyValue) {
						Write-Host $FlowControl -ForegroundColor Yellow
					} else {
						Write-Host "Failed" -ForegroundColor Red
					}
				}
			}
		}
		
		If ($JumboPacket -ne "") {
			$AdaptorProperty = '*JumboPacket'
			Write-Host "Jumbo Packet....." -NoNewline
			switch ($JumboPacket) {
				"Disabled" {
					$AdapterPropertyValue = 1514
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value $AdapterPropertyValue
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					If ($Value.$AdaptorProperty -eq $AdapterPropertyValue) {
						Write-Host $JumboPacket -ForegroundColor Yellow
					} else {
						Write-Host "Failed" -ForegroundColor Red
					}
				}
				"4088 Bytes" {
					$AdapterPropertyValue = 4088
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value $AdapterPropertyValue
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					If ($Value.$AdaptorProperty -eq $AdapterPropertyValue) {
						Write-Host $JumboPacket -ForegroundColor Yellow
					} else {
						Write-Host "Failed" -ForegroundColor Red
					}
				}
				"9014 Bytes" {
					$AdapterPropertyValue = 9014
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value $AdapterPropertyValue
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					If ($Value.$AdaptorProperty -eq $AdapterPropertyValue) {
						Write-Host $JumboPacket -ForegroundColor Yellow
					} else {
						Write-Host "Failed" -ForegroundColor Red
					}
				}
			}
		}
		
		If ($LegacySwitchCompatibilityMode -ne "") {
			$AdaptorProperty = 'LinkNegotiationProcess'
			Write-Host "Legacy Switch Compatibility Mode....." -NoNewline
			If ($LegacySwitchCompatibilityMode -eq "Disabled") {
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value 1
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				If ($Value.$AdaptorProperty -eq 1) {
					Write-Host $LegacySwitchCompatibilityMode -ForegroundColor Yellow
				} else {
					Write-Host "Failed" -ForegroundColor Red
				}
			} else {
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value 2
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				If ($Value.$AdaptorProperty -eq 2) {
					Write-Host $LegacySwitchCompatibilityMode -ForegroundColor Yellow
				} else {
					Write-Host "Failed" -ForegroundColor Red
				}
			}
		}
		
		If ($LinkSpeedBatterySaver -ne "") {
			$Platform = Get-Platform
			If ($Platform -eq "Laptop") {
				$AdaptorProperty = 'AutoPowerSaveModeEnabled'
				Write-Host "Link Speed Battery Saver....." -NoNewline
				If ($LinkSpeedBatterySaver -eq "Disabled") {
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value 0
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					If ($Value.$AdaptorProperty -eq 0) {
						Write-Host $LinkSpeedBatterySaver -ForegroundColor Yellow
					} else {
						Write-Host "Failed" -ForegroundColor Red
					}
				} else {
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value 1
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					If ($Value.$AdaptorProperty -eq 1) {
						Write-Host $LinkSpeedBatterySaver -ForegroundColor Yellow
					} else {
						Write-Host "Failed" -ForegroundColor Red
					}
				}
			}
		}
		
		If ($PriorityVLAN -ne "") {
			$AdaptorProperty = '*PriorityVLANTag'
			Write-Host "Priority VLAN....." -NoNewline
			switch ($PriorityVLAN) {
				"Priority & VLAN Disabled" {
					$AdapterPropertyValue = 0
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value $AdapterPropertyValue
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					If ($Value.$AdaptorProperty -eq $AdapterPropertyValue) {
						Write-Host $PriorityVLAN -ForegroundColor Yellow
					} else {
						Write-Host "Failed" -ForegroundColor Red
					}
				}
				"Priority Enabled" {
					$AdapterPropertyValue = 1
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value $AdapterPropertyValue
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					If ($Value.$AdaptorProperty -eq $AdapterPropertyValue) {
						Write-Host $PriorityVLAN -ForegroundColor Yellow
					} else {
						Write-Host "Failed" -ForegroundColor Red
					}
				}
				"VLAN Enabled" {
					$AdapterPropertyValue = 2
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value $AdapterPropertyValue
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					If ($Value.$AdaptorProperty -eq $AdapterPropertyValue) {
						Write-Host $PriorityVLAN -ForegroundColor Yellow
					} else {
						Write-Host "Failed" -ForegroundColor Red
					}
				}
				"Priority & VLAN Enabled" {
					$AdapterPropertyValue = 3
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value $AdapterPropertyValue
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					If ($Value.$AdaptorProperty -eq $AdapterPropertyValue) {
						Write-Host $PriorityVLAN -ForegroundColor Yellow
					} else {
						Write-Host "Failed" -ForegroundColor Red
					}
				}
			}
		}
		
		If ($ProtocolARPOffload -ne "") {
			$AdaptorProperty = '*PMARPOffload'
			Write-Host "Protocol ARP Offload....." -NoNewline
			If ($ProtocolARPOffload -eq "Disabled") {
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value 0x00000001
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				If ($Value.$AdaptorProperty -eq 0x00000001) {
					Write-Host $ProtocolARPOffload -ForegroundColor Yellow
				} else {
					Write-Host "Failed" -ForegroundColor Red
				}
			} else {
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value 0x00000000
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				If ($Value.$AdaptorProperty -eq 0x00000000) {
					Write-Host $ProtocolARPOffload -ForegroundColor Yellow
				} else {
					Write-Host "Failed" -ForegroundColor Red
				}
			}
		}
		
		If ($ProtocolNSOffload -ne "") {
			$AdaptorProperty = '*PMNSOffload'
			Write-Host "Protocol NS Offload....." -NoNewline
			If ($ProtocolNSOffload -eq "Disabled") {
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value 0x00000001
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				If ($Value.$AdaptorProperty -eq 0x00000001) {
					Write-Host $ProtocolNSOffload -ForegroundColor Yellow
				} else {
					Write-Host "Failed" -ForegroundColor Red
				}
			} else {
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value 0x00000000
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				If ($Value.$AdaptorProperty -eq 0x00000000) {
					Write-Host $ProtocolNSOffload -ForegroundColor Yellow
				} else {
					Write-Host "Failed" -ForegroundColor Red
				}
			}
		}
		
		if ($SpeedDuplex -ne "") {
			$AdaptorProperty = '*SpeedDuplex'
			$AdapterProperties.$AdaptorProperty = $SpeedDuplex
		}
		If ($SpeedDuplex -ne "") {
			$AdaptorProperty = '*SpeedDuplex'
			Write-Host "Speed Duplex....." -NoNewline
			switch ($SpeedDuplex) {
				"Auto Negotiation" {
					$AdapterPropertyValue = 0
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value $AdapterPropertyValue
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					If ($Value.$AdaptorProperty -eq $AdapterPropertyValue) {
						Write-Host $SpeedDuplex -ForegroundColor Yellow
					} else {
						Write-Host "Failed" -ForegroundColor Red
					}
				}
				"10 Mbps Half Duplex" {
					$AdapterPropertyValue = 1
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value $AdapterPropertyValue
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					If ($Value.$AdaptorProperty -eq $AdapterPropertyValue) {
						Write-Host $SpeedDuplex -ForegroundColor Yellow
					} else {
						Write-Host "Failed" -ForegroundColor Red
					}
				}
				"10 Mbps Full Duplex" {
					$AdapterPropertyValue = 2
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value $AdapterPropertyValue
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					If ($Value.$AdaptorProperty -eq $AdapterPropertyValue) {
						Write-Host $SpeedDuplex -ForegroundColor Yellow
					} else {
						Write-Host "Failed" -ForegroundColor Red
					}
				}
				"100 Mbps Half Duplex" {
					$AdapterPropertyValue = 3
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value $AdapterPropertyValue
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					If ($Value.$AdaptorProperty -eq $AdapterPropertyValue) {
						Write-Host $SpeedDuplex -ForegroundColor Yellow
					} else {
						Write-Host "Failed" -ForegroundColor Red
					}
				}
				"100 Mbps Full Duplex" {
					$AdapterPropertyValue = 4
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value $AdapterPropertyValue
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					If ($Value.$AdaptorProperty -eq $AdapterPropertyValue) {
						Write-Host $SpeedDuplex -ForegroundColor Yellow
					} else {
						Write-Host "Failed" -ForegroundColor Red
					}
				}
				"1.0 Gbps Full Duplex" {
					$AdapterPropertyValue = 6
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value $AdapterPropertyValue
					$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
					If ($Value.$AdaptorProperty -eq $AdapterPropertyValue) {
						Write-Host $SpeedDuplex -ForegroundColor Yellow
					} else {
						Write-Host "Failed" -ForegroundColor Red
					}
				}
			}
		}
		
		If ($SystemIdlePowerSaver -ne "") {
			$AdaptorProperty = 'SipsEnabled'
			Write-Host "System Idle Power Saver....." -NoNewline
			If ($SystemIdlePowerSaver -eq "Enabled") {
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value 1
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				If ($Value.$AdaptorProperty -eq 1) {
					Write-Host $SystemIdlePowerSaver -ForegroundColor Yellow
				} else {
					Write-Host "Failed" -ForegroundColor Red
				}
			} else {
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value 0
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				If ($Value.$AdaptorProperty -eq 0) {
					Write-Host $SystemIdlePowerSaver -ForegroundColor Yellow
				} else {
					Write-Host "Failed" -ForegroundColor Red
				}
			}
		}
		
		If ($WakeOnMagicPacket -ne "") {
			$AdaptorProperty = '*WakeOnMagicPacket'
			Write-Host "Wake On Magic Packet....." -NoNewline
			If ($WakeOnMagicPacket -eq "Disabled") {
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value 0x00000001
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				If ($Value.$AdaptorProperty -eq 0x00000001) {
					Write-Host $WakeOnMagicPacket -ForegroundColor Yellow
				} else {
					Write-Host "Failed" -ForegroundColor Red
				}
			} else {
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value 0x00000000
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				If ($Value.$AdaptorProperty -eq 0x00000000) {
					Write-Host $WakeOnMagicPacket -ForegroundColor Yellow
				} else {
					Write-Host "Failed" -ForegroundColor Red
				}
			}
		}
		
		If ($WakeOnPatternMatch -ne "") {
			$AdaptorProperty = '*WakeOnPattern'
			Write-Host "Wake On Pattern Match....." -NoNewline
			If ($WakeOnPatternMatch -eq "Disabled") {
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value 0x00000001
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				If ($Value.$AdaptorProperty -eq 0x00000001) {
					Write-Host $WakeOnPatternMatch -ForegroundColor Yellow
				} else {
					Write-Host "Failed" -ForegroundColor Red
				}
			} else {
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				Set-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty -Value 0x00000000
				$Value = Get-ItemProperty -Path $NetworkAdapterSubKey -Name $AdaptorProperty
				If ($Value.$AdaptorProperty -eq 0x00000000) {
					Write-Host $WakeOnPatternMatch -ForegroundColor Yellow
				} else {
					Write-Host "Failed" -ForegroundColor Red
				}
			}
		}
	}
}

function Set-ConsoleTitle {

	
	[CmdletBinding()]
	param
	(
			[Parameter(Mandatory = $true)][String]$ConsoleTitle
	)
	
	$host.ui.RawUI.WindowTitle = $ConsoleTitle
}

Clear-Host
Set-ConsoleTitle $ConsoleTitle
$NICs = Get-PhysicalNICs
Set-NICRegistryKey -NetworkAdapters $NICs
