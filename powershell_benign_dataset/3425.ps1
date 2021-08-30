














function Test-AuthorizationEndToEnd
{
    

    
    $roleDefinitions = Get-AzureRmRoleDefinition
    Assert-True { $roleDefinitions.Count -gt 0 }

    
    $roleDefinition = Get-AzureRmRoleDefinition -Name $roleDefinitions[0].Name
    Assert-AreEqual $roleDefinitions[0].Name $roleDefinition.Name

    
    $roleDefinition = Get-AzureRmRoleDefinition -Name "not-there"
    Assert-Null $roleDefinition

    
    $rg = Get-ResourceGroupName
    $defaultSubscription = Get-AzureRmContext
    $principal = $defaultSubscription.ActiveDirectoryUserId
    $roleDef = $(Get-AzureRmRoleDefinition)[0].Name
    $expectedScope = "/subscriptions/" + $defaultSubscription.Subscription.Id

    
    Get-AzureRmRoleAssignment | Remove-AzureRmRoleAssignment
    $roleAssignments = Get-AzureRmRoleAssignment
    Assert-AreEqual 0 $roleAssignments.Count

    
    $signInName = $defaultSubscription.Account.Id
    $roleAssignment = New-AzureRmRoleAssignment -SignInName $signInName -RoleDefinitionName $roleDef
    Assert-AreEqual $expectedScope $roleAssignment.Scope

    $roleAssignment | Remove-AzureRmRoleAssignment

    
    New-AzureRmResourceGroup -Name $rg -Location "westus" -Force
    $expectedScope = $expectedScope + "/resourceGroups/$rg"
    $roleAssignment = New-AzureRmRoleAssignment -SignInName $signInName -RoleDefinitionName $roleDef -ResourceGroup $rg
    Assert-AreEqual $expectedScope $roleAssignment.Scope

    
    Assert-Throws { New-AzureRmRoleAssignment -SignInName $signInName -RoleDefinitionName $roleDef -ResourceGroup $rg }

    $roleAssignment | Remove-AzureRmRoleAssignment
    Remove-AzureRmResourceGroup -Name $rg -Force
}