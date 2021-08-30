function New-SQLiteConnection
{
    
    [cmdletbinding()]
    [OutputType([System.Data.SQLite.SQLiteConnection])]
    param(
        [Parameter( Position=0,
                    Mandatory=$true,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false,
                    HelpMessage='SQL Server Instance required...' )]
        [Alias( 'Instance', 'Instances', 'ServerInstance', 'Server', 'Servers','cn','Path','File','FullName','Database' )]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $DataSource,
                
        [Parameter( Position=2,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [System.Security.SecureString]
        $Password,

        [Parameter( Position=3,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [Switch]
        $ReadOnly,

        [Parameter( Position=4,
                    Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true,
                    ValueFromRemainingArguments=$false )]
        [bool]
        $Open = $True
    )
    Process
    {
        foreach($DataSRC in $DataSource)
        {
            Write-Verbose "Querying Data Source '$DataSRC'"
            [string]$ConnectionString = "Data Source=$DataSRC;"
            if ($Password) 
            {
                $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
                $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                $ConnectionString += "Password=$PlainPassword;"
            }
            if($ReadOnly)
            {
                $ConnectionString += "Read Only=True;"
            }
        
            $conn = New-Object System.Data.SQLite.SQLiteConnection -ArgumentList $ConnectionString
            $conn.ParseViaFramework = $true 
            Write-Debug "ConnectionString $ConnectionString"

            if($Open)
            {
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

            write-Verbose "Created SQLiteConnection:`n$($Conn | Out-String)"

            $Conn
        }
    }
}