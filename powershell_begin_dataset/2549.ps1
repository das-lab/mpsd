cls






















    


$people = Import-Csv .\people.csv | 
    select Dept, Name, @{
        n="Salary"
        e={[double]$_.Salary}
    }, @{
        n="YearsEmployeed"
        e={[int]$_.yearsEmployeed}
    } 

$people | .\Out-ExcelPivotTable
$people | .\Out-ExcelPivotTable name dept salary
$people | .\Out-ExcelPivotTable -values YearsEmployeed