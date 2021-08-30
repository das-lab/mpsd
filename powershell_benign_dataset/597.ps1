

function Backup-AllSQLDBs{



	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$false)]
		[String]
		$Server = $env:COMPUTERNAME,
		
		[Parameter(Mandatory=$true)]
		[String]
		$Instance,

		[Parameter(Mandatory=$true)]
		[String]
		$Path
	)

	
	
	
    
    if((Get-PSSnapin "SqlServerCmdletSnapin100" -ErrorAction SilentlyContinue) -eq $Null){
		Add-PSSnapin "SqlServerCmdletSnapin100"
	}
	
    if((Get-PSSnapin "SqlServerProviderSnapin100" -ErrorAction SilentlyContinue) -eq $Null){
		Add-PSSnapin "SqlServerProviderSnapin100"
	}

	
	
	
    Push-Location	

    $SQLInstance = "SQLServer:\SQL\$Server\$Instance\Databases"
    set-Location $SQLInstance
    Get-ChildItem $SQLInstance | select name | %{
        $BackupPath = $Path + "\" + $_.Name
        if(! (Test-Path $BackupPath)){
            mkdir $BackupPath
        }
    }


$SQLQuery = @"
DECLARE @Name VARCHAR(250)
DECLARE @Path VARCHAR(250)
DECLARE @FileName VARCHAR(250)
DECLARE @TimeStamp VARCHAR(30)

SET @Path = '$Path'

SELECT @TimeStamp = REPLACE(CONVERT(VARCHAR(26),getdate(),120),':','-')

DECLARE db_cursor CURSOR FOR
SELECT name
FROM master.dbo.sysdatabases
WHERE name NOT IN ('master','model','msdb','tempdb')

OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @Name

WHILE @@FETCH_STATUS = 0
BEGIN
       
       SET @FileName = @Path + '\' + @Name + '\' + @Name + '

       PRINT @FileName

       BACKUP DATABASE @Name TO DISK = @FileName

       FETCH NEXT FROM db_cursor INTO @Name
END

CLOSE db_cursor
DEALLOCATE db_cursor
"@

    
    Invoke-Sqlcmd -Query $SQLQuery -QueryTimeout 1000

    Pop-Location
}