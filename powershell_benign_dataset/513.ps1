

function Update-SPWebTermNavigation{



    [CmdletBinding()]
    param(

        [Parameter(Mandatory=$true)]
        [String]$Identity,

        [Parameter(Mandatory=$true)]
        [String]$MMSSite,
        
        [Parameter(Mandatory=$true)]
        [String]$TermStoreName,
        
        [Parameter(Mandatory=$true)]
        [String]$TermGroupName,
        
        [Parameter(Mandatory=$true)]
        [String]$TermSetName,
        
        [Parameter(Mandatory=$false)]
        [String]$GlobalNavigationTermGroupName,

        [Parameter(Mandatory=$true)]
        [String]$GlobalNavigationTermSetName
    )

    
    
    

    if(-not (Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue)){Add-PSSnapin "Microsoft.SharePoint.PowerShell"}
      
    
    
    

    Write-Host "Update term navigation settings for: $Identity"

    
    $SPWeb = Get-SPWeb $Identity
    $SPSite = $SPWeb.Site

    
    $WebNavigationSettings = New-Object Microsoft.SharePoint.Publishing.Navigation.WebNavigationSettings($SPWeb)

    
    $SPTaxonomySession = Get-SPTaxonomySession -Site $MMSSite
    $TermStore = $SPTaxonomySession.TermStores[$TermStoreName]
    $TermGroup = $TermStore.Groups[$TermGroupName]
    $TermSet = $TermGroup.TermSets[$TermSetName]

    
    if($GlobalNavigationTermGroupName){
        $GlobalNavigationTermGroup = $TermStore.Groups[$GlobalNavigationTermGroupName]
        $GlobalNavigationTermSet = $GlobalNavigationTermGroup.TermSets[$GlobalNavigationTermSetName]
    }else{
        $GlobalNavigationTermSet = $TermGroup.TermSets[$GlobalNavigationTermSetName]
    }

    
    $TermSet.Terms | ForEach-Object{$_.delete()}
    $TermStore.CommitAll()

     
     $GlobalNavigationTermSet.Terms | ForEach-Object{$TermSet.ReuseTermWithPinning($_) | Out-Null}

     
     $TermSet.CustomSortOrder = $GlobalNavigationTermSet.CustomSortOrder 
     $TermStore.CommitAll()

     
     $WebNavigationSettings.GlobalNavigation.Source = 2
     $WebNavigationSettings.GlobalNavigation.TermStoreId = $TermStore.Id
     $WebNavigationSettings.GlobalNavigation.TermSetId = $TermSet.Id

     $WebNavigationSettings.AddNewPagesToNavigation = $false
     $WebNavigationSettings.CreateFriendlyUrlsForNewPages = $false
     $WebNavigationSettings.Update()
}
