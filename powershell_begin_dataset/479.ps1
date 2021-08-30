

function New-TreeObjectArray{



    param(    
        $Array,
        $Objects,     
        $Attribute,        
        $Filter,
        $Level = 0,
        $MaxLoops = 10
    )
    
    
    $Objects = $Objects.psobject.Copy()

    if( -not ($Level -eq $MaxLoops)){
                
        $Level++        

        $Objects | %{

            if(iex "`$_.$Attribute"){

                iex "`$_.$Attribute = `$_.$Attribute | %{`$FilterValue = `$_;`$Array | where{`$_.$Filter -eq `$FilterValue}}"

                iex "`$_.$Attribute = `$_.$Attribute | %{`$_ | %{ New-TreeObjectArray -Array `$Array -Objects `$_ -Attribute `$Attribute -Filter `$Filter -Level `$Level -MaxLoops `$MaxLoops}}"
             
                $_

            }else{

                $_
            }
        }
    }else{

        $null    }
}




