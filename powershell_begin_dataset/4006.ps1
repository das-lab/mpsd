



























$testReposInfo = @{
    VsoGit = @{
        Name = "AASourceControl-VsoGit"
        RepoUrl = "https://francisco-gamino.visualstudio.com/_git/VsoGit-SwaggerAndCmdletsTests"
        Branch = "preview"
        FolderPath = "Azure/MyRunbooks"
        SourceType = "VsoGit"
        PersonalAccessToken = "3qdxa22lutnhezd4atpna74jn3m7wgo6o6kfbwezjfnvgbjhvoca"
    }

    VsoTfvc =  @{
        Name = "AASourceControl-VsoTfvc"
        RepoUrl = "https://francisco-gamino.visualstudio.com/VsoTfvc-SwaggerAndCmdletsTests/_versionControl"
        FolderPath = "/MyRunbooks"
        SourceType = "VsoTfvc"
        PersonalAccessToken = "3qdxa22lutnhezd4atpna74jn3m7wgo6o6kfbwezjfnvgbjhvoca"
    }

    GitHub = @{
        Name = "AASourceControl-GitHub"
        RepoUrl = "https://github.com/Francisco-Gamino/SwaggerAndCmdletsTests.git"
        Branch = "master"
        FolderPath = "/"
        SourceType = "GitHub"
        PersonalAccessToken = "5fd81166a9ebaebc60da4756f2094a598f1d4c01"
    }
}


$resourceGroupName = "frangom-test"
$automationAccountName = "frangom-sdkCmdlet-tests"





function EnsureSourceControlDoesNotExist
{
    Param 
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name
    )

    $sourceControl = Get-AzAutomationSourceControl -ResourceGroupName $resourceGroupName `
                                                        -AutomationAccountName $automationAccountName `
                                                        -Name $Name `
                                                        -ErrorAction SilentlyContinue
    if ($sourceControl)
    {
        Remove-AzAutomationSourceControl -ResourceGroupName $resourceGroupName `
                                              -AutomationAccountName $automationAccountName `
                                              -Name $Name
    }
}

function WaitForSourceControlSyncJobState
{
    Param 
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Guid]
        $JobId,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ExpectedState
    )

    $waitTimeInSeconds = 2
    $retries = 40
    $jobCompleted = Retry-Function {
        return (Get-AzAutomationSourceControlSyncJob -ResourceGroupName $resourceGroupName `
                                                          -AutomationAccountName $automationAccountName  `
                                                          -Name $Name `
                                                          -JobId $JobId).ProvisioningState -eq $ExpectedState } $null $retries $waitTimeInSeconds

    Assert-True {$jobCompleted -gt 0} "Timeout waiting for provisioning state to reach '$ExpectedState'"
}




