    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
     
    param($path=$(throw 'path is required.'), $serverName, $configFile, [switch]$nolog)
     
    
    
    
    
    [reflection.assembly]::Load("Microsoft.SqlServer.ManagedDTS, Version=10.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91") > $null
    
    
     
    $myName = 'RunSSIS.ps1'
     
    
    function New-ISApplication
    {
       new-object ("Microsoft.SqlServer.Dts.Runtime.Application")
     
    } 
     
    
    function Test-ISPath
    {
        param([string]$path=$(throw 'path is required.'), [string]$serverName=$(throw 'serverName is required.'), [string]$pathType='Any')
     
        
        $serverName = $serverName -replace "\\.*"
     
        
     
        $app = New-ISApplication
     
        switch ($pathType)
        {
            'Package' { trap { $false; continue } $app.ExistsOnDtsServer($path,$serverName) }
            'Folder'  { trap { $false; continue } $app.FolderExistsOnDtsServer($path,$serverName) }
            'Any'     { $p=Test-ISPath $path $serverName 'Package'; $f=Test-ISPath $path $serverName 'Folder'; [bool]$($p -bor $f)}
            default { throw 'pathType must be Package, Folder, or Any' }
        }
     
    } 
     
    
    function Get-ISPackage
    {
        param([string]$path, [string]$serverName)
     
        
        $serverName = $serverName -replace "\\.*"
     
        $app = New-ISApplication
     
        
        if ($path -and $serverName)
        {
            if (Test-ISPath $path $serverName 'Package')
            { $app.LoadFromDtsServer($path, $serverName, $null) }
            else
            { Write-Error "Package $path does not exist on server $serverName" }
        }
        
        elseif ($path -and !$serverName)
        {
            if (Test-Path -literalPath $path)
            { $app.LoadPackage($path, $null) }
            else
            { Write-Error "Package $path does not exist" }
        }
        else
        { throw 'You must specify a file path or package store path and server name' }
       
    } 
     
    
    
     
    Write-Verbose "$myName path:$path serverName:$serverName configFile:$configFile nolog:$nolog.IsPresent"
     
    if (!($nolog.IsPresent))
    {
        $log = Get-EventLog -List | Where-Object { $_.Log -eq "Application" }
        $log.Source = $myName
        $log.WriteEntry("Starting:$path",'Information')
    }
     
    $package = Get-ISPackage $path $serverName
     
    if ($package)
    {
     
        if ($configFile)
        {
            if (test-path -literalPath $configFile)
            { $package.ImportConfigurationFile("$configFile") }
            else
            {
                $err = "Invalid file path. Verify configFile:$configFile"
                if (!($nolog.IsPresent)) { $log.WriteEntry("Error:$path:$err",'Error') }
                throw ($err)
                break
            }
        }
     
        $package.Execute()
        $err = $package.Errors | foreach { $_.Source.ToString() + ':' + $_.Description.ToString() }
     
        if ($err)
        {
            if (!($nolog.IsPresent)) { $log.WriteEntry("Error:$path:$err",'Error') }
            throw ($err)
            break
        }
        else
        {
            if (!($nolog.IsPresent)) { $log.WriteEntry("Completed:$path",'Information') }
        }
    }
    else
    {
        $err = "Cannot Load Package. Verify Path:$path and Server:$serverName"
        if (!($nolog.IsPresent)) { $log.WriteEntry("Error:$path:$err",'Error') }
        throw ($err)
        break
    }
    
    
