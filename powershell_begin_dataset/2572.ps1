param (
    [string]$filename = $(throw "need a filename, e.g. c:\temp\test.xls"),
    [string]$worksheet
)

if (-not (Test-Path $filename)) {
    throw "Path '$filename' does not exist."
    exit
}

if (-not $worksheet) {
    Write-Warning "Defaulting to Sheet1 in workbook."
    $worksheet = "Sheet1"
}


$filename = Resolve-Path $filename



$connectionString = "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=${filename};Extended Properties=`"Excel 12.0 Xml;HDR=YES`"";




$connection = New-Object system.data.OleDb.OleDbConnection $connectionString;
$connection.Open();
$command = New-Object system.data.OleDb.OleDbCommand "select * from [$worksheet`$]"

$command.connection = $connection
$reader = $command.ExecuteReader("CloseConnection")

if ($reader.HasRows) {
    
    $fields = @()
    $count = $reader.FieldCount

    for ($i = 0; $i -lt $count; $i++) {
        $fields += $reader.GetName($i)
    }

    while ($reader.read()) {

        trap [exception] {
            Write-Warning "Error building row."
            break;
        }

        
        $values = New-Object object[] $count

        
        $reader.GetValues($values)

        $row = New-Object psobject
        $fields | foreach-object -begin {$i = 0} -process {
            $row | Add-Member -MemberType noteproperty -Name $fields[$i] -Value $values[$i]; $i++
        }
        $row 
    }
}