


 

function SQL-Query{
 param([string]$Query,
 [string]$SqlServer = $DEFAULT_SQL_SERVER,
 [string]$DB = $DEFAULT_SQL_DB,
 [string]$RecordSeparator = "`t")
 
 $conn_options = ("Data Source=$SqlServer; Initial Catalog=$DB;" + "Integrated Security=SSPI")
 $conn = New-Object System.Data.SqlClient.SqlConnection($conn_options)
 $conn.Open()

 $sqlCmd = New-Object System.Data.SqlClient.SqlCommand
 $sqlCmd.CommandTimeout = "300"
 $sqlCmd.CommandText = $Query
 $sqlCmd.Connection = $conn

 $reader = $sqlCmd.ExecuteReader()

 [array]$serverArray
 $arrayCount = 0
 while($reader.Read()){
       
            $serverArray += ,($reader.GetValue(0), $reader.GetValue(1))
        
     $arrayCount++
 }
  $serverArray
}
 
 function SQL-NONQuery{
 param([string]$Statement,
 [string]$SqlServer = $DEFAULT_SQL_SERVER,
 [string]$DB = $DEFAULT_SQL_DB )
 
 $conn_options = ("Data Source=$SqlServer; Initial Catalog=$DB;" + "Integrated Security=SSPI")
 $conn = New-Object System.Data.SqlClient.SqlConnection($conn_options)
 $conn.Open()

 $cmd = $conn.CreateCommand()
  $cmd.CommandText = $Statement
  $returnquery = $cmd.ExecuteNonQuery()
  $returnquery
  

}

function parseString{
    Param($string,
    $regexpattern)
    $regstring = ""
   
    
    if ($regexpattern -eq $null){
        $regexpattern = "(\w+)\.(\w+)\.(\w+)\.(\w+)"
    }
    
    $regex = New-Object System.Text.RegularExpressions.Regex $regexPattern
    
    
    
    $match = $regex.Match($string)
    
    if ($match.Success -and $match.Length -gt 0){
        
        
        
        $regstring = $match.value.ToString()
        

    }
    $regstring
    
}






$DB = $args[0]
$DNS = $args[1]
$sproc = $args[2]
$regex = $args[3]
$string = ""

$statusDB = "status"
$statusDNS = "status.db.prod.dexma.com"
$SQLinsert = ""


if ($DB -eq $null) {
    write-host "Database name is required"
    exit
}
if ($DNS -eq $null) {
    write-host "Dns name is required"
    exit
}

if ($sproc -eq $null) {
    write-host "SQL statement is required"
    exit
}

SQL-NONQuery $sproc $DNS $DB 
$sql = "SELECT * FROM `
$returnQuery = SQL-Query $sql $DNS $DB

foreach ($row in $returnQuery){
    if ($row -ne $null){
        $string = $row[0]
        $name = $row[1]
        $returnstring = parsestring $string   $regex
        if (($returnstring -ne $null) -and ($returnstring -ne "")){
         write-host "Parse: $returnstring       Sproc:  $name"
        }
    
    }
    
}
$sql = "DROP TABLE `
$returnQuery = SQL-NONQuery $sql $DNS $DB