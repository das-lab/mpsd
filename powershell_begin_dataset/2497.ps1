



param( $Client = 'GTE', $TrnSourcePath = '\\psqlrpt24\e$\MSSQL10.MSSQLSERVER\MSSQL\BAK', $TrnDestPath = '\\pcon310\Relateprod\FTP sites\')


cls

function create-7zip([String] $aDirectory, [String] $aZipfile){
    [string]$pathToZipExe = "C:\Program Files\7-zip\7z.exe"
    [Array]$arguments = "a", "-t7z", "$aZipfile", "$aDirectory", "-r"
    & $pathToZipExe $arguments
}

function Trim-Bak{
	param(
		[Parameter(Position=0, Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[System.String]
		$Text	
	)
$regexpattern = "(DMart_\w*_Data_backup_\d{4}_\d{2}_\d{2})"


$regex = New-Object System.Text.RegularExpressions.Regex $regexpattern

$match = $regex.Match($text)
    
    if ($match.Success -and $match.Length -gt 0){
		
		$string = $match.value.ToString()
		$string = $string + ".bak"
		return $string
	} else {
		return $Text
	}
	
}	

$a = get-date
$b = $a.AddMinutes(-15)
$b = $a.AddMinutes(-1)

$ClientSrcPath = $TrnSourcePath + '\DMart_' + $Client + 'CDC_Data\'



if (!(Test-Path -Path $ClientSrcPath)){
	Write-Host "$ClientSrcPath not found!"	
	break;
	}
ELSE {
	
	$CopyFrom = @(Get-ChildItem -path "$ClientSrcPath*bak" ) | Where-Object{$_.LastWriteTime -lt $b}
	
	}



Write-Host
$d = (get-date).toshortdatestring()
$d = $d -replace "`/","-"
$Output = "E:\dexma\logs\Prodops_Scripts_Logs_$d.txt"

$ClientDestPath = $TrnDestPath + $Client + 'prodrpt\'



if (!(Test-Path -Path $ClientDestPath)) {
	Write-Host "$ClientDestPath not found!"
	break;
	}
ELSE {
	
	$CopyTo = @(Get-ChildItem -path "$ClientDestPath*.bak")
	}






$Files2Copy = Get-ChildItem -path "$ClientSrcPath*.bak"  | Where-Object{$_.LastWriteTime -lt $b}

if ($Files2Copy -ne $NULL)
	{
	foreach ($File in $Files2Copy)
        {
        
		[string] $fileZip = $File.FullName
		[string] $newFileZip = Trim-Bak -Text $fileZip
		Rename-Item $fileZip $ClientSrcPath$newFileZip
		$fileZip = $newFileZip.replace(".bak",".7z")
		Write-Host -ForegroundColor Magenta "file: $newFileZip"
		create-7zip  $($ClientSrcPath + $newFileZip) $($ClientSrcPath + $fileZip)
		
		if (Test-Path $($ClientSrcPath + $newFileZip)) {
			Add-Content $Output "Removing file $($ClientSrcPath + $newFileZip)"
			Remove-Item $($ClientSrcPath + $newFileZip) 
		}
		write-host "This will copy File $($ClientSrcPath + $fileZip) to $ClientDestPath$fileZip" -ForegroundColor "magenta"
        Copy-Item -Path $($ClientSrcPath + $fileZip) -Destination $ClientDestPath 
		Add-Content $Output "File $fileZip Copied to $ClientDestPath"
		
        }
	}
else
    {
    Write-Host "No files to copy for $Client!" -foregroundcolor "blue"
	Add-Content $Output "No files to copy for $Client!"
    }

















