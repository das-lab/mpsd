

function Install-PPApp{



	param(
        [Parameter(Mandatory=$false)]
		[String[]]
		$Name,
                
        [switch]
        $Force,
        
        [switch]
        $IgnoreDependencies,
                
        [switch]
        $Uninstall
	)
    
    
    $CurrentLocation = (Get-Location).Path
    $AppData = @()	
    
    
    
    
    $CurrentAppDataFile = Join-Path $CurrentLocation $PSconfigs.App.DataFile
    
    
    $GlobalAppDataFile = (Get-ChildItem -Path $PSconfigs.Path -Filter $PSconfigs.App.DataFile -Recurse).Fullname
    
    
    if(-not $GlobalAppDataFile){
        Copy-PPConfigurationFile -Name $PSconfigs.App.DataFile
        $GlobalAppDataFile = (Get-ChildItem -Path $PSconfigs.Path -Filter $PSconfigs.App.DataFile -Recurse).Fullname
    }
    
    
    $AppData += Get-PPConfiguration -Filter $PSconfigs.App.DataFile | ForEach-Object{$_.Content.App}
    
    
    if(Test-Path $CurrentAppDataFile){
        $CurrentInstalledApps = Get-PPConfiguration -Path $CurrentAppDataFile | ForEach-Object{$_.Content.App}
        $AppData += $CurrentInstalledApps
    }
    
    
    if($Name){
    
        $NameAndVersions = $Name | ForEach-Object{
                
            $Version = $_.split("
            if(-not $Version){$Version = "*"}
            
            @{
                Name = $_.split("
                Version = $Version            
            }
        }
    
    }elseif($CurrentInstalledApps){
    
        $NameAndVersions = $CurrentInstalledApps | select Name, Version
    }
    
    
        
    $NameAndVersions | ForEach-Object{
    
        $Version = $_.Version
        Get-PPApp $_.Name | 
        sort Version -Descending |
        where{$_.Version -like $Version} |
        select -First 1
        
    } | ForEach-Object{
        
        
        $Name = $_.Name
        
        
        [Version]$Version = $_.Version
                
        
        $Options = $_.Option
        
        
        $AllowMultipleVersion = $false
                               
        
        
        
        $AppEntry = $AppData | where{$_.Name -eq $Name}
                
        
        $InstalledApp = $AppEntry | where{$_.Version -eq $Version}
        
        if($Uninstall -and -not $InstalledApp){
        
            $InstalledApp = $null
        
        }elseif(-not $InstalledApp){
        
            $InstalledApp = $AppData | where{$_.Name -eq $Name}
        }
        
        
        switch($Options){
            "AllowMultipleVersions" {$InstalledApp = $null}
            "AllowMultipleMajorVersions" {
              
                $InstalledApp = $AppEntry | where{([Version]$_.Version).Major -eq $Version.Major}
                $AllowMultipleVersion = $true               
            }
            "AllowMultipleMinorVersions" {
                
                $InstalledApp = $AppEntry | where{([Version]$_.Version).Major -eq $Version.Major -and ([Version]$_.Version).Minor -eq $Version.Minor}
                $AllowMultipleVersion = $true 
            }
            "AllowMultipleBuildVersions" {
            
                $InstalledApp = $AppEntry | where{([Version]$_.Version).Major -eq $Version.Major -and ([Version]$_.Version).Minor -eq $Version.Minor -and ([Version]$_.Version).Build -eq $Version.Build}
                $AllowMultipleVersion = $true 
            }
            "AllowMultipleRevisionVersions" {
            
                $InstalledApp = $null
            }
        }
        
        
        
        if((-not $InstalledApp -and $Uninstall) -or ($InstalledApp.Status -eq "AppUninstalled" -and $Uninstall) -or ((([Version]$InstalledApp.Version -eq $Version) -or ([Version]$InstalledApp.Version -gt $Version)) -and -not ($Force -or $Uninstall) -and ($InstalledApp.Status -ne "AppUninstalled"))){
            if(-not $InstalledApp -and $Uninstall){
                Write-Warning "The Package: $Name is not installed"
            }elseif($Uninstall){
                Write-Warning "The Package: $Name is already uninstalled"
            }else{
                Write-Warning "The Package: $Name is already installed, use the force parameter to reinstall package, to downgrade it, or the uninstall parameter to remove this package"
            }
        
        }elseif(($InstalledApp -and $Force) -or -not ($InstalledApp -and $Force)){        
        
            
            $ScriptPath = $((Get-ChildItem -Path $PSlib.Path -Filter $_.Script -Recurse | select -First 1).FullName)
            $Path = "$($CurrentLocation)\"
                   
            if(-not $Uninstall -and -not $IgnoreDependencies){
            
                $_.Dependency | where{$_} | ForEach-Object{                    
                    
                    Write-Host "Installing Dependencies for $Name ..."
                    Install-PPApp -Name $(if($_.Version){"$($_.Name)
                    
                }
            } 
                       
            
            if($Uninstall){
            
                 Write-Host "Uninstalling $($_.Name) Version $($_.Version) ..."
            
            
            }elseif($InstalledApp -and ([Version]$InstalledApp.Version -ne $Version) -and ($InstalledApp.Status -ne "AppUninstalled")){
                
                
                if([Version]$InstalledApp.Version -lt $Version){
            
                    Write-Host "Updating $($_.Name) from Version $($AppEntry.Version) to Version $($_.Version)..."
                    $Update = $InstalledApp
                
                
                }elseif([Version]$InstalledApp.Version -gt $Version){
                
                    Write-Host "Downgrading $($_.Name) from Version $($AppEntry.Version) to Version $($_.Version)..."
                    $Downgrade = $InstalledApp
                
                }
            
            
            }elseif($AppEntry -and $InstalledApp -and ($InstalledApp.Status -ne "AppUninstalled")){   
            
                Write-Host "Reinstalling $($_.Name) Version $($_.Version) ..."
            
            }else{                            

                Write-Host "Installing $($_.Name) Version $($_.Version) ..."
            }           
            
            $Config = Invoke-Expression "& `"$ScriptPath`" -Version $($_.Version) -Path $Path -Force:`$Force -Update:`$Update -Downgrade:`$Downgrade -Uninstall:`$Uninstall"                    
            
            if($Options -contains "UseLocalConfig"){
            
                
                if(-not (Test-Path $CurrentAppDataFile)){
                    Copy-PPConfigurationFile -Name $PSconfigs.App.DataFile -Destination $CurrentLocation
                }
                $Xml = [xml](Get-Content (Join-Path $CurrentLocation $PSconfigs.App.DataFile))
                $AppDataFile = $CurrentAppDataFile                
                
            }else{
            
                
                $Xml = [xml](Get-Content $GlobalAppDataFile)   
                $AppDataFile = $GlobalAppDataFile    
            }
            
            
            if($Config.Result -eq "Error"){
                  
                Write-Error "Installion of $($_.Name) completed unsuccessfully."           
            }   
                    
            
            if($Config.Result -eq "ConditionExclusion"){
                
                Write-Error "Conditions exclution for $($_.Name) matched: $($Config.ConditionExclusion)"
            }  
              
            
            if($Config.Result -eq "AppDowngraded"){
            
                Write-Host "Downgrade of $($_.Name) to Version $($_.Version) completed successfully."
            
                $Element = Select-Xml -Xml $xml -XPath "//Content/App"| where{$_.Node.Name -eq $Name -and ($_.Node.Version -eq $InstalledApp.Version -or -not $InstalledApp)}
                $Element.Node.Status = $Config.Result
                $Element.Node.Version = $_.Version            
            }
                       
            
            if($Config.Result -eq "AppUpdated"){
            
                Write-Host "Update of $($_.Name) to Version $($_.Version) completed successfully."
            
                $Element = Select-Xml -Xml $xml -XPath "//Content/App"| where{$_.Node.Name -eq $Name -and ($_.Node.Version -eq $InstalledApp.Version -or -not $InstalledApp)}
                $Element.Node.Status = $Config.Result
                $Element.Node.Version = $_.Version            
            }
            
            
            if($InstalledApp -and $Config.Result -eq "AppInstalled"){
            
                Write-Host "Reinstallation of $($_.Name) completed successfully."     
                                
                $Element = Select-Xml -Xml $xml -XPath "//Content/App"| where{$_.Node.Name -eq $Name -and ($_.Node.Version -eq $InstalledApp.Version -or -not $InstalledApp)}
                $Element.Node.Status = $Config.Result
                $Element.Node.Version = $_.Version
            }
            
            
            if($Config.Result -eq "AppInstalled" -and -not $InstalledApp){
            
                Write-Host "Installation of $($_.Name) completed successfully."
                
                $Element = $Xml.CreateElement("App")
                $Element.SetAttribute("Name",$_.Name)
                $Element.SetAttribute("Version",$_.Version)
                $Element.SetAttribute("Status", $Config.Result)
                $Content = Select-Xml -Xml $Xml -XPath "//Content"
                $Null = $Content.Node.AppendChild($Element)
                
            }
            
            
            if($Config.Result -eq "AppUninstalled"){
            
                Write-Host "Uninstallaton of $($_.Name) completed successfully."
            
                $Element = Select-Xml -Xml $xml -XPath "//Content/App"| where{$_.Node.Name -eq $Name -and ($_.Node.Version -eq $InstalledApp.Version -or -not $InstalledApp)}
                $Element.Node.Status = $Config.Result        
            }
            
            
            $Xml.Save($AppDataFile)
        }          
    }    
}