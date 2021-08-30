
[void][reflection.assembly]::LoadWithPartialName( "Microsoft.SqlServer.Smo" );
$smoApp = [Microsoft.SqlServer.Management.Smo.SmoApplication];
$smoApp::EnumAvailableSqlServers($false);


$SQL = [System.Data.Sql.SqlDataSourceEnumerator]::Instance.GetDataSources() | `
foreach {
"INSERT INTO dbo.FoundSQLServers VALUES ('$($_.ServerName)', '$($_.InstanceName)', '$($_.IsClustered)', '$($_.Version)')" `
>> C:\Dexma\Logs\INSERTFoundSQLServers.sql
        };