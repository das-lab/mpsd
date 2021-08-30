





param(
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$ApiManagementServiceName,

	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$ApiManagementServiceResourceGroup,

	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$ApiMatchPattern,

	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$AzureRoleName,

	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$AzureRoleDescription,

	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$Rights,

	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$PrincipalName,

	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$AzurSubscriptionId = (Get-AzureRmSubscription).SubscriptionId
)


$azrContext = New-AzureRmApiManagementContext -ResourceGroupName $ApiManagementServiceResourceGroup -ServiceName $ApiManagementServiceName


if (-not ($apis = @(Get-AzureRmApiManagementApi -Context $azrContext).where({ $_.Name -match $ApiMatchPattern }))) {
	throw "No APIs found matching [$($ApiMatchPattern)] under API service gateway [$($ApiManagementServiceName)]"
}


$scopes = $apis.ApiId | foreach {
	$strFormat = $AzureSubscriptionId,$ApiManagementServiceResourceGroup,$ApiManagementServiceName,$_
	'/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.ApiManagement/service/{2}/apis/{3}' -f $strFormat
}


if (-not (Get-AzureRmRoleDefinition -Name $AzureRoleName)) {
	Write-Verbose -Message "No role with name [$($AzureRoleName)] found. Creating..."

	switch ($APIRights) {
		'Read' {
			
			$role = Get-AzureRmRoleDefinition 'API Management Service Reader Role'
			$role.Actions.Add('Microsoft.ApiManagement/service/apis/read')
		}
		default {
			throw "Unrecognized input: [$_]"
		}
	}

	$role.Id = $null
	$role.Name = $AzureRoleName
	$role.Description = $AzureRoleDescription
	$role.AssignableScopes.Clear()

	$scopes | foreach {
		$role.AssignableScopes.Add($_)
	}
	New-AzureRmRoleDefinition -Role $role
}


$principal = Get-AzureRmADGroup -SearchString $PrincipalName
$principalId = $principal.Id.Guid

$scopes | foreach {
	New-AzureRmRoleAssignment -ObjectId $principalId -RoleDefinitionName $AzureRoleName -Scope $_
}