function Test-CreateVsoGitSourceControlAndSync
{
    
    $sourceControl = $testReposInfo["VsoGit"]

    try
    {
        EnsureSourceControlDoesNotExist -Name $sourceControl.Name

        
        $accessToken = ConvertTo-SecureString -String $sourceControl.PersonalAccessToken -AsPlainText -Force

        $createdSourceControl = New-AzAutomationSourceControl -ResourceGroupName $resourceGroupName `
                                                                   -AutomationAccountName $automationAccountName  `
                                                                   -Name $sourceControl.Name  `
                                                                   -RepoUrl $sourceControl.RepoUrl `
                                                                   -Branch $sourceControl.Branch `
                                                                   -SourceType $sourceControl.SourceType `
                                                                   -FolderPath $sourceControl.FolderPath `
                                                                   -AccessToken $accessToken `
                                                                   -DoNotPublishRunbook

        
        Assert-NotNull $createdSourceControl "Failed to create VsoGit source control."

        
        $propertiesToValidate = @("Name", "RepoUrl", "SourceType", "Branch", "FolderPath")
        
        foreach ($property in $propertiesToValidate)
        {
            Assert-AreEqual $sourceControl.$property $createdSourceControl.$property `
                "'$property' of created source control does not match. Expected:$($sourceControl.$property). Actual: $($createdSourceControl.$property)"
        }

        
        $updatedSourceControl = Update-AzAutomationSourceControl -ResourceGroupName $resourceGroupName `
                                                                      -AutomationAccountName $automationAccountName  `
                                                                      -Name $sourceControl.Name  `
                                                                      -PublishRunbook $true
        $expectedPropertyValue = "True"
        Assert-AreEqual $updatedSourceControl.PublishRunbook $expectedPropertyValue `
                "'PublishRunbook' property does not match. Expected: $expectedPropertyValue. Actual: $($updatedSourceControl.PublishRunbook)"
        
        
        $jobId = "0bfa6b49-c08c-4b2f-853e-08128c3c86ee"
        Start-AzAutomationSourceControlSyncJob -ResourceGroupName $resourceGroupName `
                                            -AutomationAccountName $automationAccountName  `
                                            -Name $sourceControl.Name `
                                            -JobId $jobId

        WaitForSourceControlSyncJobState -Name $sourceControl.Name -JobId $jobId -ExpectedState Completed

        
        $streams =  Get-AzAutomationSourceControlSyncJobOutput -ResourceGroupName $resourceGroupName `
                                                                    -AutomationAccountName $automationAccountName  `
                                                                    -Name $sourceControl.Name `
                                                                    -JobId $jobId `
                                                                    -Stream Output | % Summary
        
        Assert-True {$streams.count -gt 0} "Failed to get Output stream via Get-AzAutomationSourceControlSyncJobOutput "
    }
    finally
    {
        EnsureSourceControlDoesNotExist -Name $sourceControl.Name
    }
}

function Test-CreateVsoTfvcSourceControlAndSync
{
    
    $sourceControl = $testReposInfo["VsoTfvc"]

    try
    {
        EnsureSourceControlDoesNotExist -Name $sourceControl.Name

        
        $accessToken = ConvertTo-SecureString -String $sourceControl.PersonalAccessToken -AsPlainText -Force

        $createdSourceControl = New-AzAutomationSourceControl -ResourceGroupName $resourceGroupName `
                                                                   -AutomationAccountName $automationAccountName  `
                                                                   -Name  $sourceControl.Name  `
                                                                   -RepoUrl $sourceControl.RepoUrl `
                                                                   -SourceType $sourceControl.SourceType `
                                                                   -FolderPath  $sourceControl.FolderPath `
                                                                   -AccessToken $accessToken `
                                                                   -DoNotPublishRunbook

        
        Assert-NotNull $createdSourceControl "Failed to create VsoGit source control."

        
        $propertiesToValidate = @("Name", "RepoUrl", "SourceType", "FolderPath")
        
        foreach ($property in $propertiesToValidate)
        {
            Assert-AreEqual $sourceControl.$property $createdSourceControl.$property `
                "'$property' of created source control does not match. Expected:$($sourceControl.$property) Actual: $($createdSourceControl.$property)"
        }

        
        $updatedSourceControl = Update-AzAutomationSourceControl -ResourceGroupName $resourceGroupName `
                                                                      -AutomationAccountName $automationAccountName  `
                                                                      -Name $sourceControl.Name  `
                                                                      -PublishRunbook $true
        $expectedPropertyValue = "True"
        Assert-AreEqual $updatedSourceControl.PublishRunbook $expectedPropertyValue `
                "'PublishRunbook' property does not match. Expected: $expectedPropertyValue. Actual: $($updatedSourceControl.PublishRunbook)"
        
        
        $jobId = "27dcdb17-1f65-42e9-9eeb-088a5f50eeb8"
        Start-AzAutomationSourceControlSyncJob -ResourceGroupName $resourceGroupName `
                                            -AutomationAccountName $automationAccountName  `
                                            -Name $sourceControl.Name `
                                            -JobId $jobId

        WaitForSourceControlSyncJobState -Name $sourceControl.Name -JobId $jobId -ExpectedState Completed

        
        $streams =  Get-AzAutomationSourceControlSyncJobOutput -ResourceGroupName $resourceGroupName `
                                                                    -AutomationAccountName $automationAccountName  `
                                                                    -Name $sourceControl.Name `
                                                                    -JobId $jobId `
                                                                    -Stream Output | % Summary
        
        Assert-True {$streams.count -gt 0} "Failed to get Output stream via Get-AzAutomationSourceControlSyncJobOutput "
    }
    finally
    {
        EnsureSourceControlDoesNotExist -Name $sourceControl.Name
    }
}

function Test-CreateGitHubSourceControlAndSync
{
    
    $sourceControl = $testReposInfo["GitHub"]

    try
    {
        EnsureSourceControlDoesNotExist -Name $sourceControl.Name

        
        $accessToken = ConvertTo-SecureString -String $sourceControl.PersonalAccessToken -AsPlainText -Force

        $createdSourceControl = New-AzAutomationSourceControl -ResourceGroupName $resourceGroupName `
                                                                   -AutomationAccountName $automationAccountName  `
                                                                   -Name $sourceControl.Name  `
                                                                   -RepoUrl $sourceControl.RepoUrl `
                                                                   -Branch $sourceControl.Branch `
                                                                   -SourceType $sourceControl.SourceType `
                                                                   -FolderPath $sourceControl.FolderPath `
                                                                   -AccessToken $accessToken `
                                                                   -DoNotPublishRunbook

        
        Assert-NotNull $createdSourceControl "Failed to create VsoGit source control."

        
        $propertiesToValidate = @("Name", "RepoUrl", "SourceType", "Branch", "FolderPath")
        
        foreach ($property in $propertiesToValidate)
        {
            Assert-AreEqual $sourceControl.$property $createdSourceControl.$property `
                "'$property' of created source control does not match. Expected:$($sourceControl.$property) Actual: $($createdSourceControl.$property)"
        }

        
        $updatedSourceControl = Update-AzAutomationSourceControl -ResourceGroupName $resourceGroupName `
                                                                      -AutomationAccountName $automationAccountName  `
                                                                      -Name $sourceControl.Name  `
                                                                      -PublishRunbook $true
        $expectedPropertyValue = "True"
        Assert-AreEqual $updatedSourceControl.PublishRunbook $expectedPropertyValue `
                "'PublishRunbook' property does not match. Expected: $expectedPropertyValue. Actual: $($updatedSourceControl.PublishRunbook)"
        
        
        $jobId = "f7dd56e6-0da3-442a-b1c5-3027065c7786"
        Start-AzAutomationSourceControlSyncJob -ResourceGroupName $resourceGroupName `
                                            -AutomationAccountName $automationAccountName  `
                                            -Name $sourceControl.Name `
                                            -JobId $jobId

        WaitForSourceControlSyncJobState -Name $sourceControl.Name -JobId $jobId -ExpectedState Completed

        
        $streams =  Get-AzAutomationSourceControlSyncJobOutput -ResourceGroupName $resourceGroupName `
                                                                    -AutomationAccountName $automationAccountName  `
                                                                    -Name $sourceControl.Name `
                                                                    -JobId $jobId `
                                                                    -Stream Output | % Summary
        
        Assert-True {$streams.count -gt 0} "Failed to get Output stream via Get-AzAutomationSourceControlSyncJobOutput "
    }
    finally
    {
        EnsureSourceControlDoesNotExist -Name $sourceControl.Name
    }
}