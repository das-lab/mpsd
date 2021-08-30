
function Reset-CMsmqQueueManagerID
{
    
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-Verbose "Resetting MSMQ Queue Manager ID."
    Write-Verbose "Stopping MSMQ."
    Stop-Service MSMQ -Force
    
    $QMIdPath = "HKLM:\SOFTWARE\Microsoft\MSMQ\Parameters\MachineCache"
    $QMIdName = "QMId"
   	$QMId = Get-CRegistryKeyValue -Path $QMIdPath -Name $QMIdName
   	Write-Verbose "Existing QMId: $QMId"
   	Remove-CRegistryKeyValue -Path $QMIdPath -Name $QMIdName
    
    $MSMQSysPrepPath = "HKLM:\SOFTWARE\Microsoft\MSMQ\Parameters"
    $MSMQSysPrepName = "SysPrep"
   	Remove-CRegistryKeyValue -Path $MSMQSysPrepPath -Name $MSMQSysPrepName
	Set-CRegistryKeyValue -Path $MSMQSysPrepPath -Name $MSMQSysPrepName -DWord 1
    
    Write-Verbose "Starting MSMQ"
    Start-Service MSMQ
    
	$QMId = Get-CRegistryKeyValue -Path $QMIdPath -Name $QMIdName
    Write-Verbose "New QMId: $QMId"
}

