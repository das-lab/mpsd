

function Get-TreeObjectArrayAsList{



    param(    
        $Array,        
        $Attribute,        
        $Level = 0
    )

    
    $Array = $Array.psobject.Copy()

    $Array | %{
        
        
        $Childs = iex "`$_.$Attribute"
    
        
        $_ | select *, @{L="Level";E={$Level}}
    
        
        if($Childs){
        
            
            $Childs | %{Get-TreeObjectArrayAsList -Array $_ -Attribute $Attribute -Level ($Level + 1)}
        }
    }
}