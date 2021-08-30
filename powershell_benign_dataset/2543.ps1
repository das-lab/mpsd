


param( 
	$Client = 'GTE'
	, $TrnSourcePath = '\\psqlrpt24\e$\MSSQL10.MSSQLSERVER\MSSQL\TRN\'
	, $TrnDestPath = '\\pcon310\Relateprod\FTP sites\'
	)


cls

$a = get-date
$b = $a.AddMinutes(-15)

$ClientSrcPath = $TrnSourcePath + '\DMart_' + $Client + 'CDC_Data\'



if (!(Test-Path -Path $ClientSrcPath)){
	Write-Host "$ClientSrcPath not found!"	
	break;
	}
ELSE {
	
	$CopyFrom = @(Get-ChildItem -path "$ClientSrcPath*.trn" ) | Where-Object{$_.LastWriteTime -lt $b}
	}



Write-Host

$ClientDestPath = $TrnDestPath + $Client + 'prodrpt\'
if (!(Test-Path -Path $ClientDestPath)) {
	Write-Host "$ClientDestPath not found!"
	break;
	}
ELSE {
	
	$CopyTo = @(Get-ChildItem -recurse -path "$ClientDestPath*.trn")
	}




$Files2Copy = Compare-Object -ReferenceObject $CopyFrom -DifferenceObject $CopyTo  -Property fullname, name, length  | Where-Object {$_.SideIndicator -eq "<="}


foreach ($File in $Files2Copy)
    {
    if ($File -ne $NULL)
        {
        write-host "This will copy File $($File.FullName) to $ClientDestPath$($File.Name)" -ForegroundColor "Red"
        Copy-Item -Path $($File.FullName) -Destination $ClientDestPath$($File.Name) -whatif
        }
    else
        {
        Write-Host "No files to delete!" -foregroundcolor "blue"
        }
    }

