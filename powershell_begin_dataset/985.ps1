Param(
    [parameter(Mandatory=$true)]
    $CsvFilePath
)

$ErrorActionPreference = "Stop"

$scriptsPath = $PSScriptRoot
if ($PSScriptRoot -eq "") {
    $scriptsPath = "."
}

. "$scriptsPath\asr_logger.ps1"
. "$scriptsPath\asr_common.ps1"
. "$scriptsPath\asr_csv_processor.ps1"

Function ProcessItemImpl($processor, $csvItem, $reportItem) {
    
    
    $reportItem | Add-Member NoteProperty "AdditionalInfoForReporting" $null
    $processor.Logger.LogTrace("Sample log - $($csvItem.SOURCE_MACHINE_NAME)")
    $reportItem.AdditionalInfoForReporting = "test_info" 
}

Function ProcessItem($processor, $csvItem, $reportItem) {
    try {
        
        ProcessItemImpl $processor $csvItem $reportItem
    }
    catch {
        $exceptionMessage = $_ | Out-String
        $processor.Logger.LogError($exceptionMessage)
        throw
    }
}


$logger = New-AsrLoggerInstance -CommandPath $PSCommandPath


$asrCommon = New-AsrCommonInstance -Logger $logger


$processor = New-CsvProcessorInstance -Logger $logger -ProcessItemFunction $function:ProcessItem
$processor.ProcessFile($CsvFilePath)
