function PRobocopy {
    param (
        [string]$Source = $PWD,
        [string]$Destination = 'NULL',
        [string[]]$Include,
        [long]$Retries = 1000000,
        [long]$WaitTime = 30,
        [string]$ExcludeAttributes,    
        [switch]$ExcludeChanged,
        [switch]$ExcludeNewer,
        [switch]$ExcludeOlder,
        [switch]$ListOnly,
        [switch]$Recurse,
        [switch]$NoJobHeader,
        [switch]$Bytes,
        [switch]$FullPathname,
        [switch]$NoClass,
        [switch]$NoDirectoryList,
        [switch]$TimeStamps,
        [switch]$ExcludeJunctions,
        [switch]$Mirror,
        [switch]$FATFileTimes,
        [switch]$Restartable
    )

    if ($Source, $Destination, $Include, $ExcludeAttributes, $args -match '\?') {
        cmd /c Robocopy.exe /?
        return
    }
    if (!$Source) { Throw 'No source directory provided' }
        
    $params = @()
    if ($Destination.ToUpper() -eq 'NULL') {$params += '/L'}
    if ($Retries -ne 1000000)    {$params += "/R:$Retries"}
    if ($WaitTime -ne 30)        {$params += "/W:$WaitTime"}
    if ($ExcludeAttributes)      {$params += "/XA:$ExcludeAttributes"} 
    if ($ExcludeChanged)    {$params += '/XC'}
    if ($ExcludeNewer)      {$params += '/XN'}
    if ($ExcludeOlder)      {$params += '/XO'}
    if ($ListOnly)          {$params += '/L'}
    if ($Recurse)           {$params += '/S'}
    if ($NoJobHeader)       {$params += '/NJH'}
    if ($Bytes)             {$params += '/BYTES'}
    if ($FullPathname)      {$params += '/FP'}
    if ($NoClass)           {$params += '/NC'}
    if ($NoDirectoryList)   {$params += '/NDL'}
    if ($TimeStamps)        {$params += '/TL'}
    if ($ExcludeJunctions)  {$params += '/XJ'}
    if ($Mirror)            {$params += '/MIR'}
    if ($FATFileTimes)      {$params += '/FFT'}
    if ($Restartable)       {$params += '/Z'}
    if ($Include)           {$params += $Include}
    
    
    
    
    

    robocopy $Source $Destination $params
}



