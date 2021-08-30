









 
function Import-Excel { 
   
  [CmdletBinding()] 
  Param([Parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Path, 
        [Parameter(Mandatory=$false)][switch]$NoHeaders 
        ) 
  $Path = if([IO.Path]::IsPathRooted($Path)){$Path}else{Join-Path -Path (Get-Location) -ChildPath $Path} 
  if(!(Test-Path $Path) -or $Path -notmatch ".xls$|.xlsx$") { Write-Host "ERROR: Invalid excel file [$Path]." -ForeGroundColor Red; return } 
  $excel = New-Object -ComObject Excel.Application 
  if(!$excel) { Write-Host "ERROR: Please install Excel first. I haven't figured out how to read an Excel file as xml yet." -ForeGroundColor Red; return } 
  $content = @() 
  $workbooks = $excel.Workbooks 
  $workbook = $workbooks.Open($Path) 
  $worksheets = $workbook.Worksheets 
  $sheet = $worksheets.Item(1) 
  $range = $sheet.UsedRange 
  $rows = $range.Rows 
  $columns = $range.Columns 
  $headers = @() 
  $top = if($NoHeaders){1}else{2}  
  if($NoHeaders) { for($c=1;$c-le$columns.Count;$c++) { $headers += "Column$c" } }  
  else { 
    $headers = $rows | Where-Object { $_.Row -eq 1 } | %{ $_.Value2 } 
    for($i=0;$i-lt$headers.Count;$i++) { if(!$headers[$i]) { $headers[$i] = "Column$($i+1)" } }  
    } 
  for($r=$top;$r-le$rows.Count;$r++) {  
    $data = $rows | Where-Object { $_.Row -eq $r } | %{ $_.Value2 } 
    $line = New-Object PSOBject 
    for($c=0;$c-lt$columns.Count;$c++) { $line | Add-Member NoteProperty $headers[$c]($data[$c]) } 
    $content += $line 
    } 
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($columns) } while($o -gt -1) 
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($rows) } while($o -gt -1) 
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($range) } while($o -gt -1) 
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($sheet) } while($o -gt -1) 
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($worksheets) } while($o -gt -1) 
  $workbook.Close($false) 
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($workbook) } while($o -gt -1) 
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($workbooks) } while($o -gt -1) 
  $excel.Quit() 
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) } while($o -gt -1) 
  return $content 
  } 
 
function Export-Excel { 
   
  [CmdletBinding()] 
  Param([Parameter(Mandatory=$true)][string]$Path, 
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)][PSObject]$InputObject, 
        [Parameter(Mandatory=$false)][ValidateSet("Line","ThickLine","DoubleLine")][string]$HeaderBorder, 
        [Parameter(Mandatory=$false)][switch]$BoldHeader, 
        [Parameter(Mandatory=$false)][switch]$Force 
        ) 
  $Path = if([IO.Path]::IsPathRooted($Path)){$Path}else{Join-Path -Path (Get-Location) -ChildPath $Path} 
  if($Path -notmatch ".xls$|.xlsx$") { Write-Host "ERROR: Invalid file extension in Path [$Path]." -ForeGroundColor Red; return } 
  $excel = New-Object -ComObject Excel.Application 
  if(!$excel) { Write-Host "ERROR: Please install Excel first." -ForeGroundColor Red; return } 
  $workbook = $excel.Workbooks.Add() 
  $sheet = $workbook.Worksheets.Item(1) 
  $xml = ConvertTo-XML $InputObject 
  $lines = $xml.Objects.Object.Property 
  for($r=2;$r-le$lines.Count;$r++) { 
    $fields = $lines[$r-1].Property 
    for($c=1;$c-le$fields.Count;$c++) { 
      if($r -eq 2) { $sheet.Cells.Item(1,$c) = $fields[$c-1].Name } 
      $sheet.Cells.Item($r,$c) = $fields[$c-1].InnerText 
      } 
    } 
  [void]($sheet.UsedRange).EntireColumn.AutoFit() 
  $headerRow = $sheet.Range("1:1") 
  if($BoldHeader) { $headerRow.Font.Bold = $true } 
  switch($HeaderBorder) { 
    "Line"       { $style = 1 } 
    "ThickLine"  { $style = 4 } 
    "DoubleLine" { $style = -4119 } 
    default      { $style = -4142 } 
    } 
  $headerRow.Borders.Item(9).LineStyle = $style 
  if($Force) { $excel.DisplayAlerts = $false } 
  $workbook.SaveAs($Path) 
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($headerRow) } while($o -gt -1) 
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($sheet) } while($o -gt -1) 
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($workbook) } while($o -gt -1) 
  $excel.ActiveWorkbook.Close($false) 
  $excel.Quit() 
  do { $o = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) } while($o -gt -1) 
  return $Path 
  } 
 
Export-ModuleMember Export-Excel,Import-Excel