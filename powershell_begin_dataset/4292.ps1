function Invoke-SQLiteBulkCopy {

    [cmdletBinding( DefaultParameterSetName = 'Datasource',
                    SupportsShouldProcess = $true,
                    ConfirmImpact = 'High' )]
    param(
        [parameter( Position = 0,
                    Mandatory = $true,
                    ValueFromPipeline = $false,
                    ValueFromPipelineByPropertyName= $false)]
        [System.Data.DataTable]
        $DataTable,

        [Parameter( ParameterSetName='Datasource',
                    Position=1,
                    Mandatory=$true,
                    ValueFromRemainingArguments=$false,
                    HelpMessage='SQLite Data Source required...' )]
        [Alias('Path','File','FullName','Database')]
        [validatescript({
            
            if ( $_ -match ":MEMORY:" -or (Test-Path $_) ) {
                $True
            }
            else {
                Throw "Invalid datasource '$_'.`nThis must match :MEMORY:, or must exist"
            }
        })]
        [string]
        $DataSource,

        [Parameter( ParameterSetName = 'Connection',
                    Position=1,
                    Mandatory=$true,
                    ValueFromPipeline=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [Alias( 'Connection', 'Conn' )]
        [System.Data.SQLite.SQLiteConnection]
        $SQLiteConnection,

        [parameter( Position=2,
                    Mandatory = $true)]
        [string]
        $Table,

        [Parameter( Position=3,
                     Mandatory=$false,
                     ValueFromPipeline=$false,
                     ValueFromPipelineByPropertyName=$false,
                     ValueFromRemainingArguments=$false)]
        [ValidateSet("Rollback","Abort","Fail","Ignore","Replace")]
        [string]
        $ConflictClause,

        [int]
        $NotifyAfter = 0,

        [switch]
        $Force,

        [Int32]
        $QueryTimeout = 600

    )

    Write-Verbose "Running Invoke-SQLiteBulkCopy with ParameterSet '$($PSCmdlet.ParameterSetName)'."

    Function CleanUp
    {
        [cmdletbinding()]
        param($conn, $com, $BoundParams)
        
        if($BoundParams.Keys -notcontains 'SQLiteConnection')
        {
            $conn.Close()
            $conn.Dispose()
            Write-Verbose "Closed connection"
        }
        $com.Dispose()
    }

    function Get-ParameterName
    {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
            [string[]]$InputObject,

            [Parameter(ValueFromPipelineByPropertyName = $true)]
            [string]$Regex = '(\W+)',

            [Parameter(ValueFromPipelineByPropertyName = $true)]
            [string]$Separator = '_'
        )

        Process{
            $InputObject | ForEach-Object {
                if($_ -match $Regex){
                    $Groups = @($_ -split $Regex | Where-Object {$_})
                    for($i = 0; $i -lt $Groups.Count; $i++){
                        if($Groups[$i] -match $Regex){
                            $Groups[$i] = ($Groups[$i].ToCharArray() | ForEach-Object {[string][int]$_}) -join $Separator
                        }
                    }
                    $Groups -join $Separator
                } else {
                    $_
                }
            }
        }
    }

    function New-SqliteBulkQuery {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
            [string]$Table,

            [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
            [string[]]$Columns,

            [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
            [string[]]$Parameters,

            [Parameter(ValueFromPipelineByPropertyName = $true)]
            [string]$ConflictClause = ''
        )

        Begin{
            $EscapeSingleQuote = "'","''"
            $Delimeter = ", "
            $QueryTemplate = "INSERT{0} INTO {1} ({2}) VALUES ({3})"
        }

        Process{
            $fmtConflictClause = if($ConflictClause){" OR $ConflictClause"}
            $fmtTable = "'{0}'" -f ($Table -replace $EscapeSingleQuote)
            $fmtColumns = ($Columns | ForEach-Object { "'{0}'" -f ($_ -replace $EscapeSingleQuote) }) -join $Delimeter
            $fmtParameters = ($Parameters | ForEach-Object { "@$_"}) -join $Delimeter

            $QueryTemplate -f $fmtConflictClause, $fmtTable, $fmtColumns, $fmtParameters
        }
    }

    
        if($PSBoundParameters.Keys -notcontains "SQLiteConnection")
        {
            $ConnectionString = "Data Source={0}" -f $DataSource
            $SQLiteConnection = New-Object System.Data.SQLite.SQLiteConnection -ArgumentList $ConnectionString
            $SQLiteConnection.ParseViaFramework = $true 
        }

        Write-Debug "ConnectionString $($SQLiteConnection.ConnectionString)"
        Try
        {
            if($SQLiteConnection.State -notlike "Open")
            {
                $SQLiteConnection.Open()
            }
            $Command = $SQLiteConnection.CreateCommand()
            $CommandTimeout = $QueryTimeout
            $Transaction = $SQLiteConnection.BeginTransaction()
        }
        Catch
        {
            Throw $_
        }
    
    write-verbose "DATATABLE IS $($DataTable.gettype().fullname) with value $($Datatable | out-string)"
    $RowCount = $Datatable.Rows.Count
    Write-Verbose "Processing datatable with $RowCount rows"

    if ($Force -or $PSCmdlet.ShouldProcess("$($DataTable.Rows.Count) rows, with BoundParameters $($PSBoundParameters | Out-String)", "SQL Bulk Copy"))
    {
        
            $Columns = $DataTable.Columns | Select -ExpandProperty ColumnName
            $ColumnTypeHash = @{}
            $ColumnToParamHash = @{}
            $Index = 0
            foreach($Col in $DataTable.Columns)
            {
                $Type = Switch -regex ($Col.DataType.FullName)
                {
                    
                    
                    '^(|\ASystem\.)Boolean$' {"BOOLEAN"} 
                    '^(|\ASystem\.)Byte\[\]' {"BLOB"}
                    '^(|\ASystem\.)Byte$'  {"BLOB"}
                    '^(|\ASystem\.)Datetime$'  {"DATETIME"}
                    '^(|\ASystem\.)Decimal$' {"REAL"}
                    '^(|\ASystem\.)Double$' {"REAL"}
                    '^(|\ASystem\.)Guid$' {"TEXT"}
                    '^(|\ASystem\.)Int16$'  {"INTEGER"}
                    '^(|\ASystem\.)Int32$'  {"INTEGER"}
                    '^(|\ASystem\.)Int64$' {"INTEGER"}
                    '^(|\ASystem\.)UInt16$'  {"INTEGER"}
                    '^(|\ASystem\.)UInt32$'  {"INTEGER"}
                    '^(|\ASystem\.)UInt64$' {"INTEGER"}
                    '^(|\ASystem\.)Single$' {"REAL"}
                    '^(|\ASystem\.)String$' {"TEXT"}
                    Default {"BLOB"} 
                }

                
                $ColumnTypeHash.Add($Index,$Type)

                
                
                
                $ColumnToParamHash.Add($Col.ColumnName, (Get-ParameterName $Col.ColumnName))

                $Index++
            }

        
            if ($PSBoundParameters.ContainsKey('ConflictClause'))
            {
                $Command.CommandText = New-SqliteBulkQuery -Table $Table -Columns $ColumnToParamHash.Keys -Parameters $ColumnToParamHash.Values -ConflictClause $ConflictClause
            }
            else
            {
                $Command.CommandText = New-SqliteBulkQuery -Table $Table -Columns $ColumnToParamHash.Keys -Parameters $ColumnToParamHash.Values
            }

            foreach ($Column in $Columns)
            {
                $param = New-Object System.Data.SQLite.SqLiteParameter $ColumnToParamHash[$Column]
                [void]$Command.Parameters.Add($param)
            }
            
            for ($RowNumber = 0; $RowNumber -lt $RowCount; $RowNumber++)
            {
                $row = $Datatable.Rows[$RowNumber]
                for($col = 0; $col -lt $Columns.count; $col++)
                {
                    
                    
                    switch ($ColumnTypeHash[$col])
                    {
                        "BOOLEAN" {
                            $Command.Parameters[$ColumnToParamHash[$Columns[$col]]].Value = [int][boolean]$row[$col]
                        }
                        "DATETIME" {
                            Try
                            {
                                $Command.Parameters[$ColumnToParamHash[$Columns[$col]]].Value = $row[$col].ToString("yyyy-MM-dd HH:mm:ss")
                            }
                            Catch
                            {
                                $Command.Parameters[$ColumnToParamHash[$Columns[$col]]].Value = $row[$col]
                            }
                        }
                        Default {
                            $Command.Parameters[$ColumnToParamHash[$Columns[$col]]].Value = $row[$col]
                        }
                    }
                }

                
                    Try
                    {
                        [void]$Command.ExecuteNonQuery()
                    }
                    Catch
                    {
                        
                            Write-Verbose "Rolling back due to error:`n$_"
                            $Transaction.Rollback()
                        
                        
                            CleanUp -conn $SQLiteConnection -com $Command -BoundParams $PSBoundParameters
                            Throw "Rolled back due to error:`n$_"
                    }

                if($NotifyAfter -gt 0 -and $($RowNumber % $NotifyAfter) -eq 0)
                {
                    Write-Verbose "Processed $($RowNumber + 1) records"
                }
            }  
    }
    
    
        $Transaction.Commit()
        CleanUp -conn $SQLiteConnection -com $Command -BoundParams $PSBoundParameters
    
}