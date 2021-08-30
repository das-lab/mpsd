
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

function SQL-Query {
  param([string]$Query,
    [string]$SqlServer = $DEFAULT_SQL_SERVER,
    [string]$DB = $DEFAULT_SQL_DB,
    [string]$RecordSeparator = "`t")

  $conn_options = ("Data Source=$SqlServer; Initial Catalog=$DB;" + "Integrated Security=SSPI")
  $conn = New-Object System.Data.SqlClient.SqlConnection ($conn_options)
  $conn.Open()

  $sqlCmd = New-Object System.Data.SqlClient.SqlCommand
  $sqlCmd.CommandTimeout = "300"
  $sqlCmd.CommandText = $Query
  $sqlCmd.Connection = $conn

  $reader = $sqlCmd.ExecuteReader()
  if (-not $?) { 
    $lineno = Get-CurrentLineNumber
    ./logerror.ps1 $Output $date $lineno $title
  }
  [array]$serverArray
  $arrayCount = 0
  while ($reader.Read()) {
    $serverArray +=,($reader.GetValue(0))
    $arrayCount++
  }
  $serverArray
}

[string]$SMCIndexesScript = "\\xfs3\DataManagement\Scripts\Move_DB\PowershellScripts\SQL\SMCIndexes.sql";

[string]$SMCTriggersScript = "\\xfs3\Release\Prime Alliance\SMC\LatestVersion\DatabaseScripts\Other\Triggers.sql";
[string]$SMCViewsScript = "\\xfs3\Release\Prime Alliance\SMC\LatestVersion\DatabaseScripts\Other\Views.sql";
[string]$SMCImportLoansScript = "\\xfs3\Release\Prime Alliance\SMC\LatestVersion\DatabaseScripts\Other\ImportLoans.sql";





function Apply-SMCScripts {
  param(
    [Parameter(Mandatory = $True)]
    [string]$DBServerName,
    [Parameter(Mandatory = $True)]
    [string]$DBName
  )
  Invoke-SQLCMD -ServerInstance $DBServerName -database $DBName -InputFile $SMCIndexesScript -QueryTimeout 120
  
  Invoke-SQLCMD -ServerInstance $DBServerName -database $DBName -InputFile $SMCTriggersScript -QueryTimeout 120
  Invoke-SQLCMD -ServerInstance $DBServerName -database $DBName -InputFile $SMCViewsScript -QueryTimeout 120
  Invoke-SQLCMD -ServerInstance $DBServerName -database $DBName -InputFile $SMCImportLoansScript -QueryTimeout 120
}

function DO-Replication
{

  

  param
  (
    [string][Parameter(Mandatory = $true,Position = 0)] $subscriber,
    [string][Parameter(Mandatory = $true,Position = 1)] $publisher,
    [string][Parameter(Mandatory = $true,Position = 2)] $publication,
    [string][Parameter(Mandatory = $true,Position = 3)] $subscriptionDatabase,
    [string][Parameter(Mandatory = $true,Position = 4)] $publicationDatabase,
    [boolean][Parameter(Mandatory = $true,Position = 5)] $forceReInit,
    [int32][Parameter(Mandatory = $true,Position = 6)] $verboseLevel,
    [int32][Parameter(Mandatory = $true,Position = 7)] $retries
  )

  "Subscriber: $subscriber";
  "Publisher: $publisher";
  "Publication: $publication";
  "Publication Database: $publicationDatabase";
  "Subscription Database: $subscriptionDatabase";
  "ForceReInit: $forceReinit";
  "VerboseLevel: $verboseLevel";
  "Retries: $retries";

  for ($counter = 1; $counter -le $retries; $counter++)
  {

    

    $serverConnection = New-Object Microsoft.SqlServer.Management.Common.ServerConnection $publisher;

    try
    {

      $transSubscription = New-Object Microsoft.SqlServer.Replication.TransSubscription
      $transSubscription.ConnectionContext = $serverConnection;
      $transSubscription.DatabaseName = $publicationDatabase;
      $transSubscription.PublicationName = $publication;
      $transSubscription.SubscriptionDBName = $subscriptionDatabase;
      $transSubscription.SubscriberName = $subscriber;

      if ($true -ne $transSubscription.LoadProperties())
      {
        throw New-Object System.ApplicationException "A subscription to [$publication] does not exist on [$subscriber]"
      }
      else
      {
        $ReplJob = SQL-Query -Query "select name from sysjobs where category_id = 15 and name like '%$($publicationDatabase)%' " -sqlserver $Publisher -DB "msdb"
        SQL-Query -Query "exec sp_start_job '$($ReplJob)'" -sqlserver $publisher -DB "msdb"
      }


      if ($null -eq $transSubscription.SubscriberSecurity)
      {
        throw New-Object System.ApplicationException "There is insufficent metadata to synchronize the subscription. Recreate the subscription with the agent job or supply the required agent properties at run time.";
      }


      if ($forceReInit -eq $true)
      {
        $transSubscription.Reinitialize();
      }

      $transSubscription.SynchronizationAgent.CommitPropertyChanges;
      $transSubscription.SynchronizationAgent.Synchronize;

      "Sync Complete";
      return;



    } catch [exception]
    {
      if ($counter -lt $retries)
      {
        $_.Exception.Message + ": " + $_.Exception.InnerException
        "Retry $counter";
        continue;
      }
      else
      {
        $Error[0] | Out-String
        return $_.Exception.Message + ": " + $_.Exception.InnerException
      }

    }
  }
}

cls


Apply-SMCScripts -DBServerName "STGSQLLFC6" -dbname "RLCSMC"












