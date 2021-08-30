


[CmdletBinding()]
[OutputType([Amazon.Route53.Model.ChangeInfo])]
param
(
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$Name,
	
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$ZoneName,
	
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$AliasName,
	
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[int]$TTL = 300,
	
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$AWSRegion = 'us-west-1'
	
)
begin
{
	try
	{
		if ((Get-AWSCredentials -ListStoredCredentials) -notcontains 'default')
		{
			throw 'No default AWS credentials set. To set use the "Set-AWSCredentials -AccessKey <YourKey> -SecretKey <YourKey> -StoreAs default" command'
		}
		Initialize-AWSDefaults -ProfileName default -Region $AWSRegion
	}
	catch 
	{
		$PSCmdlet.ThrowTerminatingError($_)
	}	
}
process {
	try
	{
		
		$hostedZones = Get-R53HostedZones
		if ($hostedZones.Name.TrimEnd('.') -notcontains $ZoneName)
		{
			throw "Could not find any hosted DNS zones matching the domain name [$($ZoneName)]"
		}
		
		$hostedZone = $hostedZones | where { $_.Name -eq "$ZoneName." }
		
		
		$recordSet = New-Object -TypeName Amazon.Route53.Model.ResourceRecordSet
		$recordSet.Name = "$Name.$ZoneName."
		$recordSet.Type = 'CNAME'
		$recordSet.TTL = $TTL
		$recordSet.ResourceRecords.Add((New-Object Amazon.Route53.Model.ResourceRecord($AliasName)))
		$action = New-Object -TypeName Amazon.Route53.Model.Change
		$action.Action = 'CREATE'
		$action.ResourceRecordSet = $recordSet
		Edit-R53ResourceRecordSet -HostedZoneId $hostedZone.ID -ChangeBatch_Change $action
		
	}
	catch
	{
		$PSCmdlet.ThrowTerminatingError($_)
	}
}