function Invoke-SqliteQuery {  
    

    [CmdletBinding( DefaultParameterSetName='Src-Que' )]
    [OutputType([System.Management.Automation.PSCustomObject],[System.Data.DataRow],[System.Data.DataTable],[System.Data.DataTableCollection],[System.Data.DataSet])]
    param(
        [Parameter( ParameterSetName='Src-Que',
                    Position=0,
                    Mandatory=$true,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false,
                    HelpMessage='SQLite Data Source required...' )]
        [Parameter( ParameterSetName='Src-Fil',
                    Position=0,
                    Mandatory=$true,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false,
                    HelpMessage='SQLite Data Source required...' )]
        [Alias('Path','File','FullName','Database')]
        [validatescript({
            
            $Parent = Split-Path $_ -Parent
            if(
                $_ -match ":MEMORY:|^WHAT$" -or
                ( $Parent -and (Test-Path $Parent))
            ){
                $True
            }
            else {
                Throw "Invalid datasource '$_'.`nThis must match :MEMORY:, or '$Parent' must exist"
            }
        })]
        [string[]]
        $DataSource,
    
        [Parameter( ParameterSetName='Src-Que',
                    Position=1,
                    Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [Parameter( ParameterSetName='Con-Que',
                    Position=1,
                    Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [string]
        $Query,
        
        [Parameter( ParameterSetName='Src-Fil',
                    Position=1,
                    Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [Parameter( ParameterSetName='Con-Fil',
                    Position=1,
                    Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [ValidateScript({ Test-Path $_ })]
        [string]
        $InputFile,

        [Parameter( Position=2,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [Int32]
        $QueryTimeout=600,
    
        [Parameter( Position=3,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [ValidateSet("DataSet", "DataTable", "DataRow","PSObject","SingleValue")]
        [string]
        $As="PSObject",
    
        [Parameter( Position=4,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [System.Collections.IDictionary]
        $SqlParameters,

        [Parameter( Position=5,
                    Mandatory=$false )]
        [switch]
        $AppendDataSource,

        [Parameter( Position=6,
                    Mandatory=$false )]
        [validatescript({Test-Path $_ })]
        [string]$AssemblyPath = $SQLiteAssembly,

        [Parameter( ParameterSetName = 'Con-Que',
                    Position=7,
                    Mandatory=$true,
                    ValueFromPipeline=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [Parameter( ParameterSetName = 'Con-Fil',
                    Position=7,
                    Mandatory=$true,
                    ValueFromPipeline=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [Alias( 'Connection', 'Conn' )]
        [System.Data.SQLite.SQLiteConnection]
        $SQLiteConnection
    ) 

    Begin
    {
        
            Try
            {
                [void][System.Data.SQLite.SQLiteConnection]
            }
            Catch
            {
                if( -not ($Library = Add-Type -path $SQLiteAssembly -PassThru -ErrorAction stop) )
                {
                    Throw "This module requires the ADO.NET driver for SQLite:`n`thttp://system.data.sqlite.org/index.html/doc/trunk/www/downloads.wiki"
                }
            }

        if ($InputFile) 
        { 
            $filePath = $(Resolve-Path $InputFile).path 
            $Query =  [System.IO.File]::ReadAllText("$filePath") 
        }

        Write-Verbose "Running Invoke-SQLiteQuery with ParameterSet '$($PSCmdlet.ParameterSetName)'.  Performing query '$Query'"

        If($As -eq "PSObject")
        {
            
            $cSharp = @'
                using System;
                using System.Data;
                using System.Management.Automation;

                public class DBNullScrubber
                {
                    public static PSObject DataRowToPSObject(DataRow row)
                    {
                        PSObject psObject = new PSObject();

                        if (row != null && (row.RowState & DataRowState.Detached) != DataRowState.Detached)
                        {
                            foreach (DataColumn column in row.Table.Columns)
                            {
                                Object value = null;
                                if (!row.IsNull(column))
                                {
                                    value = row[column];
                                }

                                psObject.Properties.Add(new PSNoteProperty(column.ColumnName, value));
                            }
                        }

                        return psObject;
                    }
                }
'@

            Try
            {
                Add-Type -TypeDefinition $cSharp -ReferencedAssemblies 'System.Data','System.Xml' -ErrorAction stop
            }
            Catch
            {
                If(-not $_.ToString() -like "*The type name 'DBNullScrubber' already exists*")
                {
                    Write-Warning "Could not load DBNullScrubber.  Defaulting to DataRow output: $_"
                    $As = "Datarow"
                }
            }
        }

        
        if($PSBoundParameters.Keys -contains "SQLiteConnection")
        {
            if($SQLiteConnection.State -notlike "Open")
            {
                Try
                {
                    $SQLiteConnection.Open()
                }
                Catch
                {
                    Throw $_
                }
            }

            if($SQLiteConnection.state -notlike "Open")
            {
                Throw "SQLiteConnection is not open:`n$($SQLiteConnection | Out-String)"
            }

            $DataSource = @("WHAT")
        }
    }
    Process
    {
        foreach($DB in $DataSource)
        {

            if($PSBoundParameters.Keys -contains "SQLiteConnection")
            {
                $Conn = $SQLiteConnection
            }
            else
            {
                if(Test-Path $DB)
                {
                    Write-Verbose "Querying existing Data Source '$DB'"
                }
                else
                {
                    Write-Verbose "Creating andn querying Data Source '$DB'"
                }

                $ConnectionString = "Data Source={0}" -f $DB

                $conn = New-Object System.Data.SQLite.SQLiteConnection -ArgumentList $ConnectionString
                $conn.ParseViaFramework = $true 
                Write-Debug "ConnectionString $ConnectionString"

                Try
                {
                    $conn.Open() 
                }
                Catch
                {
                    Write-Error $_
                    continue
                }
            }

            $cmd = $Conn.CreateCommand()
            $cmd.CommandText = $Query
            $cmd.CommandTimeout = $QueryTimeout

            if ($SqlParameters -ne $null)
            {
                $SqlParameters.GetEnumerator() |
                    ForEach-Object {
                        If ($_.Value -ne $null)
                        {
                            if($_.Value -is [datetime]) { $_.Value = $_.Value.ToString("yyyy-MM-dd HH:mm:ss") }
                            $cmd.Parameters.AddWithValue("@$($_.Key)", $_.Value)
                        }
                        Else
                        {
                            $cmd.Parameters.AddWithValue("@$($_.Key)", [DBNull]::Value)
                        }
                    } > $null
            }
    
            $ds = New-Object system.Data.DataSet 
            $da = New-Object System.Data.SQLite.SQLiteDataAdapter($cmd)
    
            Try
            {
                [void]$da.fill($ds)
                if($PSBoundParameters.Keys -notcontains "SQLiteConnection")
                {
                    $conn.Close()
                }
                $cmd.Dispose()
            }
            Catch
            { 
                $Err = $_
                if($PSBoundParameters.Keys -notcontains "SQLiteConnection")
                {
                    $conn.Close()
                }
                switch ($ErrorActionPreference.tostring())
                {
                    {'SilentlyContinue','Ignore' -contains $_} {}
                    'Stop' {     Throw $Err }
                    'Continue' { Write-Error $Err}
                    Default {    Write-Error $Err}
                }           
            }

            if($AppendDataSource)
            {
                
                $Column =  New-Object Data.DataColumn
                $Column.ColumnName = "Datasource"
                $ds.Tables[0].Columns.Add($Column)

                Try
                {
                    
                    $Conn.ConnectionString -match "Data Source=(?<DataSource>.*);"
                    $Datasrc = $Matches.DataSource.split(";")[0]
                }
                Catch
                {
                    $Datasrc = $DB
                }

                Foreach($row in $ds.Tables[0])
                {
                    $row.Datasource = $Datasrc
                }
            }

            switch ($As) 
            { 
                'DataSet' 
                {
                    $ds
                } 
                'DataTable'
                {
                    $ds.Tables
                } 
                'DataRow'
                {
                    $ds.Tables[0]
                }
                'PSObject'
                {
                    
                    
                    foreach ($row in $ds.Tables[0].Rows)
                    {
                        [DBNullScrubber]::DataRowToPSObject($row)
                    }
                }
                'SingleValue'
                {
                    $ds.Tables[0] | Select-Object -ExpandProperty $ds.Tables[0].Columns[0].ColumnName
                }
            }
        }
    }
}