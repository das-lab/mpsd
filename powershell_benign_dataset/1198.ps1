













$userDomain = $env:USERDNSDOMAIN
$computerDomain = Get-WmiObject 'Win32_ComputerSystem' | Select-Object -ExpandProperty Domain
if( (Get-Service -Name MSMQ -ErrorAction SilentlyContinue) -and $userDomain -eq $computerDomain )
{

    $publicQueueName = 'CarbonTestGetQueue-Public'
    $privateQueueName = 'CarbonTestGetQueue-Private'

    function Start-TestFixture
    {
        & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
    }

    function Start-Test
    {
        Install-MSMQMessageQueue $publicQueueName 
        Install-MSMQMessageQueue $privateQueueName -Private 
    }

    function Stop-Test
    {
        [Messaging.MessageQueue]::Delete(".\$publicQueueName")
        [Messaging.MessageQueue]::Delete(".\Private`$\$privateQueueName")
    }

    function Test-ShouldFindExistingPublicQueue
    {
        Assert-True (Test-MSMQMessageQueue $publicQueueName)
    }

    function Test-ShouldFindExistingPrivateQueue
    {
        Assert-True (Test-MSMQMessageQueue $privateQueueName -Private)
    }

    function Test-ShouldNotFindNonExistentPublicQueue
    {
        Assert-False (Test-MSMQMessageQueue "IDoNotExist")
    }
    function Test-ShouldNotFindNonExistentPrivateQueue
    {
        Assert-False (Test-MSMQMessageQueue "IDoNotExist" -Private)
    }
}
else
{
    Write-Warning ("Tests for Get-MSMQMessageQueue not run because MSMQ is not installed or the current user's domain ({0}) and the computer's domain ({1}) are different." -f $userDomain,$computerDomain)
}

