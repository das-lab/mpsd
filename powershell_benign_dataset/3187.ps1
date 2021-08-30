function Invoke-MySQLQuery { 
    

    [CmdletBinding( DefaultParameterSetName='Query' )]
    [OutputType([System.Management.Automation.PSCustomObject],[System.Data.DataRow],[System.Data.DataTable],[System.Data.DataTableCollection],[System.Data.DataSet])]
    param(
        [Parameter( Position=0,
                    Mandatory=$true,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false,
                    HelpMessage='SQL Server Instance required...' )]
        [Alias( 'Instance', 'Instances', 'ServerInstance', 'Server', 'Servers','cn' )]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ComputerName,

        [Parameter( Position=1,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [int]$Port = 3306,

        [Parameter( Position=2,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false)]
        [string]
        $Database,
    
        [Parameter( Position=3,
                    Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false,
                    ParameterSetName='Query' )]
        [string]
        $Query,
        
        [Parameter( Position=3,
                    Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false,
                    ParameterSetName="File")]
        [ValidateScript({ Test-Path $_ })]
        [string]
        $InputFile,
        
        [Parameter( Position=4,
                    Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false,
                    ParameterSetName="Query")]
        [Parameter( Position=4,
                    Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false,
                    ParameterSetName="File")]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter( Position=5,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [Int32]
        $QueryTimeout=600,
    
        [Parameter( Position=6,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [Int32]
        $ConnectionTimeout=15,
    
        [Parameter( Position=7,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [ValidateSet("DataSet", "DataTable", "DataRow","PSObject","SingleValue")]
        [string]
        $As="DataRow",
    
        [Parameter( Position=8,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [System.Collections.IDictionary]
        $SqlParameters,

        [Parameter( Position=9,
                    Mandatory=$false )]
        [switch]
        $AppendServerInstance
    ) 

    Begin
    {
        
        if( -not ($Library = [System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")) )
        {
            Throw "This function requires the ADO.NET driver for MySQL:`n`thttp://dev.mysql.com/downloads/connector/net/"
        }
        

        if ($InputFile) 
        { 
            $filePath = $(Resolve-Path $InputFile).path 
            $Query =  [System.IO.File]::ReadAllText("$filePath") 
        }

        Write-Verbose "Running Invoke-MySQLQuery with ParameterSet '$($PSCmdlet.ParameterSetName)'.  Performing query '$Query'"

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

    }
    Process
    {
        foreach($Computer in $ComputerName)
        {
            Write-Verbose "Querying ComputerName '$Computer'"

            $ConnectionString = "Server={0};Port=$Port;Database={1};Uid={2};Pwd={3};allow zero datetime=yes;Connection Timeout={4}" -f $Computer,$Database,$Credential.UserName,$Credential.GetNetworkCredential().Password,$ConnectionTimeout
	        
            $conn=new-object MySql.Data.MySqlClient.MySqlConnection
            $conn.ConnectionString = $ConnectionString 
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

            $cmd = New-Object MySql.Data.MySqlClient.MySqlCommand($Query,$conn) 
            $cmd.CommandTimeout = $QueryTimeout

            if ($SqlParameters -ne $null)
            {
                $SqlParameters.GetEnumerator() |
                    ForEach-Object {
                        If ($_.Value -ne $null)
                        { $cmd.Parameters.AddWithValue("@$($_.Key)", $_.Value) }
                        Else
                        { $cmd.Parameters.AddWithValue("@$($_.Key)", [DBNull]::Value) }
                    } > $null
            }
    
            $ds = New-Object system.Data.DataSet 
            $da = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($cmd)
    
            Try
            {
                [void]$da.fill($ds)
                $conn.Close()
            }
            Catch
            { 
                $Err = $_
                $conn.Close()

                switch ($ErrorActionPreference.tostring())
                {
                    {'SilentlyContinue','Ignore' -contains $_} {}
                    'Stop' {     Throw $Err }
                    'Continue' { Write-Error $Err}
                    Default {    Write-Error $Err}
                }              
            }

            if($AppendServerInstance)
            {
                
                $Column =  New-Object Data.DataColumn
                $Column.ColumnName = "MySQLServer"
                $ds.Tables[0].Columns.Add($Column)
                Foreach($row in $ds.Tables[0])
                {
                    $row.MySQLServer = $Computer
                }
                
                $Column =  New-Object Data.DataColumn
                $Column.ColumnName = "MySQLPort"
                $ds.Tables[0].Columns.Add($Column)
                Foreach($row in $ds.Tables[0])
                {
                    $row.MySQLPort = $Port
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