



cls

function invoke-sql
{

  param(
    [Parameter(Mandatory = $True)]
    [string]$Query,
    [Parameter(Mandatory = $True)]
    [string]$DBName,
    [Parameter(Mandatory = $True)]
    [string]$DBServerName
  )

  
  $QueryTimeout = 36000 
  $ConnectionTimeout = 36000 

  
  $conn = New-Object System.Data.SqlClient.SQLConnection
  $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $DBServerName,$DBName,$ConnectionTimeout
  $conn.ConnectionString = $ConnectionString
  $conn.Open()
  $cmd = New-Object system.Data.SqlClient.SqlCommand ($Query,$conn)
  $cmd.CommandTimeout = $QueryTimeout
  $ds = New-Object system.Data.DataSet
  $da = New-Object system.Data.SqlClient.SqlDataAdapter ($cmd)
  [void]$da.fill($ds)
  $conn.Close()
  $results = $ds.Tables[0]

  $results
}


$SQLSERVER = 'PSQLLFC6';

$SQL = "SELECT  name
		FROM    sys.[databases]
		WHERE   name NOT IN ( 'master', 'tempdb', 'model', 'msdb', 'dbamaint',
                      'distribution' )";

$DBs = @();

$DBs = invoke-sql -DBServerName $SQLSERVER -DBName 'master' -Query $SQL;

$Retain = (Get-Date).AddDays(-7)

foreach ( $DB in $DBs ) {

$a = get-date
$b = $a.AddMinutes(-15)

$BAKSourcePath = '\\' + $SQLSERVER + '\e$\MSSQL10.MSSQLSERVER\MSSQL\BAK\'
$BAKDestPath = '\\pdoc4\SQLBackups\'
$ClientSrcPath = $BAKSourcePath + $DB.name + '\'


if (!(Test-Path -Path $ClientSrcPath)){
	Write-Host "$ClientSrcPath not found!"	
	break;
	}
ELSE {
	
	$CopyFrom = @(Get-ChildItem -path "$ClientSrcPath*.bak" ) | Where-Object{$_.LastWriteTime -lt $b}
	}



Write-Host

$ClientDestPath = $BAKDestPath + $DB.name + '\'


if (!(Test-Path -Path $ClientDestPath)) {
	Write-Host "$ClientDestPath not found!  Creating directory..."
	New-Item -ItemType directory -Path $ClientDestPath
	$CopyTo = @(Get-ChildItem -path "$ClientDestPath*.bak")
	
	}
ELSE {
	
	$CopyTo = @(Get-ChildItem -path "$ClientDestPath*.bak")
	}




$Files2Copy = Compare-Object -ReferenceObject $CopyFrom -DifferenceObject $CopyTo -Property name, length -PassThru | Where-Object {$_.SideIndicator -eq "<="}


if ($Files2Copy -ne $NULL)
	{
	foreach ($File in $Files2Copy)
        {
        write-host "This will copy File $($File.FullName) to $ClientDestPath$($File.Name)" -ForegroundColor "Red"
        
        }
	}
else
    {
    Write-Host "No files to copy for $($Client.Name)!" -foregroundcolor "blue"
    }


Get-ChildItem -Path $ClientDestPath -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.LastWriteTime -lt $Retain } | Remove-Item -Force

}