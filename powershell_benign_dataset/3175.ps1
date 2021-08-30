function Open-ISEFunction {
     
    [cmdletbinding()]
    param(
    
    
    [ValidateScript({ Get-Command -commandtype function -name $_ })]
        [string[]]$function
    )

    foreach($fn in $function){
        
        
        $definition = (Get-Command -commandtype function -name $fn).definition
        
        
        if($definition){
            
            
            $definition = "function $fn { $definition }"
            
            
            $tab = $psise.CurrentPowerShellTab.files.Add()
            $tab.editor.text = $definition

            
            $tab.editor.SetCaretPosition(1,1)

            
            start-sleep -Milliseconds 200
        }
    }
}