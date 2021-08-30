






















cls

Import-Module b:\PnPPowerShell\V16\OfficeDevPnP.PowerShell.Commands.dll 	
Import-Module "C:\Program Files (x86)\SharePoint Online Management Shell\Microsoft.Online.SharePoint.PowerShell\Microsoft.Online.SharePoint.PowerShell.dll"

$outputFile = "<output file location>"
$site = "<site url>"





function GetDocumentLibraries{
	Param(
	[string] $webUrl
	)
	
	$web = Get-SPOWeb -Identity $webUrl
	$lists = Get-SPOList -Web $web
	$excluded = "Form Templates","Site Assets","Style Library"
	
	foreach($list in $lists.SyncRoot)
	{
		if($list.BaseType -eq "DocumentLibrary" -and $list.Hidden -eq $false -and $excluded.Contains($list.Title) -eq $false)
		{
			$documentLibraries += $list.Title + ","
		}
	}
	$separator = ","
	$option = [System.StringSplitOptions]::RemoveEmptyEntries
	return $documentLibraries.Split($separator,$option)
}


function GetWebs{
	$sites = Get-SPOSite 
	$subs = Get-SPOSubWebs -Web $sites.RootWeb -Recurse
	foreach ($sub in $subs.SyncRoot)
	{
		$subIds += $sub.ServerRelativeUrl + "," 
	}
	$separator = ","
	$option = [System.StringSplitOptions]::RemoveEmptyEntries
	return $subIds.Split($separator,$option)
}


function ProcessWeb
{
param( [string] $webUrl)
	$docLibraries = GetDocumentLibraries -webUrl $webUrl 
	$x += "<Libraries>"
	foreach ($library in $docLibraries){
		$x += '<Library Title="' + $library +'">'
		$pages = Get-SPOListItem -List $library -Web $webUrl
		$x += "<Pages>"
		foreach($page in $pages.SyncRoot)
		{
			$x +='<Page Url="' + $page.FieldValues["FileLeafRef"] + '">'
			$pageName = $page.FieldValues["FileLeafRef"]
			$url = $page.FieldValues["FileRef"]
			$webparts = get-spowebpart -PageUrl $url 
			$webpart = ""
			$x +="<Webparts>"
			foreach ($webpart in  $webparts.SyncRoot)
			{	
				$audience  = $webpart.WebPart.Properties.FieldValues["AuthorizationFilter"]
				if ($audience -eq "")
				{
					$audience = "Not set"
				}
				$x +='<Webpart Title="'+ $webpart.WebPart.Title + '" Audiences="'+ $audience + '">'
				$x += '</Webpart>'	
			}
			$x +="</Webparts>"
			$x += "</Page>"
		}
		$x +="</Pages>"
		$x +="</Library>"		
	}

	$x+="</Libraries>"
	return $x
}


Connect-SPOnline -Url $site -Credentials (Get-Credential)


$webs = GetWebs
$xml = '<?xml version="1.0" encoding="utf-8"?>' 
$xml += '<TargetAudienceData>'
$xml +='<Webs>'


foreach ($web in $webs){
	$xml += '<Web Url="' +$web + '">'
	$retxml = ProcessWeb -webUrl $web
	$xml += $retxml
	$xml += '</Web>'
}
$xml +='</Webs>' 
$xml += '</TargetAudienceData>'

Write-Host $xml
$xml | Out-File -Force -FilePath $outputFile

