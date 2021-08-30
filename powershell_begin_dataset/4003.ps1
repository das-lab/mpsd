




$script:AutomationAccountName = "mirichmo-aatest-WUS2"
$script:ResourceGroupName = "mirichmo-aatest-wus2-rg"
$script:TestRunbookName = "TestRunbookName"
$script:TestRunbookTwoParamsName = "TestRunbookTwoParamsName"

function Create-PublishedRunbook {
    param(
        [Parameter (Mandatory = $true)]
        [String] $Name,
    
        [Parameter (Mandatory = $true)]
        [String] $RunbookScript
    )

    $runbookScriptFile = ".\RunbookFile.ps1"
    Set-Content -Path $runbookScriptFile -Value $RunbookScript
    Import-AzAutomationRunbook -ResourceGroupName $script:ResourceGroupName -AutomationAccountName $script:AutomationAccountName -Name $Name -Type PowerShell -Path $runbookScriptFile
    Publish-AzAutomationRunbook -ResourceGroupName $script:ResourceGroupName -AutomationAccountName $script:AutomationAccountName -Name $Name
    Remove-Item $runbookScriptFile -ErrorAction SilentlyContinue
}

function Initialize-TestEnvironment {
    Create-PublishedRunbook -Name $script:TestRunbookName -RunbookScript 'Write-Output "No parameters webhook"'

    Create-PublishedRunbook -Name $script:TestRunbookTwoParamsName -RunbookScript 'param
    (
        [Parameter (Mandatory = $true)]
        [String] $First,
    
        [Parameter (Mandatory = $true)]
        [Int] $Second
    )
    
    if ($First -and $Second)
    {
        Write-Output -InputObject ("Webhook data First={0} Second={1}." -f $First, $Second)
    }
    else
    {
        Write-Error "WebhookData is NULL!!!"
    }'
}

function Remove-TestEnvironment {
    
    $runbook = Get-AzAutomationRunbook -ResourceGroupName $script:ResourceGroupName -AutomationAccountName $script:AutomationAccountName -Name $script:TestRunbookTwoParamsName -ErrorAction SilentlyContinue
    if ($null -ne $runbook)
    {
        $runbook | Remove-AzAutomationRunbook -Force
    }

    $runbook = Get-AzAutomationRunbook -ResourceGroupName $script:ResourceGroupName -AutomationAccountName $script:AutomationAccountName -Name $script:TestRunbookName -ErrorAction SilentlyContinue
    if ($null -ne $runbook)
    {
        $runbook | Remove-AzAutomationRunbook -Force
    }
}




function Compare-ImmutableProperties {
    param(
        $webhookOne,
        $webhookTwo
    )

    Assert-AreEqual $webhookOne.AutomationAccountName $webhookTwo.AutomationAccountName
    Assert-AreEqual $webhookOne.ResourceGroupName $webhookTwo.ResourceGroupName
    Assert-AreEqual $webhookOne.RunbookName $webhookTwo.RunbookName
    Assert-AreEqual $webhookOne.Name $webhookTwo.Name
    Assert-AreEqual $webhookOne.CreationTime $webhookTwo.CreationTime
}



