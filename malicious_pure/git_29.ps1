function Get-ClipboardContents {


    [CmdletBinding()] Param (
        [Parameter(Position = 1)]
        [UInt32]
        $CollectionLimit,

        [Parameter(Position = 2)]
        [UInt32]
        $PollInterval = 15
    )

    Add-Type -AssemblyName System.Windows.Forms

    
    if($CollectionLimit) {
        $StopTime = (Get-Date).addminutes($CollectionLimit)
    }
    else {
        $StopTime = (Get-Date).addyears(10)
    }

    $TimeStamp = (Get-Date -Format dd/MM/yyyy:HH:mm:ss:ff)
    "=== Get-ClipboardContents Starting at $TimeStamp ===`n"

    
    $PrevLength = 0
    $PrevFirstChar = ""

    for(;;){
        if ((Get-Date) -lt $StopTime){

            
            $tb = New-Object System.Windows.Forms.TextBox
            $tb.Multiline = $true
            $tb.Paste()

            
            if (($tb.Text.Length -ne 0) -and ($tb.Text.Length -ne $PrevLength)){
                
                
                
                if($PrevFirstChar -ne ($tb.Text)[0]){
                    $TimeStamp = (Get-Date -Format dd/MM/yyyy:HH:mm:ss:ff)
                    "`n=== $TimeStamp ===`n"
                    $tb.Text
                    $PrevFirstChar = ($tb.Text)[0]
                    $PrevLength = $tb.Text.Length 
                }
            }
        }
        else{
            $TimeStamp = (Get-Date -Format dd/MM/yyyy:HH:mm:ss:ff)
            "`n=== Get-ClipboardContents Shutting down at $TimeStamp ===`n"
            Break;
        }
        Start-Sleep -s $PollInterval
    }
}
