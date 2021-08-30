

function Export-SPList{


	
	param(	
		[Parameter(Mandatory=$true)]
		[String]
		$ListUrl,
       			
		[Parameter(Mandatory=$false)]
		[String]
		$Path = "C:\temp",
        
        [Switch]
        $NoFileCompression
	)

	
	
	
    if(-not (Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue)){Add-PSSnapin "Microsoft.SharePoint.PowerShell"}
	
	
	
	
    if(!(Test-Path -path $Path)){New-Item $Path -Type Directory}   

    $SPUrl = Get-SPUrl $ListUrl     
    $SPWeb = Get-SPWeb $SPUrl.WebUrl 
          
    $FileName = ([uri]$SPUrl.Url).LocalPath -replace ".*/",""
    $FilePath = Join-Path -Path $Path -ChildPath ( $FileName + "
       
    Write-Host "Export SharePoint list $FileName to $FilePath"    
    Export-SPWeb -Identity $SPWeb.Url -ItemUrl ([uri]$SPUrl.Url).LocalPath -Path $FilePath  -IncludeVersions All -IncludeUserSecurity -Force -NoLogFile -NoFileCompression:$NoFileCompression
    
    $FilePath
}