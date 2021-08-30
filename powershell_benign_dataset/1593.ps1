


$DebugPreference = "SilentlyContinue"  
$UserName = (Get-Item Env:\USERNAME).Value
$origComputerName = (Get-Item Env:\COMPUTERNAME).Value
$ComputerName = Read-Host 'What is the computer name?'
$FileName = (Join-Path -Path ((Get-ChildItem Env:\USERPROFILE).value) -ChildPath $ComputerName) + ".html"  
  

$style = @"  
<style>  
BODY{background-color:Lavender}  
TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse}  
TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:thistle}  
TD{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:PaleGoldenrod}  
</style>  
"@  
  

if (Test-Path -Path $FileName)   
{  
    Remove-Item $FileName  
    Write-Debug "$FileName removed"  
}  



Get-WmiObject win32_Product -ComputerName $ComputerName |   
    Select Name,Version,PackageName,Installdate,Vendor |   
    Sort Installdate -Descending |   
        ConvertTo-Html -Head $style -PostContent "Report generated on $(get-date) by $UserName on computer $origComputerName" -PreContent "<h1>Computer Name: $ComputerName<h1><h2>Software Installed</h2>" -Title "Software Information for $ComputerName" |
        Out-File -FilePath $FileName  
                                   

    Write-Debug "File saved $FileName"
    Invoke-Item -Path $FileName
  

