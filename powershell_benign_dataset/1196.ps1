











$userDomain = $env:USERDNSDOMAIN
$computerDomain = Get-WmiObject 'Win32_ComputerSystem' | Select-Object -ExpandProperty Domain
if( (Get-Service -Name MSMQ -ErrorAction SilentlyContinue) -and $userDomain -eq $computerDomain )
{

    $publicQueueName = $null
    $privateQueueName = $null

    function Start-TestFixture
    {
        & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
    }

    function Start-Test
    {
        $publicQueueName = 'CarbonTestRemoveQueue-Public' + [Guid]::NewGuid().ToString()
        $privateQueueName = 'CarbonTestRemoveQueue-Private' + [Guid]::NewGuid().ToString()
        Install-MSMQMessageQueue $publicQueueName 
        Install-MSMQMessageQueue $privateQueueName -Private 
    }

    function Stop-Test
    {
        if( Test-MSMQMessageQueue -Name $publicQueueName )
        {
            [Messaging.MessageQueue]::Delete( (Get-MSMQMessageQueuePath -Name $publicQueueName) )
            Wait-ForQueueDeletion $publicQueueName
        }
        
        if( Test-MSMQMessageQueue -Name $privateQueueName -Private )
        {
            [Messaging.MessageQueue]::Delete( (Get-MSMQMessageQueuePath -Name $privateQueueName -Private) )
            Wait-ForQueueDeletion $privateQueueName -Private 
        }
    }
    
    function Test-ShouldRemovePublicMessageQueue
    {
        Remove-MSMQMessageQueue $publicQueueName
        Assert-False (Test-MSMQMessageQueue $publicQueueName)
    }
    
    function Test-ShouldRemovePrivateMessageQueue
    {
        Remove-MSMQMessageQueue $privateQueueName -Private
        Assert-False (Test-MSMQMessageQueue $privateQueueName -Private)
    }
    
    function Test-ShouldSupportWhatIf
    {
        Remove-MSMQMessageQueue $publicQueueName -WhatIf
        Assert-True (Test-MSMQMessageQueue $publicQueueName)
    }
    
    function Wait-ForQueueDeletion($Name, [Switch]$Private)
    {
        $queueArgs = @{ Name = $Name ; Private = $Private }
        while( Test-MSMQMessageQueue @queueArgs )
        {
            Start-Sleep -Milliseconds 1000
        }
    }
    

}
else
{
    Write-Warning ("Tests for Get-MSMQMessageQueue not run because MSMQ is not installed or the current user's domain ({0}) and the computer's domain ({1}) are different." -f $userDomain,$computerDomain)
}

