

function Get-SPListFiles{



	param(
	)
    
    Get-SPSite | %{
    
        $SPsite = $_
        
        
        $SPsite.RecycleBin | where{$_.ItemType -eq "File"} |%{
        
            $ItemUrl = $SPsite.Url + "/" + $_.DirName + "/"+ $_.LeafName
        
            New-Object PSObject -Property @{
                ParentWebsite = $SPSite.HostName
                ParentWebsiteUrl = $SPsite.Url
                Website = $_.Web.title
                WebsiteUrl = $_.Web.Url
                List = ""
                ListUrl = ""
                FileExtension = [System.IO.Path]::GetExtension($_.LeafName)
                IsCheckedOut = $false
                IsASubversion = $false
                IsDeleted = $true                
                Item = $_.LeafName                
                ItemUrl = $ItemUrl
                Folder = $ItemUrl -replace "[^/]+$",""      
                FileSize = $_.Size / 1MB    
            }
        }
        
        $SPWebs = Get-SPWebs $_.Url 
        $SPWebs | %{

            $SPWeb = $_
            
            
            $SPWeb.RecycleBin | where{$_.ItemType -eq "File"} |%{
        
                $ItemUrl = $SPsite.Url + "/" + $_.DirName + "/"+ $_.LeafName
            
                New-Object PSObject -Property @{
                    ParentWebsite = $SPWeb.ParentWeb.title
                    ParentWebsiteUrl = $SPWeb.ParentWeb.Url
                    Website = $SPWeb.title
                    WebsiteUrl = $SPWeb.Url
                    List = ""
                    ListUrl = ""
                    FileExtension = [System.IO.Path]::GetExtension($_.LeafName)
                    IsCheckedOut = $false
                    IsASubversion = $false
                    IsDeleted = $true                
                    Item = $_.LeafName                
                    ItemUrl = $ItemUrl
                    Folder = $ItemUrl -replace "[^/]+$",""      
                    FileSize = $_.Size / 1MB    
                }
            }
                            
            Get-SPLists $_.Url -OnlyDocumentLibraries | %{
            
                $SPList = $_
                
                $SPListUrl = (Get-SPUrl $SPList).url
                
                Write-Progress -Activity "Crawl list on website" -status "$($SPWeb.Title): $($SPList.Title)" -percentComplete ([Int32](([Array]::IndexOf($SPWebs, $SPWeb)/($SPWebs.count))*100))
                
                
                Get-SPListItems $_.ParentWeb.Url -FilterListName $_.title | %{
                    
                    $ItemUrl = (Get-SPUrl $_).Url                    
                    
                    New-Object PSObject -Property @{
                        ParentWebsite = $SPWeb.ParentWeb.title
                        ParentWebsiteUrl = $SPWeb.ParentWeb.Url
                        Website = $SPWeb.title
                        WebsiteUrl = $SPWeb.Url
                        List = $SPList.title
                        ListUrl = $SPListUrl
                        FileExtension = [System.IO.Path]::GetExtension($_.Url)
                        IsCheckedOut = $false
                        IsASubversion = $false
                        IsDeleted = $false              
                        Item = $_.Name                
                        ItemUrl = $ItemUrl
                        Folder = $ItemUrl -replace "[^/]+$",""      
                        FileSize = $_.file.Length / 1MB    
                    }
                    
                    $SPItem = $_
                    
                    
                    $_.file.versions | %{
                    
                        $ItemUrl = (Get-SPUrl $SPItem).Url  
                    
                        New-Object PSObject -Property @{
                            ParentWebsite = $SPWeb.ParentWeb.title
                            ParentWebsiteUrl = $SPWeb.ParentWeb.Url
                            Website = $SPWeb.title
                            WebsiteUrl = $SPWeb.Url                    
                            List = $SPList.title
                            ListUrl = $SPListUrl
                            FileExtension = [System.IO.Path]::GetExtension($_.Url)
                            IsCheckedOut = $false
                            IsASubversion = $true
                            IsDeleted = $false                                
                            Item = $SPItem.Name                    
                            ItemUrl = $ItemUrl 
                            Folder = $ItemUrl -replace "[^/]+$",""                               
                            FileSize = $_.Size / 1MB
                        }
                    }            
                }
                
                
                Get-SPListItems $_.ParentWeb.Url -FilterListName $_.title -OnlyCheckedOutFiles | %{
                
                    $ItemUrl = $SPSite.url + "/" + $_.Url 
                
                    New-Object PSObject -Property @{
                        ParentWebsite = $SPWeb.ParentWeb.title
                        ParentWebsiteUrl = $SPWeb.ParentWeb.Url
                        Website = $SPWeb.title
                        WebsiteUrl = $SPWeb.Url
                        List = $SPList.title
                        ListUrl = $SPListUrl
                        FileExtension = [System.IO.Path]::GetExtension($_.Url)
                        IsCheckedOut = $true
                        IsASubversion = $false
                        IsDeleted = $false                             
                        Item = $_.LeafName                
                        ItemUrl = $ItemUrl  
                        Folder = $ItemUrl -replace "[^/]+$",""          
                        FileSize = $_.Length / 1MB
                    }                
                }
            }
        }
    }
}