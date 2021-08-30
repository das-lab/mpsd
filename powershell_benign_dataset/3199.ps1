function Get-MSSQLColumn { 

    
    [cmdletbinding()]
    param(
        
        [parameter(
            Mandatory=$true,
            Position=0,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true
        )]
            [string[]]$table,
        
        [parameter( Mandatory=$true )]
            [string]$database,

            [switch]$allFields,

            [string]$username = $null,

            [string]$password = $null,
        
        [parameter( Mandatory=$true )]
            [string]$ServerInstance
    )
    Begin
    {

        
        function Invoke-Sqlcmd2 { 
             
            [CmdletBinding()] 
            param( 
            [Parameter(Position=0, Mandatory=$true)] [string]$ServerInstance, 
            [Parameter(Position=1, Mandatory=$false)] [string]$Database, 
            [Parameter(Position=2, Mandatory=$false)] [string]$Query, 
            [Parameter(Position=3, Mandatory=$false)] [string]$Username, 
            [Parameter(Position=4, Mandatory=$false)] [string]$Password, 
            [Parameter(Position=5, Mandatory=$false)] [Int32]$QueryTimeout=600, 
            [Parameter(Position=6, Mandatory=$false)] [Int32]$ConnectionTimeout=15, 
            [Parameter(Position=7, Mandatory=$false)] [ValidateScript({test-path $_})] [string]$InputFile, 
            [Parameter(Position=8, Mandatory=$false)] [ValidateSet("DataSet", "DataTable", "DataRow","SingleValue")] [string]$As="DataRow",
            [Parameter(Position=9, Mandatory=$false)] [System.Collections.IDictionary]$SqlParameters 
            ) 
            
            if ($InputFile) 
            { 
                $filePath = $(resolve-path $InputFile).path 
                $Query =  [System.IO.File]::ReadAllText("$filePath") 
            } 
            
            $conn=new-object System.Data.SqlClient.SQLConnection 
            
            if ($Username) 
            { $ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}" -f $ServerInstance,$Database,$Username,$Password,$ConnectionTimeout } 
            else 
            { $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,$Database,$ConnectionTimeout } 
            
            $conn.ConnectionString=$ConnectionString 
            
            
            if ($PSBoundParameters.Verbose) 
            { 
                $conn.FireInfoMessageEventOnUserErrors=$true 
                $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {Write-Verbose "$($_)"} 
                $conn.add_InfoMessage($handler) 
            } 
            
            $conn.Open() 
            $cmd=new-object system.Data.SqlClient.SqlCommand($Query,$conn) 
            $cmd.CommandTimeout=$QueryTimeout
            if ($SqlParameters -ne $null)
            {
                $SqlParameters.GetEnumerator() |
                    ForEach-Object {
                        If ($_.Value -ne $null)
                        { $cmd.Parameters.AddWithValue($_.Key, $_.Value) }
                        Else
                        { $cmd.Parameters.AddWithValue($_.Key, [DBNull]::Value) }
                    } > $null
            }
            
            $ds = New-Object system.Data.DataSet 
            $da = New-Object system.Data.SqlClient.SqlDataAdapter($cmd) 
            
            [void]$da.fill($ds) 
            
            $conn.Close() 
            
            switch ($As) 
            { 
                'DataSet'     { Write-Output ($ds) } 
                'DataTable'   { Write-Output ($ds.Tables) } 
                'DataRow'     { Write-Output ($ds.Tables[0]) }
                'SingleValue' { Write-Output ($ds.Tables[0] | Select-Object -Expand $ds.Tables[0].Columns[0].ColumnName ) }
            } 
 
        } 
        

        
        if(-not ( get-command invoke-sqlcmd2 -ErrorAction SilentlyContinue))
        {
            Throw "This command relies on Invoke-SQLCMD2.  Please obtain the latest version and dot source it prior to running this command.`nThis script was built using the code from here: http://poshcode.org/4137"
        }


        
        
        $params = @{
            Query = "SELECT $( if($allFields){"*"} else{"COLUMN_NAME"}) FROM [INFORMATION_SCHEMA].[COLUMNS] WHERE TABLE_NAME = @table"
            ServerInstance = $ServerInstance
            ErrorAction = "Stop"
            Database = $database
        }
        if($username){
            $params.add("username",$username)
        }
        if($password){
            $params.add("password",$password)
        }

    }
    Process
    {
        foreach($sqlTable in $table)
        {

            
            $sqlParams = @{
                table = $sqlTable
            }

            
            try
            {
                write-verbose "Running Invoke-SQLCMD with parameters:`n$($params | out-string)`nSQL Parameters:`n$($sqlParams | out-string)"
                $results = Invoke-Sqlcmd2 @params -SqlParameters $sqlParams
            }
            catch
            {
                Write-Error "Error returning columns from table '$sqlTable' on instance '$ServerInstance': $_"
                continue
            }

            
            if($allFields)
            {
                $results
            }
            else
            {
                $results | select -ExpandProperty COLUMN_NAME
            }
        }
    }
 }