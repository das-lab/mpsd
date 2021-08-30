
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null

function Get-FreeSpace{


    param([string] $hostname = ($env:COMPUTERNAME))

	gwmi win32_volume -computername $hostname  | where {$_.drivetype -eq 3} | Sort-Object name `
	 | ft name,@{l="Size(GB)";e={($_.capacity/1gb).ToString("F2")}},@{l="Free Space(GB)";e={($_.freespace/1gb).ToString("F2")}},@{l="% Free";e={(($_.Freespace/$_.Capacity)*100).ToString("F2")}}

}

function Test-SQLConnection{
    param([parameter(mandatory=$true)][string] $InstanceName)

    $smosrv = new-object ('Microsoft.SqlServer.Management.Smo.Server') $InstanceName
    $return = New-Object –TypeName PSObject –Prop @{'InstanceName'=$InstanceName;'StartupTime'=$null}
    try{
        $check=$smosrv.Databases['tempdb'].ExecuteWithResults('SELECT @@SERVERNAME')
        $return.InstanceName = $smosrv.Name
        $return.StartupTime = $smosrv.Databases['tempdb'].CreateDate
    }
    catch{
        
    }

    return $return
}

function Test-SQLAGRole{
    param([parameter(mandatory=$true,ValueFromPipeline=$true)][string] $ComputerName)


    If(Test-SQLConnection -ComputerName $computerName){
        $smosrv = new-object ('Microsoft.SqlServer.Management.Smo.Server') $ComputerName
        if($smosrv.AvailabilityGroups[0].PrimaryReplicaServerName -eq $smosrv.ComputerNamePhysicalNetBIOS){return "Primary"}
        else{"Secondary"}
    }
    else{
        return "Unreachable"
    }
}