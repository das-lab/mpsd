

function Add-PPScriptShortcut{



    [CmdletBinding()]
    param(

        [Parameter(Mandatory=$true)]
		[String]
		$Name,
 
        [Parameter(Mandatory=$false)]
		[String]
		$ShortcutKey,
                 
        [Parameter(Mandatory=$false)]
		[String]
		$ShortcutName
	)
  
    
    
    

    
    if(-not $ShortcutName){$ShortcutName = $Name}

    
    $ShortcutFiles = Get-ChildItem -Path $PSconfigs.Path -Filter $PSconfigs.ScriptShortcut.DataFile -Recurse
        
    
    Get-PPScript -Name $Name | select -First 1 | %{
    
        $Script = $_
    
        
        if($ShortcutKey){
            if( (Get-PPScript -Name $Name -Shortcut) -or                
                (Get-PPScript -Name $ShortcutName -Shortcut) -or
                (Get-PPScript -Name $ShortcutKey -Shortcut)
            ){
                throw "This script shortcut name, key or filename already exists, these attributes have to be unique."
            }
        }elseif( (Get-PPScript -Name $Name -Shortcut) -or                
            (Get-PPScript -Name $ShortcutName -Shortcut)        
        ){
            throw "This script shortcut name, filename already exists, these attributes have to be unique."
        }
    
        
        $(if(-not $ShortcutFiles){
        
            Write-Host "Create Shortcut data file in config folder"                     
            Copy-Item -Path (Get-ChildItem -Path $PStemplates.Path -Filter $PSconfigs.ScriptShortcut.DataFile -Recurse).FullName -Destination $PSconfigs.Path -PassThru
            
        }else{
        
            $ShortcutFiles
            
        }) | %{
        
            Write-Host "Adding script shortcut: $ShortcutName refering to: $($Script.Name)"

            $Xml = [xml](get-content $_.Fullname)
            $Element = $Xml.CreateElement("ScriptShortcut")
            $Element.SetAttribute("Key",$ShortcutKey)
            $Element.SetAttribute("Name",$ShortcutName)
            $Element.SetAttribute("Filename", $Script.Name)
            $Content = Select-Xml -Xml $Xml -XPath "//Content"
            $Null = $Content.Node.AppendChild($Element)
            $Xml.Save($_.Fullname)
			
			
			$_ | select @{L="Key";E={$ShortcutKey}}, @{L="Name";E={$ShortcutName}}, @{L="Filename";E={$Script.Name}}
        }
    }
}