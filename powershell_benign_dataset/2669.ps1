
$configFilePath = "D:\ModernPagesConfig.xlsx" 



function Add-PnPModernListWebPart() {
   param(
      [Parameter(Mandatory)]
      [ValidateSet("Library", "List")]
      [String] $WebPartType,

      [Parameter(Mandatory)]
      [ValidateScript( {
            if (-not (Get-PnPClientSidePage $_)) {
               throw "The [$_] page does not exist"
            }
            else {
               $true
            }           
         })]
      [String] $PageName,

      [Parameter(Mandatory)]
      [ValidateScript( {        
            if (-not (Get-PnPList -Identity $_)) {
               throw "The [$_] list does not exist"
            }
            else {
               $true
            }  
         })]
      [String] $ListName,

      [Parameter(Mandatory)]
      [ValidateScript( {
            if (-not (Get-PnPView -List $listName -Identity $_)) {
               throw "The [$_] view does not exist in the [$listName] $WebPartType"
            }
            else {
               $true
            }        
         })]
      [String] $ViewName,
        
      [String] $WebPartTitle, 
        
      [ValidateSet(0, 1, 2, 3, 4)] 
      [int] $WebPartHeight, 

      [int] $Section, 

      [ValidateSet(0, 1, 2, 3)] 
      [int] $Column

      
   )

   
   [hashtable]$webPartProperties

   
   If ($WebPartType -eq "Library") {
      $webPartProperties = @{"isDocumentLibrary" = $true; }
   }

   If ($WebPartType -eq "List") {
      $webPartProperties = @{"isDocumentLibrary" = $false; }
   }

   $list = Get-PnPList -Identity $ListName

   
   $listId = $list.Id.ToString()
   $webPartProperties.Add("selectedListId", $listId)


   
   $listUrl = $list.RootFolder.ServerRelativeUrl
   $webPartProperties.Add("selectedListUrl", $listUrl)


   
   $view = Get-PnPView -List $ListName -Identity $ViewName
   $viewId = $view.Id.ToString()
   $webPartProperties.Add("selectedViewId", $viewId)
    

   
   If ($WebPartTitle) {
      $webPartProperties.Add("listTitle", $WebPartTitle)
   }

   
   Else {
      $WebPartTitle = $list.Title + ' - ' + $ViewName
      $webPartProperties.Add("listTitle", $WebPartTitle)
   }

   
   If ($WebPartHeight -ne 0) {
      $webPartProperties.Add("webpartHeightKey", $WebPartHeight)
   }

   If (($Section -eq 0) -and ($Column -eq 0)) {
      Write-Warning -Message "The Section and Column fields for the [$WebPartTitle] web part have been left blank or have zero values"
      try {
         Add-PnPClientSideWebPart -Page $PageName -DefaultWebPartType List -WebPartProperties $webPartProperties
      }
      catch {
         Write-Error -Message "Unable to add [$WebPartTitle] web part to the [$PageName] page. Check that there is a section [$Section] with [$Column] columns"
      }
   }
   Else {
      try {                     
         Add-PnPClientSideWebPart -Page $PageName -DefaultWebPartType List -WebPartProperties $webPartProperties -Section $Section -Column $Column -ErrorAction Stop 
      }
      catch {
         Write-Error -Message "Unable to add [$WebPartTitle] web part to the [$PageName] page. Check that there is a section [$Section] with [$Column] columns"
      }
   }
}


try {
   Write-Verbose -Message "Importing site worksheet from the excel configuration file: [$configFilePath]"
   $xlSiteSheet = Import-Excel -Path $configFilePath -WorkSheetname Site 
}
catch {
   Write-Error -Message "Unable to open spreadsheet from [$configFilePath] or 'Site' worksheet does not exist"
   EXIT
}


try {
   Write-Verbose -Message "Importing site url from the site worksheet."
   $site = $xlSiteSheet[0].'TargetSiteUrl'  
    
   Write-Verbose -Message "Connecting to site: $site"
   Connect-PnPOnline -Url $site
}
catch {
   Write-Error -Message "Unable to open site at [$site]"
   EXIT
}


try {
   Write-Verbose -Message "Importing ModernPages worksheet from the excel configuration file."
   $xlPagesSheet = Import-Excel -Path $configFilePath -WorkSheetname ModernPages 
}
catch { 
   Write-Error -Message "Unable to open spreadsheet from [$configFilePath] or 'ModernPages' worksheet does not exist."
   EXIT
}

Write-Verbose -Message "Begin adding ModernPages to the site."


ForEach ($row in $xlPagesSheet) {
   $page = $row.'PageName'; 
   $layout = $row.'LayoutType'; 
   $sections = $row.'Sections'; 

   
   try {
      Write-Verbose -Message "Adding the $page page with $layout layout."
      Add-PnPClientSidePage -Name $page -LayoutType $layout
   }
   catch {
      Write-Warning -Message "Unable to add [$page] page."
   }
   
   
   if ($sections) {

      $arraySections = $sections.split("`n"); 
      $sectionOrder = 1

      ForEach ($section in $arraySections) {
         Write-Verbose -Message "Adding the $section section to the $page page. Section order is $sectionOrder."
         try {
            Add-PnPClientSidePageSection -Page $page  -SectionTemplate $section -Order $sectionOrder
         }
         catch {
            Write-Warning -Message "Unable to add [$section] section to [$page] page. Ensure [$section] is a valid Section Template value (e.g. OneColumn, TwoColumn, ThreeColumn etc)"
         }
         $sectionOrder++
      }
   }
} 

try {
   Write-Verbose -Message "Importing ModernListLibraryWebParts worksheet from the excel configuration file."
   $xlWebPartsSheet = Import-Excel -Path $configFilePath -WorkSheetname ModernListLibraryWebParts 
}
catch { 
   Write-Error -Message "Unable to open spreadsheet from [$configFilePath] or 'ModernListLibraryWebParts' worksheet does not exist."
   EXIT
}

Write-Verbose -Message "Begin adding Modern List / Library web parts to pages:"


ForEach ($row in $xlWebPartsSheet) {
   $page = $row.'PageName'; 
   $section = $row.'Section'; 
   $column = $row.'Column'; 
   
   $wpType = $row.'WebPartType'; 
   $listLibraryName = $row.'ListOrLibraryName'; 
   $viewName = $row.'ViewName'; 
   $wpTitle = $row.'WebPartTitle'; 
   $wpHeight = $row.'WebPartHeight'; 

   Write-Verbose -Message "Adding web part to the '$page' page with title [$wpTitle]"
   Write-Verbose -Message "web part will be added with '$viewName' view for the '$listLibraryName' $wpType"
   Write-Verbose -Message "web part will be added to column $column in section $section height is set to $wpHeight" 
    
   Add-PnPModernListWebPart -PageName $page -WebPartType $wpType -ListName $listLibraryName -ViewName $viewName -WebPartHeight $wpHeight -WebPartTitle $wpTitle -Section $section -Column $column 
}