function Test-BasicCrud {
    try {
        $testWebhookName = "testWebhookName-ed41c2d4-0055-41e8-b48d-800042358f21"
    
        Initialize-TestEnvironment

        $wh = New-AzAutomationWebhook `
            -AutomationAccountName $script:AutomationAccountName `
            -ResourceGroupName $script:ResourceGroupName `
            -RunbookName $script:TestRunbookName `
            -Name $testWebhookName `
            -IsEnabled $false `
            -ExpiryTime (get-date).AddDays(1) `
            -Force

        Assert-AreEqual $wh.AutomationAccountName $script:AutomationAccountName
        Assert-AreEqual $wh.ResourceGroupName $script:ResourceGroupName
        Assert-AreEqual $wh.RunbookName  $script:TestRunbookName
        Assert-AreEqual $wh.Name $testWebhookName
        Assert-True { $wh.WebhookURI -match ".azure-automation.net/webhooks\?token=" }

        $getWebhook = Get-AzAutomationWebhook `
            -AutomationAccountName $script:AutomationAccountName `
            -ResourceGroupName $script:ResourceGroupName `
            -Name $testWebhookName

        Compare-ImmutableProperties $getWebhook $wh
        Assert-AreEqual $getWebhook.IsEnabled $wh.IsEnabled
        
        $setWebhook = Set-AzAutomationWebhook `
            -AutomationAccountName $script:AutomationAccountName `
            -ResourceGroupName $script:ResourceGroupName `
            -Name $testWebhookName `
            -IsEnabled $true

        Compare-ImmutableProperties $setWebhook $wh
        Assert-True { $setWebhook.IsEnabled } 
        
        Remove-AzAutomationWebhook `
            -AutomationAccountName $script:AutomationAccountName `
            -ResourceGroupName $script:ResourceGroupName `
            -Name $testWebhookName

        $getWebhook = Get-AzAutomationWebhook `
            -AutomationAccountName $script:AutomationAccountName `
            -ResourceGroupName $script:ResourceGroupName `
            -Name $testWebhookName `
            -ErrorAction SilentlyContinue 

        Assert-Null $getWebhook
    }
    finally {
        $webhook = Get-AzAutomationWebhook `
            -AutomationAccountName $script:AutomationAccountName `
            -ResourceGroupName $script:ResourceGroupName `
            -Name $testWebhookName `
            -ErrorAction SilentlyContinue

        if ($webhook) {
            Remove-AzAutomationWebhook `
                -AutomationAccountName $script:AutomationAccountName `
                -ResourceGroupName $script:ResourceGroupName `
                -Name $testWebhookName `
                -ErrorAction SilentlyContinue
        }

        Remove-TestEnvironment
    }
}


function Test-NewWithParameters {
    try {
        $testWebhookName = "testWebhookName-3fa8650e-d364-4c4a-8a95-9dd13766ef1b"

        Initialize-TestEnvironment

        $wh = New-AzAutomationWebhook `
            -AutomationAccountName $script:AutomationAccountName `
            -ResourceGroupName $script:ResourceGroupName `
            -RunbookName $script:TestRunbookTwoParamsName `
            -Name $testWebhookName `
            -IsEnabled $false `
            -ExpiryTime (get-date).AddDays(1) `
            -Parameters @{"First"="NameParam";"Second"=1337} `
            -Force

        Assert-AreEqual $wh.AutomationAccountName $script:AutomationAccountName
        Assert-AreEqual $wh.ResourceGroupName $script:ResourceGroupName
        Assert-AreEqual $wh.RunbookName $script:TestRunbookTwoParamsName
        Assert-AreEqual $wh.Name $testWebhookName
        Assert-True { $wh.WebhookURI -match ".azure-automation.net/webhooks\?token=" }

        $getWebhook = Get-AzAutomationWebhook `
            -AutomationAccountName $script:AutomationAccountName `
            -ResourceGroupName $script:ResourceGroupName `
            -Name $testWebhookName

        Compare-ImmutableProperties $getWebhook $wh
        Assert-AreEqual $getWebhook.IsEnabled $wh.IsEnabled

        Assert-AreEqual $getWebhook.Parameters["First"] "NameParam"
        Assert-AreEqual $getWebhook.Parameters["Second"] 1337
    }
    finally {
        $webhook = Get-AzAutomationWebhook `
            -AutomationAccountName $script:AutomationAccountName `
            -ResourceGroupName $script:ResourceGroupName `
            -Name $testWebhookName `
            -ErrorAction SilentlyContinue

        if ($webhook) {
            Remove-AzAutomationWebhook `
                -AutomationAccountName $script:AutomationAccountName `
                -ResourceGroupName $script:ResourceGroupName `
                -Name $testWebhookName `
                -ErrorAction SilentlyContinue
        }

        Remove-TestEnvironment
    }
}


