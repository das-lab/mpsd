

function Get-SPManagedMetadataServiceTerms{



    [CmdletBinding()]
    param(

		[Parameter(Mandatory=$true)]
		[String]
		$Site,

		[String]
		$TermGroup
        
	)
    
    
    
    

    function Add-ArrayLevelIndex{

        param(
    
            $Object,        
            $AttributeName,        
            $Level = 0
        )
    
        
        $Objects = iex "`$Object.$AttributeName"
    
        
        $Object | select @{L="Object";E={$_}}, @{L="Level";E={$Level}}
    
        
        if($Objects){
    
            
            $Level ++
        
            
            $Objects | %{Add-ArrayLevelIndex -Object $_ -AttributeName $AttributeName -Level $Level}

        }
    }

    
    
    
    if((Get-PSSnapin 'Microsoft.SharePoint.PowerShell' -ErrorAction SilentlyContinue) -eq $null){Add-PSSnapin 'Microsoft.SharePoint.PowerShell'}

    
    
    
    $SPTaxonomies = @()
    $TempTerm = New-Object -TypeName Psobject @{    
        Index = ""
        Term = ""
    }

    $i = 0;
    $TempTerms = while($i -ne 7){
        $i ++
        $e = $TempTerm.PSObject.Copy()
        $e.Index = $i
        $e
    }


    
    $SPTaxonomies = Get-SPTaxonomySession -Site $Site | %{

        $_.TermStores | %{
    
            $TermStore = New-Object -TypeName Psobject -Property @{
        
                TermStore = $_.Name
                "Term Group" = ""
                "Term Set Name" = ""
                "Term Set Description" = ""   
                LCID = ""             
                "Available for Tagging" = ""                
                Terms = ""      
            }        
        
        
            $_.Groups | Where{$_.Name -eq $TermGroup -or -not $TermGroup} | ForEach-Object{
            
                $Group = $TermStore.PSObject.Copy()
                $Group.'Term Group' = $_.Name                       
        
                $_.TermSets | %{
            
                    $TermSet = $Group.PSObject.Copy()
                    $TermSet.'Term Set Name' = $_.Name
                    $TermSet.'Term Set Description' = $_.Description
                                    
                    $TermSet.Terms = ($_.Terms | %{Add-ArrayLevelIndex -Object $_ -AttributeName "Terms" -Level 1})
            
                    $TermSet                  
                }        
            }        
        }
    }

    
    
    

    
    $SPTaxonomies | %{

        $SPTaxonomy = $_

        
        $Item = $SPTaxonomy.PSObject.Copy()  
        $Item.'Available for Tagging' = if($_.IsAvailableForTagging){"TRUE"}else{"FALSE"}        
        $i = 0;while($i -ne 7){
            $i ++
            $Item | Add-Member –MemberType NoteProperty –Name "Level $i Term" –Value ""
        }
        $Item |  Select-Object 'Term Set Name','Term Set Description', LCID, 'Available for Tagging', 'Term Description', 'Level*'

    
        
        $_.Terms | where{$_} | %{
                
            $Term = $_

            
            $Item = $SPTaxonomy.PSObject.Copy()   
             
            $Item.'Available for Tagging' = if($_.IsAvailableForTagging){"TRUE"}else{"FALSE"}
            $Item.'Term Set Name' = ""
            $Item.'Term Set Description' = ""
            
            $_.Object.Labels | ForEach-Object{

                $Item.LCID = $_.Language

                $Index = 0;while($Index -ne 7){
                    $Index ++

                    if($Term.Level -eq $Index){                        

                        $Item | Add-Member –MemberType NoteProperty –Name "Level $Index Term" –Value $Term.Object.Name

                        $TempTerms[$Index].Term = $Term.Object.Name

                    }elseif($Index -gt $Term.Level){
                            
                        $Item | Add-Member –MemberType NoteProperty –Name "Level $Index Term" –Value $Value

                    }elseif($Term.Level -gt $Index){

                        $Item | Add-Member –MemberType NoteProperty –Name "Level $Index Term" –Value $TempTerms[$Index].Term
                        
                    }                                   
                }  
            }   
        
            
            $Item |  Select-Object 'Term Set Name','Term Set Description', LCID, 'Available for Tagging', 'Term Description', 'Level*'
        }                
    }
}