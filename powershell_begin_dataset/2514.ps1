[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
$scrp = New-Object Microsoft.SqlServer.Management.Smo.ScriptingOptions
$scrp.IncludeDatabaseContext = $true;

$dt = get-date
$logFile = "C:\Dexma\Logs\IndexMovementScript_"+ $dt.Year.ToString() + $dt.Month.ToString() + $dt.Day.ToString() + $dt.Hour.ToString()+ $dt.Minute.ToString() + ".sql"
$errorLogFile = "C:\Dexma\Logs\IndexMovementScriptFailures_"+ $dt.Year.ToString() + $dt.Month.ToString() + $dt.Day.ToString() + $dt.Hour.ToString()+ $dt.Minute.ToString() + ".sql"

$sqlInstanceName = "XSQLUTIL18";


$sqlServer = New-Object -typeName Microsoft.SqlServer.Management.Smo.Server -argumentList "$sqlInstanceName"


$userDbs = $sqlServer.Databases | Where-Object {$_.IsSystemObject -eq $false -and $_.ReadOnly -eq $false} 

function Invoke-Sqlcmd3
{
    param(
    [string]$ServerInstance,
    [string]$Query
    )
	$QueryTimeout=30
    $conn=new-object System.Data.SqlClient.SQLConnection
	$constring = "Server=" + $ServerInstance + ";Integrated Security=True"
	$conn.ConnectionString=$constring
    	$conn.Open()
		if($conn){
    	$cmd=new-object system.Data.SqlClient.SqlCommand($Query,$conn)
    	$cmd.CommandTimeout=$QueryTimeout
    	$ds=New-Object system.Data.DataSet
    	$da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
    	[void]$da.fill($ds)
    	$conn.Close()
    	$ds.Tables[0]
	}
}

foreach($currentDB in $userDbs)
{
 
 
 	foreach($tb in $currentDB.Tables | Where-Object {$_.HasIndex -eq $true -and $_.IsSystemObject -eq $false} `
		| Select-Object name,indexes )
 	{ 
 		foreach($ind in $tb.Indexes | Where-Object{$_.IsClustered -eq $false -and $_.IsXmlIndex -eq $false})
 		{ 
			if($ind.FileGroup -eq "PRIMARY")
 			{
			 try
			 {

				
				$scrp.IncludeIfNotExists = $true; 
				$scrp.DriAll = $true;
				$scrp.ScriptDrops = $true; 
				$sql = $ind.Script($scrp); 

				
				$ind.FileGroup = "SECONDARY" 
				$scrp.IncludeIfNotExists = $false; 
				$scrp.ScriptDrops = $false; 
				
				
				$sql += $ind.Script($scrp);  

 				
 				$sql | Out-File $logFile -append 

 				
 				
 			}
 			catch
			{
				$errorMsg = "No File in FileGroup:" + $currentDB.Name + ":" + $ind.Name
				$errorMsg | Out-File $errorLogFile -append 
			}	
 		   } 
 		} 
 	} 
 
}