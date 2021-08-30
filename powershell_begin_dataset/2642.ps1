

param(
	[Parameter(Mandatory=$true)] 
	[ValidateNotNullOrEmpty()]
	[string]
	$ServerList,
	[Parameter(Mandatory=$false)] 
	[string]
	$OutputPath=([Environment]::GetFolderPath("MyDocuments")))

if((Test-Path $OutputPath) -eq $false)
{
	throw "Invalid -OutputPath, please use a valid file path"
}

if(Test-Path $ServerList){
	$output=@()
	$machines=Get-Content $ServerList
	$filename=(Join-Path -Path $OutputPath -ChildPath("Environement_IP_List_"+(Get-Date -Format yyyyMMddHHmm)+".csv"))
	
	foreach($machine in $machines){
		$return=New-Object System.Object
		
		if(Test-Connection $machine -Quiet -Count 1){
			$ip = (Test-Connection $machine -count 1).IPV4Address.ToString()
		}
		else{
			$ip = "Machine not available"
		}
		
		$return | Add-Member -type NoteProperty -Name "Host" -Value $machine
		$return | Add-Member -type NoteProperty -Name "IP" -Value $ip
		
		$output+=$return
		}
	
	$output | Export-CSV -Path $filename -NoTypeInformation
}
else{
	throw "Invalid -ServerList, please use a valid file path"
}