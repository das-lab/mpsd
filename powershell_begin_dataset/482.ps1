

function Remove-PPScriptShortcut{



    [CmdletBinding()]
    param(

        [Parameter(Mandatory=$true)]
		[String]
		$Name
	)
  
    
    
    
    
    $ShortcutToRemove = Get-PPScript -Name $Name -Shortcut
    
    if($ShortcutToRemove){
    
        Get-ChildItem -Path $PSconfigs.Path -Filter $PSconfigs.ScriptShortcut.DataFile -Recurse | %{
        
            Write-Host "Remove script shorcut: $($ShortcutToRemove.Name)"
        
            $Xml = [xml](get-content $_.Fullname)
            $RemoveNode = Select-Xml $xml -XPath "//Content/ScriptShortcut[@Name=`"$($ShortcutToRemove.Name)`"]"
            $null = $RemoveNode.Node.ParentNode.RemoveChild($RemoveNode.Node)
            $Xml.Save($_.Fullname)
        }
    }
}