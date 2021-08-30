function Invoke-SQLBulkCopy {

    [cmdletBinding( DefaultParameterSetName = 'Instance',
                    SupportsShouldProcess = $true,
                    ConfirmImpact = 'High' )]
    param(
        [parameter( Position = 0,
                    Mandatory = $true,
                    ValueFromPipeline = $true,
                    ValueFromPipelineByPropertyName= $true)]
        [System.Data.DataTable]
        $DataTable,

        [Parameter( ParameterSetName = 'Instance',
                    Position = 1,
                    Mandatory = $true,
                    ValueFromPipeline = $false,
                    ValueFromPipelineByPropertyName = $true)]
        [Alias( 'SQLInstance', 'Server', 'Instance' )]
        [string]
        $ServerInstance,

        [Parameter( ParameterSetName = 'Connection',
                    Position = 1,
                    Mandatory = $true,
                    ValueFromPipeline = $false,
                    ValueFromPipelineByPropertyName = $false,
                    ValueFromRemainingArguments = $false )]
        [Alias( 'Connection', 'Conn' )]
        [System.Data.SqlClient.SQLConnection]
        $SQLConnection,

        [Parameter( Position = 2,
                    Mandatory = $true)]
        [string]
        $Database,

        [parameter( Position = 3,
                    Mandatory = $true)]
        [string]
        $Table,

        [Parameter( ParameterSetName = 'Instance',
                    Position = 4,
                    Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $Credential,
    
        [Parameter( ParameterSetName = 'Instance',
                    Position = 5,
                    Mandatory = $false)]
        [Int32]
        $ConnectionTimeout=15,

        [switch]
        $Temp,

        [int]
        $BatchSize = 0,

        [int]
        $NotifyAfter = 0,

        [System.Collections.Hashtable]
        $ColumnMappings,

        [switch]
        $Force

    )
    begin {

        
        if ($PSBoundParameters.Keys -contains "SQLConnection")
        {
            if ($SQLConnection.State -notlike "Open")
            {
                Try
                {
                    $SQLConnection.Open()
                }
                Catch
                {
                    Throw $_
                }
            }

            if ($Database -and $SQLConnection.Database -notlike $Database)
            {
                Try
                {
                    $SQLConnection.ChangeDatabase($Database)
                }
                Catch
                {
                    Throw "Could not change Connection database '$($SQLConnection.Database)' to $Database`: $_"
                }
            }

            if ($SQLConnection.state -notlike "Open")
            {
                Throw "SQLConnection is not open"
            }
        }
        else
        {
            if ($Credential) 
            {
                $ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}" -f $ServerInstance,$Database,$Credential.UserName,$Credential.GetNetworkCredential().Password,$ConnectionTimeout
            }
            else 
            {
                $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,$Database,$ConnectionTimeout
            } 
            
            $SQLConnection = New-Object System.Data.SqlClient.SQLConnection
            $SQLConnection.ConnectionString = $ConnectionString 
            
            Write-Debug "ConnectionString $ConnectionString"
            
            Try
            {
                $SQLConnection.Open() 
            }
            Catch
            {
                Write-Error $_
                continue
            }
        }

        $bulkCopy = New-Object System.Data.SqlClient.SqlBulkCopy $SQLConnection
        $bulkCopy.BatchSize = $BatchSize
        $bulkCopy.BulkCopyTimeout = 10000000

        if ($Temp)
        {
            $bulkCopy.DestinationTableName = "
        }
        else
        {
            $bulkCopy.DestinationTableName = $Table
        }
        if ($NotifyAfter -gt 0)
        {
            $bulkCopy.NotifyAfter=$notifyafter
		    $bulkCopy.Add_SQlRowscopied( {Write-Verbose "$($args[1].RowsCopied) rows copied"} )
        }
        else
        {
            $bulkCopy.NotifyAfter=$DataTable.Rows.count
		    $bulkCopy.Add_SQlRowscopied( {Write-Verbose "$($args[1].RowsCopied) rows copied"} )
        }       
    }
    process
    {
        try
        {
            foreach ($column in ( $DataTable.Columns | Select -ExpandProperty ColumnName ))
            {
                if ( $PSBoundParameters.ContainsKey( 'ColumnMappings') -and $ColumnMappings.ContainsKey($column) )
                {
                    [void]$bulkCopy.ColumnMappings.Add($column,$ColumnMappings[$column])
                }
                else
                {
                    [void]$bulkCopy.ColumnMappings.Add($column,$column)
                }
            }
            Write-Verbose "ColumnMappings: $($bulkCopy.ColumnMappings | Format-Table -Property SourceColumn, DestinationColumn -AutoSize | Out-String)"
            
            if ($Force -or $PSCmdlet.ShouldProcess("$($DataTable.Rows.Count) rows, with BoundParameters $($PSBoundParameters | Out-String)", "SQL Bulk Copy"))
            {
                $bulkCopy.WriteToServer($DataTable)
            }
        }
        catch
        {
            throw $_
        }
    }
    end
    {
        
        if($PSBoundParameters.Keys -notcontains 'SQLConnection')
        {
            $SQLConnection.Close()
            $SQLConnection.Dispose()
        }
    }
}