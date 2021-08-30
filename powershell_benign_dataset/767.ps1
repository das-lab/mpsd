






function Invoke-MyCommand {
    Write-Output "My command's function was executed!"
}



Register-EditorCommand -Verbose `
   -Name "MyModule.MyCommandWithFunction" `
   -DisplayName "My command with function" `
   -Function Invoke-MyCommand



Register-EditorCommand -Verbose `
   -Name "MyModule.MyCommandWithScriptBlock" `
   -DisplayName "My command with script block" `
   -ScriptBlock { Write-Output "My command's script block was executed!" }



function Invoke-MyEdit([Microsoft.PowerShell.EditorServices.Extensions.EditorContext]$context) {

    

    $context.CurrentFile.InsertText(
        "`r`n
        35, 1);

    

    

    
    
    
}





Register-EditorCommand -Verbose `
   -Name "MyModule.MyEditCommand" `
   -DisplayName "Apply my edit!" `
   -Function Invoke-MyEdit `
   -SuppressOutput
