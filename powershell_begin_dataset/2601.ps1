



$SqlQuery = "
SELECT server_name + '.' + domain AS Server_Name
	, IP_Address
FROM t_server s
	INNER JOIN t_server_properties sp ON s.server_id = sp.server_id
	INNER JOIN t_server_type_assoc sta ON s.server_id = sta.server_id
	INNER JOIN t_server_type st ON sta.type_id = st.type_id
WHERE st.type_name LIKE '%SQL%'
ORDER BY IP_Address"
	
function Run-Query()
{
	param (
	$SqlQuery
	, $SqlServer = 'SQLUTIL02'
	, $SqlCatalog = 'Status'
	)
	
	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection("Data Source=$SqlServer;Integrated Security=SSPI;Initial Catalog=$SqlCatalog;");
	
	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$SqlCmd.CommandText = $SqlQuery
	$SqlCmd.Connection = $SqlConnection
	
	$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
	$SqlAdapter.SelectCommand = $SqlCmd
	
	$DataSet = New-Object System.Data.DataSet
	$a = $SqlAdapter.Fill($DataSet)
	
	$SqlConnection.Close()
	
	$DataSet.Tables | Select-Object -ExpandProperty Rows
}

$Servers = Run-Query -SQLServer SQLUTIL02 -SQLCatalog Status -SqlQuery $SqlQuery | Select-Object -Property Server_Name, ip_address



foreach($Server in $servers)
	{
	
	
	
	
	
	$Services = Get-Service -DisplayName SQL* -ComputerName $($Server.ip_address) |	Where-Object {$_.Name -like "*SQL*"}
	
	
	foreach ($Service IN $Services)
		{
		
		if ($Service.Status -eq "Running")
			{
			Write-Host "$($Server.server_name), $($Service.Name), $($Service.Status), $($Server.server_name)"
			
			
			}
		elseif ($Service.Status -eq "Stopped")
			{
			Write-Host "$($Server.server_name), $($Service.Name), $($Service.Status), $($Server.server_name)"
			
			
			
			}
		
		}
		
		Write-Host "";
	}