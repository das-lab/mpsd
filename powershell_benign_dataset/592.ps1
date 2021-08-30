

function Dismount-TrueCyptContainer{



    [CmdletBinding()]
    param(

        [Parameter(Mandatory=$false)]
		[String]
		$Name 
	)
  
    
    
    
        
    if(-not (Get-Command TrueCrypt)){
    
        throw ("Command TrueCrypt not available, try `"Install-PPApp TrueCrypt`"")
    }
        
    Get-TrueCryptContainer -Name:$Name -Mounted | %{   
        
        Write-Host "Dismount TrueCrypt container: $($_.Name) on drive: $($_.Drive)" 
        & TrueCrypt /quit /dismount $_.Drive
        Start-Sleep -s 3
        (Get-ChildItem ($_.Path)).lastwritetime = Get-Date

        
        $_ 
        
    } | %{
    
        $TrueCryptContainer = $_
    
        Get-ChildItem -Path $PSconfigs.Path -Filter $PSconfigs.TrueCryptContainer.DataFile -Recurse| %{
    
            $Xml = [xml](get-content $_.Fullname)
            $RemoveNode = Select-Xml $xml -XPath "//Content/MountedContainer[@Name=`"$($TrueCryptContainer.Name)`"]"
            $null = $RemoveNode.Node.ParentNode.RemoveChild($RemoveNode.Node)
            $Xml.Save($_.Fullname)
    
        }
    }
}