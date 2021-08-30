














function Test-StorageSync
{
    Write-Verbose "RecordMode : $(Get-StorageTestMode)"
    Get-Command Invoke-AzStorageSyncCompatibilityCheck
}
