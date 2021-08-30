




function Out-CurrentFile {
    
    [CmdletBinding()]
    param(
        [Switch]$AsNewFile,

        [Parameter(ValueFromPipeline, Mandatory = $true)]
        $InputObject
    )

    Begin { $objectsToWrite = @() }
    Process { $objectsToWrite += $InputObject }
    End {

        
        if ($AsNewFile) {
            $psEditor.Workspace.NewFile()
        }

        $outputString = "@`"`r`n{0}`r`n`"@" -f ($objectsToWrite|out-string).Trim()

        try {
            
            $psEditor.GetEditorContext()
        }
        catch {
            
            $psEditor.Workspace.NewFile()
        }

        $psEditor.GetEditorContext().CurrentFile.InsertText($outputString)
    }
}