function Test-NewFailureParams {
    try {
        $testWebhookName = "testWebhookName-54ed2ef9-c540-4534-9c2c-d924d8e9de58"
    
        Initialize-TestEnvironment

        try {
            $wh = New-AzAutomationWebhook `
                -AutomationAccountName $script:AutomationAccountName `
                -ResourceGroupName $script:ResourceGroupName `
                -RunbookName $script:TestRunbookTwoParamsName `
                -Name $testWebhookName `
                -IsEnabled $false `
                -ExpiryTime (get-date).AddDays(1) `
                -Parameters @{"Second"=1337} `
                -Force `
                -ErrorAction Stop
            throw "Expected exception not thrown"
        }
        catch {
            Assert-True { $wh -eq $null -OR $wh -eq "" }
            Assert-AreEqual $_.FullyQualifiedErrorId "Microsoft.Azure.Commands.Automation.Cmdlet.NewAzureAutomationWebhook" 
            Assert-True { $_.CategoryInfo -match "ArgumentException" }
        }
    }
    finally {
        $webhook = Get-AzAutomationWebhook `
            -AutomationAccountName $script:AutomationAccountName `
            -ResourceGroupName $script:ResourceGroupName `
            -Name $testWebhookName `
            -ErrorAction SilentlyContinue

        if ($webhook) {
            Remove-AzAutomationWebhook `
                -AutomationAccountName $script:AutomationAccountName `
                -ResourceGroupName $script:ResourceGroupName `
                -Name $testWebhookName `
                -ErrorAction SilentlyContinue
        }

        Remove-TestEnvironment
    }
}


function Test-GetSuccessScenarios {
    try {
        $testWebhookName = "testWebhookName-5398a8e5-a019-449b-bd90-147bb27d7f71"

        Initialize-TestEnvironment

        $webhook = New-AzAutomationWebhook `
            -AutomationAccountName $script:AutomationAccountName `
            -ResourceGroupName $script:ResourceGroupName `
            -RunbookName $script:TestRunbookTwoParamsName `
            -Name $testWebhookName `
            -IsEnabled $false `
            -ExpiryTime (get-date).AddDays(1) `
            -Parameters @{"First"="NameParam";"Second"=1337} `
            -Force

        
        $results = Get-AzAutomationWebhook `
            -AutomationAccountName $script:AutomationAccountName `
            -ResourceGroupName $script:ResourceGroupName `
            -Name $testWebhookName

        Assert-AreEqual $results.Count 1
        Assert-AreEqual $results[0].AutomationAccountName $script:AutomationAccountName
        Assert-AreEqual $results[0].ResourceGroupName $script:ResourceGroupName
        Assert-AreEqual $results[0].Name $testWebhookName
        Assert-AreEqual $results[0].RunbookName $script:TestRunbookTwoParamsName
        Assert-AreEqual $results[0].Parameters.Count 2

        
        $results = Get-AzAutomationWebhook `
            -AutomationAccountName $script:AutomationAccountName `
            -ResourceGroupName $script:ResourceGroupName

        Assert-AreEqual $results.Count 1
        Assert-AreEqual $results[0].AutomationAccountName $script:AutomationAccountName
        Assert-AreEqual $results[0].ResourceGroupName $script:ResourceGroupName
        Assert-AreEqual $results[0].Name $testWebhookName
        Assert-AreEqual $results[0].RunbookName $script:TestRunbookTwoParamsName

        
        $results = Get-AzAutomationWebhook `
            -AutomationAccountName $script:AutomationAccountName `
            -ResourceGroupName $script:ResourceGroupName `
            -RunbookName $script:TestRunbookTwoParamsName

        Assert-AreEqual $results.Count 1
        Assert-AreEqual $results[0].AutomationAccountName $script:AutomationAccountName
        Assert-AreEqual $results[0].ResourceGroupName $script:ResourceGroupName
        Assert-AreEqual $results[0].Name $testWebhookName
        Assert-AreEqual $results[0].RunbookName $script:TestRunbookTwoParamsName
    }
    finally {
        $webhook = Get-AzAutomationWebhook `
            -AutomationAccountName $script:AutomationAccountName `
            -ResourceGroupName $script:ResourceGroupName `
            -Name $testWebhookName `
            -ErrorAction SilentlyContinue

        if ($webhook) {
            Remove-AzAutomationWebhook `
                -AutomationAccountName $script:AutomationAccountName `
                -ResourceGroupName $script:ResourceGroupName `
                -Name $testWebhookName `
                -ErrorAction SilentlyContinue
        }

        Remove-TestEnvironment
    }
}


function Test-GetFailureScenarios {
    
    try {
        $results = Get-AzAutomationWebhook `
            -ResourceGroupName "DoesntExistWebhookRG" `
            -AutomationAccountName $script:AutomationAccountName `
            -ErrorAction Stop 
        throw "Expected exception not thrown"
    }
    catch {
        Assert-AreEqual $results.Count 0
        Assert-AreEqual $_.FullyQualifiedErrorId "Microsoft.Azure.Commands.Automation.Cmdlet.GetAzureAutomationWebhook"
        Assert-True { $_.CategoryInfo -match "ErrorResponseException" }
    }

    
    try {
        $results = Get-AzAutomationWebhook `
            -Name "DoesntExistWebhook" `
            -ResourceGroupName $script:ResourceGroupName `
            -AutomationAccountName $script:AutomationAccountName `
            -ErrorAction Stop 
        throw "Expected exception not thrown"
    }
    catch {
        Assert-AreEqual $results.Count 0
        Assert-AreEqual $_.FullyQualifiedErrorId "Microsoft.Azure.Commands.Automation.Cmdlet.GetAzureAutomationWebhook"
        Assert-True { $_.CategoryInfo -match "ResourceNotFoundException" }
    }

    
    try {
        $results = Get-AzAutomationWebhook `
            -RunbookName "DoesntExistWebhookRunbook" `
            -ResourceGroupName $script:ResourceGroupName `
            -AutomationAccountName $script:AutomationAccountName `
            -ErrorAction Stop 
            Assert-AreEqual $results.Count 0
        }
    catch {
        Assert-AreEqual $_.FullyQualifiedErrorId "Microsoft.Azure.Commands.Automation.Cmdlet.GetAzureAutomationWebhook"
        Assert-True { $_.CategoryInfo -match "ResourceNotFoundException" }
    }
}
