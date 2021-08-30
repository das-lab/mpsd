

function Mount-TrueCyptContainer{



    [CmdletBinding()]
    param(

        [Parameter(Mandatory=$true)]
		[String]
		$Name   
	)
  
    
    
    
    if(-not (Get-Command TrueCrypt)){
    
        throw ("Command TrueCrypt not available, try `"Install-PPApp TrueCrypt`"")
    }
    
    $MountedContainers = Get-PPConfiguration $PSconfigs.TrueCryptContainer.DataFile | ForEach-Object{$_.Content.MountedContainer}
    
    Get-TrueCryptContainer -Name $Name | ForEach-Object{        
        
        $TrueCryptContainer = $_
        
        $MountedContainer = $MountedContainers | where{$_.Name -eq $TrueCryptContainer.Name}
            
        if($MountedContainer){
            
            Write-Error "TrueCrypt container: $($_.Name) already mounted to drive: $($MountedContainer.Drive)"
            
			$_ | select Key, Name, @{L="Drive";E={$MountedContainer.Drive}}
                        
        }else{
        
            $Drive = Get-AvailableDriveLetter -FavoriteDriveLetter $_.FavoriteDriveLetter
        
            Write-Host "Mount TrueCrypt container: $($_.Name) to drive: $Drive" 
            & TrueCrypt /quit /auto /letter $Drive /volume $_.Path
            
            
            $TrueCryptDataFiles = Get-ChildItem -Path $PSconfigs.Path -Filter $PSconfigs.TrueCryptContainer.DataFile -Recurse
            
            $(if(-not $TrueCryptDataFiles){
            
                Write-Host "Create TrueCrypt data file in config folder"                     
                Copy-Item -Path (Get-ChildItem -Path $PStemplates.Path -Filter $PSconfigs.TrueCryptContainer.DataFile -Recurse).FullName -Destination $PSconfigs.Path -PassThru
                
            }else{
            
                $TrueCryptDataFiles
                
            }) | ForEach-Object{

                $Xml = [xml](get-content $_.Fullname)
                $Element = $Xml.CreateElement("MountedContainer")
                $Element.SetAttribute("Name",$TrueCryptContainer.Name)
                $Element.SetAttribute("Drive",$Drive)
                $Content = Select-Xml -Xml $Xml -XPath "//Content"
                $Null = $Content.Node.AppendChild($Element)
                $Xml.Save($_.Fullname)
            }
			
			
			$_ | select Key, Name, @{L="Drive";E={$Drive}}
        }
    }
}