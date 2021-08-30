

function Export-SPLists{


	
	param(	
		[Parameter(Mandatory=$true)]
		[String[]]
		$Urls,
				
		[Parameter(Mandatory=$false)]
		[String]
		$Path = "C:\temp"
	)

	
	
	
    if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) 
    {
        Add-PSSnapin "Microsoft.SharePoint.PowerShell"
    }
	
	
	
	
	
		
	
	foreach($UrlItem in $Urls){
    
        
        $Url = Get-CleanSPUrl -Url $UrlItem        
        
        $SPWeb = Get-SPWeb -Identity ($Url.WebUrl.Scheme + "://" + $Url.WebUrl.Host + $Url.WebUrl.LocalPath)
		
		
        if(!(Test-Path -path $Path)){New-Item $Path -Type Directory}
        
        $FileName = ($Url.ListUrl.LocalPath -replace ".*/","")
        
        Write-Progress -Activity "Export SharePoint list" -status $FileName -percentComplete ([int]([array]::IndexOf($Urls, $UrlItem)/$Urls.Count*100))
		        
        
        $FilePath = Join-Path -Path $Path -ChildPath ( $FileName + "
        
		Export-SPWeb -Identity $SPWeb.Url -ItemUrl $Url.ListUrl.LocalPath -Path $FilePath  -IncludeVersions All -IncludeUserSecurity -Force -NoLogFile -CompressionSize 1000
        
        $FilePath

	}
}
