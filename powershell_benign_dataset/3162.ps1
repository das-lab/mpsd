









Function Dump-AzureDomainInfo-MSOL
{


    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false,
        HelpMessage="Folder to output to.")]
        [string]$folder
    )

    
    if ($folder){if(Test-Path $folder){if(Test-Path $folder"\MSOL"){}else{New-Item -ItemType Directory $folder"\MSOL"|Out-Null}}else{New-Item -ItemType Directory $folder|Out-Null ; New-Item -ItemType Directory $folder"\MSOL"|Out-Null}}
    else{if(Test-Path MSOL){}else{New-Item -ItemType Directory MSOL|Out-Null};$folder=".\"}

    
    Connect-MsolService

    
    Write-Verbose "Getting Domain Contact Info..."
    Get-MsolCompanyInformation | Out-File -LiteralPath $folder"\MSOL\DomainCompanyInfo.txt"

    
    Write-Verbose "Getting Domains..."
    $domains = Get-MsolDomain 
    $domains | select  Name,Status,Authentication | Export-Csv -NoTypeInformation -LiteralPath $folder"\MSOL\Domains.CSV"
    $domainCount = $domains.Count
    Write-Verbose "$domainCount Domains were found."

    
    Write-Verbose "Getting Domain Users..."
    $userCount=0
    $domains | select  Name | ForEach-Object {$DomainIter=$_.Name; $domainUsers=Get-MsolUser -All -DomainName $DomainIter; $userCount+=$domainUsers.Count; $domainUsers | Select-Object @{Label="Domain"; Expression={$DomainIter}},UserPrincipalName,DisplayName,isLicensed | Export-Csv -NoTypeInformation -LiteralPath $folder"\MSOL\"$DomainIter"_Users.CSV"}
    Write-Verbose "$userCount Domain Users were found across $domainCount domains."

    
    Write-Verbose "Getting Domain Groups..."
    if(Test-Path $folder"\MSOL\Groups"){}
    else{New-Item -ItemType Directory $folder"\MSOL\Groups" | Out-Null}
    $groups = Get-MsolGroup -All -GroupType Security
    $groupCount = $groups.Count
    Write-Verbose "$groupCount Domain Groups were found."
    Write-Verbose "Getting Domain Users for each group..."
    $groups | Export-Csv -NoTypeInformation -LiteralPath $folder"\MSOL\Groups.CSV"
    $groups | ForEach-Object {$groupName=$_.DisplayName; Get-MsolGroupMember -All -GroupObjectId $_.ObjectID | Select-Object @{ Label = "Group Name"; Expression={$groupName}}, EmailAddress, DisplayName | Export-Csv -NoTypeInformation -LiteralPath $folder"\MSOL\Groups\group_"$groupName"_Users.CSV"}
    Write-Verbose "Domain Group Users were enumerated for $groupCount groups."

    
    Write-Verbose "Getting Domain Devices..."
    $devices = Get-MsolDevice -All 
    $devices | Export-Csv -NoTypeInformation -LiteralPath $folder"\MSOL\Domain_Devices.CSV"
    $deviceCount = $devices.Count
    Write-Verbose "$deviceCount devices were enumerated."


    
    Write-Verbose "Getting Domain Service Principals..."
    $principals = Get-MsolServicePrincipal -All
    $principals | Export-Csv -NoTypeInformation -LiteralPath $folder"\MSOL\Domain_SPNs.CSV"
    $principalCount = $principals.Count
    Write-Verbose "$principalCount service principals were enumerated."


    Write-Verbose "All done with MSOL tasks.`n"
}

Function Dump-AzureDomainInfo-AzureRM
{


    
    
    
    


    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false,
        HelpMessage="Folder to output to.")]
        [string]$folder
    )

    
    if ($folder){if(Test-Path $folder){if(Test-Path $folder"\AzureRM"){}else{New-Item -ItemType Directory $folder"\AzureRM"|Out-Null}}else{New-Item -ItemType Directory $folder|Out-Null ; New-Item -ItemType Directory $folder"\AzureRM"|Out-Null}}
    else{if(Test-Path AzureRM){}else{New-Item -ItemType Directory AzureRM|Out-Null};$folder=".\"}

    
    Login-AzureRmAccount

    
    $tenantID = Get-AzureRmTenant | select TenantId

    
    Write-Verbose "Getting Domain Users..."
    $userCount=0
    $users=Get-AzureRmADUser 
    $users | Export-Csv -NoTypeInformation -LiteralPath $folder"\AzureRM\Users.CSV"
    $userCount=$users.Count
    Write-Verbose "$userCount Domain Users were found."

    
    Write-Verbose "Getting Domain Groups..."
    if(Test-Path $folder"\AzureRM\Groups"){}
    else{New-Item -ItemType Directory $folder"\AzureRM\Groups" | Out-Null}
    $groups=Get-AzureRmADGroup
    $groupCount = $groups.Count
    Write-Verbose "$groupCount Domain Groups were found."
    Write-Verbose "Getting Domain Users for each group..."
    $groups | Export-Csv -NoTypeInformation -LiteralPath $folder"\AzureRM\Groups.CSV"
    $groups | ForEach-Object {$groupName=$_.DisplayName; Get-AzureRmADGroupMember -GroupObjectId $_.Id | Select-Object @{ Label = "Group Name"; Expression={$groupName}}, DisplayName | Export-Csv -NoTypeInformation -LiteralPath $folder"\AzureRM\Groups\group_"$groupName"_Users.CSV"}
    Write-Verbose "Domain Group Users were enumerated for $groupCount group(s)."

    
    
    
    
    $storageAccounts = Get-AzureRmStorageAccount | select StorageAccountName,ResourceGroupName 
    
    if(Test-Path $folder"\AzureRM\Files"){}
    else{New-Item -ItemType Directory $folder"\AzureRM\Files" | Out-Null}

    Foreach ($storageAccount in $storageAccounts){
        $StorageAccountName = $storageAccount.StorageAccountName
        Write-Verbose "Listing out blob files for the $StorageAccountName storage account..."
        
        Set-AzureRmCurrentStorageAccount -ResourceGroupName $storageAccount.ResourceGroupName -Name $storageAccount.StorageAccountName | Out-Null

        $strgName = $storageAccount.StorageAccountName

        
        if(Test-Path $folder"\AzureRM\Files\"$strgName){}
        else{New-Item -ItemType Directory $folder"\AzureRM\Files\"$strgName | Out-Null}

        
        $containers = Get-AzureStorageContainer | select Name
        
        foreach ($container in $containers){
            $containerName = $container.Name
            Write-Verbose "`tListing files for the $containerName container"
            $pathName = "\AzureRM\Files\"+$strgName+"\Blob_Files_"+$container.Name
            Get-AzureStorageBlob -Container $container.Name | Export-Csv -NoTypeInformation -LiteralPath $folder$pathName".CSV"
            
            
            $publicStatus = Get-AzureStorageContainerAcl $container.Name | select PublicAccess
            if (($publicStatus.PublicAccess -eq "Blob") -or ($publicStatus.PublicAccess -eq "Container")){
                Write-Verbose "`t`tPublic File Found" 
                
                $blobName = Get-AzureStorageBlob -Container $container.Name | select Name
                $blobUrl = "https://$StorageAccountName.blob.core.windows.net/$containerName/"+$blobName.Name
                $blobUrl >> $folder"\AzureRM\Files\"$strgName"\PublicFileURLs.txt"
                }
        }

        
        Try{
            $AZFileShares = Get-AzureStorageShare -ErrorAction Stop | select Name
            Write-Verbose "Listing out File Service files for the $StorageAccountName storage account..."
            foreach ($share in $AZFileShares) {
                $shareName = $share.Name
                Write-Verbose "`tListing files for the $shareName share"
                Get-AzureStorageFile -ShareName $shareName | select Name | Export-Csv -NoTypeInformation -LiteralPath $folder"\AzureRM\Files\"$strgName"\File_Service_Files-"$shareName".CSV" -Append
                }
            }
        Catch{
            Write-Verbose "No available File Service files for the $StorageAccountName storage account..."
            }
        finally{
            $ErrorActionPreference = "Continue"
            }

        
        Try{            
            $tableList = Get-AzureStorageTable -ErrorAction Stop 
            if ($tableList.Length -gt 0){
                $tableList | Export-Csv -NoTypeInformation -LiteralPath $folder"\AzureRM\Files\"$strgName"\Data_Tables.CSV"
                Write-Verbose "Listing out Data Tables for the $StorageAccountName storage account..."
                }
            else {Write-Verbose "No available Data Tables for the $StorageAccountName storage account..."}
            }
        Catch{
            Write-Verbose "No available Data Tables for the $StorageAccountName storage account..."
            }
        finally{
            $ErrorActionPreference = "Continue"
            }

    }

    
    Write-Verbose "Getting Domain Service Principals..."
    $principals = Get-AzureRmADServicePrincipal
    $principals | Export-Csv -NoTypeInformation -LiteralPath $folder"\AzureRM\Domain_SPNs.CSV"
    $principalCount = $principals.Count
    Write-Verbose "$principalCount service principals were enumerated."
    

    Write-Verbose "All done with AzureRM tasks.`n"
}

Function Dump-AzureDomainInfo-All
{
    
        [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$false,
        HelpMessage="Folder to output to.")]
        [string]$folder
    )
    if($folder){
        Dump-AzureDomainInfo-MSOL -folder $folder
        Dump-AzureDomainInfo-AzureRM -folder $folder
    }
    else{
        Dump-AzureDomainInfo-MSOL
        Dump-AzureDomainInfo-AzureRM
    }
}
