param (
	[Parameter(Mandatory, ValueFromPipelineByPropertyname)]
	[ValidateNotNullOrEmpty()]
	[string]$FirstName,
	
	[Parameter(Mandatory, ValueFromPipelineByPropertyname)]
	[ValidateNotNullOrEmpty()]
	[string]$LastName,
	
	[Parameter(Mandatory, ValueFromPipelineByPropertyname)]
	[ValidateNotNullOrEmpty()]
	[string]$MiddleInitial,
	
	[Parameter(Mandatory, ValueFromPipelineByPropertyname)]
	[ValidateNotNullOrEmpty()]
	[string]$Department,
	
	[Parameter(Mandatory, ValueFromPipelineByPropertyname)]
	[ValidateNotNullOrEmpty()]
	[string]$Title,
	
	[Parameter(ValueFromPipelineByPropertyname)]
	[ValidateNotNullOrEmpty()]
	[string]$Location = 'OU=Corporate Users',
	
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$DefaultGroup = 'XYZCompany',
	
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$DefaultPassword = 'p@$$w0rd12345',
	
	[Parameter()]
	[ValidateScript({ Test-Path -Path $_ })]
	[string]$BaseHomeFolderPath = '\\MEMBERSRV1\Users'
)


$DomainDn = (Get-AdDomain).DistinguishedName

$Username = "$($FirstName.SubString(0, 1))$LastName"


Write-Verbose -Message "Checking if [$($Username)] is available"
if (Get-ADUser -Filter "Name -eq '$Username'")
{
	Write-Warning -Message "The username [$($Username)] is not available. Checking alternate..."
	
	$Username = "$($FirstName.SubString(0, 1))$MiddleInitial$LastName"
	if (Get-ADUser -Filter "Name -eq '$Username'")
	{
		throw "No acceptable username schema could be created"
	}
	else
	{
		Write-Verbose -Message "The alternate username [$($Username)] is available."
	}
}
else
{
	Write-Verbose -Message "The username [$($Username)] is available"
}



$ouDN = "$Location,$DomainDn"
if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouDN'"))
{
	throw "The user OU [$($ouDN)] does not exist. Can't add a user there"
}



if (-not (Get-ADGroup -Filter "Name -eq '$DefaultGroup'"))
{
	throw "The group [$($DefaultGroup)] does not exist. Can't add the user into this group."
}
if (-not (Get-ADGroup -Filter "Name -eq '$Department'"))
{
	throw "The group [$($Department)] does not exist. Can't add the user to this group."
}



$homeFolderPath = "$BaseHomeFolderPath\$UserName"
if (Test-Path -Path $homeFolderPath)
{
	throw "The home folder path [$homeFolderPath] already exists."
}



$NewUserParams = @{
	'UserPrincipalName' = $Username
	'Name' = $Username
	'GivenName' = $FirstName
	'Surname' = $LastName
	'Title' = $Title
	'Department' = $Department
	'SamAccountName' = $Username
	'AccountPassword' = (ConvertTo-SecureString $DefaultPassword -AsPlainText -Force)
	'Enabled' = $true
	'Initials' = $MiddleInitial
	'Path' = "$Location,$DomainDn"
	'ChangePasswordAtLogon' = $true
}
Write-Verbose -Message "Creating the new user account [$($Username)] in OU [$($ouDN)]"
New-AdUser @NewUserParams



Write-Verbose -Message "Adding the user account [$($Username)] to the group [$($DefaultGroup)]"
Add-ADGroupMember -Members $Username -Identity $DefaultGroup
Write-Verbose -Message "Adding the user account [$($Username)] to the group [$($Department)]"
Add-ADGroupMember -Members $Username -Identity $Department



Write-Verbose -message "Creating the home folder [$homeFolderPath]..."
$null = mkdir $homeFolderPath
