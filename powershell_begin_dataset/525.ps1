

function Export-PPSPWeb{



	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)]
		[String]
		$Url,
		
		[Parameter(Mandatory=$false)]
		[String]
		$Path = "C:\temp",
        
        [Switch]
        $NoFileCompression
	)
	
	
	
	
	if(-not (Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue)){Add-PSSnapin "Microsoft.SharePoint.PowerShell"}
	
	
	
	
        
    
    $SPUrl = $(Get-SPUrl $Url).Url
    
    
    $SPWeb = Get-SPWeb -Identity $SPUrl
    
    $SPTemplate = $SPWeb.WebTemplate + "
    
    
    if(!(Test-Path -path $Path)){New-Item $Path -Type Directory}
    
    
    $FileName = $SPWeb.Title + "
    
    
    $FilePath = Join-Path $Path -ChildPath $FileName
    
    
    Export-SPWeb -Identity $SPWeb.Url -Path $FilePath -Force -IncludeUserSecurity -IncludeVersions All -NoFileCompression:$NoFileCompression -NoLogFile

    
    @{BackupFile = $FilePath;Template = $SPTemplate}
    
}