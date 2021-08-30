
Function Invoke-WMIEvent 
{

    Param
    (
        [Parameter(Mandatory=$true)][string]
        $Name,
        [Parameter(Mandatory=$true)][string]
        $Command,
        [string]
        $Hour=9,
        [string]
        $Minute=30
    )

    $Filter=Set-WmiInstance -Class __EventFilter -Namespace "root\subscription" -Arguments @{name="$Name";EventNameSpace='root\CimV2';QueryLanguage="WQL";Query="SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA 'Win32_LocalTime' AND TargetInstance.Hour = $Hour AND TargetInstance.Minute = $Minute GROUP WITHIN 60"}; 

    $Consumer=Set-WmiInstance -Namespace "root\subscription" -Class 'CommandLineEventConsumer' -Arguments @{ name="$Name";CommandLineTemplate="$Command";RunInteractively='false'}; 

    Set-WmiInstance -Namespace "root\subscription" -Class __FilterToConsumerBinding -Arguments @{Filter=$Filter;Consumer=$Consumer} 

    Write-Output ""
    Write-Output "[+] WMIEvent added: $Name for $Hour:$Minute"
    Write-Output "[+] Command: $Command"
    Write-Output ""
}

Function Remove-WMIEvent 
{

    Param
    (
        [Parameter(Mandatory=$true)][string]
        $Name
    )

    Get-WmiObject CommandLineEventConsumer -Namespace root\subscription -Filter "name='$Name'" | Remove-WmiObject 

    Write-Output ""
    Write-Output "[+] WMIEvent removed: $Name"
    Write-Output ""
}
Function Get-WMIEvent
{
	gwmi CommandLineEventConsumer -Namespace root\subscription
}