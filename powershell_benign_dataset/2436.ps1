


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
