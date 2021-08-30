
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SqlWmiManagement')| Out-Null
function Set-SqlServiceAccount{
    param([string[]] $Instance
        ,[System.Management.Automation.PSCredential]$ServiceAccount
        ,[ValidateSet('SqlServer','SqlAgent')] $service = 'SqlServer'
    )
    
    
    $account =$ServiceAccount.GetNetworkCredential().Domain +'\'+ $ServiceAccount.GetNetworkCredential().UserName
    
    
    foreach($i in $Instance){
        
        $HostName = ($i.Split('\'))[0]
        $InstanceName = ($i.Split('\'))[1]

        
        $sqlsvc = if($InstanceName){"MSSQL`$$InstanceName"}else{'MSSQLSERVER'}
        $agtsvc = if($InstanceName){"SQLAGENT`$$InstanceName"}else{'SQLSERVERAGENT'}

        $ServiceName = switch($service){
            'SqlServer'{$sqlsvc}
            'SqlAgent'{$agtsvc}
        }

        
        $smowmi = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer $HostName
        $wmisvc = $smowmi.Services | Where-Object {$_.Name -eq $ServiceName}
        $wmisvc.SetServiceAccount($account,$ServiceAccount.GetNetworkCredential().Password)
    
        
        $wmiagt = $smowmi.Services | Where-Object {$_.Name -eq $agtsvc}
        if($wmiagt.ServiceSatus -ne 'Running'){$wmiagt.Start()}
    }
}


