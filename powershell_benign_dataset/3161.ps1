Function Convert-CsvToPsDt
{
    
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true,
        HelpMessage = 'The csv input file path.')]
        [string]$Infile,
        [Parameter(Mandatory = $true,
        HelpMessage = 'The output file path.')]
        [string]$Outfile = ".\MyPsDataTable.ps1"
    )

    
    if(Test-Path $Infile)
    {
        Write-Output "[+] $Infile is accessible."
    }else{
        write-Output "[-] $Infile is not accessible, aborting."
        break
    }

    
    Write-Output "[+] Importing csv file."
    $MyCsv = Import-Csv $Infile

    
    Write-Output "[+] Paring columns."
    $MyCsvColumns = $MyCsv | Get-Member | Where-Object MemberType -like "NoteProperty" | Select-Object Name -ExpandProperty Name

    
    Write-Output "[+] Writing data table object to $Outfile."    
    write-output '$MyTable = New-Object System.Data.DataTable' | Out-File $Outfile

    
    Write-Output "[+] Writing data table columns to $Outfile."    
    $MyCsvColumns |
    ForEach-Object {

        write-Output "`$null = `$MyTable.Columns.Add(`"$_`")" | Out-File $Outfile -Append
    
    }

    
    Write-Output "[+] Writing data table rows to $Outfile." 
    $MyCsv |
    ForEach-Object {
    
        
        $CurrentRow = $_
        $PrintRow = ""
        $MyCsvColumns | 
        ForEach-Object{
            $GetValue = $CurrentRow | Select-Object $_ -ExpandProperty $_ 
            if($PrintRow -eq ""){
                $PrintRow = "`"$GetValue`""
            }else{         
                $PrintRow = "$PrintRow,`"$GetValue`""
            }
        }

        
        write-Output "`$null = `$MyTable.Rows.Add($PrintRow)" | Out-File $Outfile -Append
    }

    Write-Output "[+] All done."
}
