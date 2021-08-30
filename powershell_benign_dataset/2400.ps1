

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
