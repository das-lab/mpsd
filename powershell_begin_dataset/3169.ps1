

function Invoke-AzureRmVmScript {

    [cmdletbinding()]
    param(
        
        [Parameter(Mandatory = $True,
                   Position = 0,
                   ValueFromPipelineByPropertyName = $True)]
        [string[]]$ResourceGroupName,
        
        [Parameter(Mandatory = $True,
                   Position = 1,
                   ValueFromPipelineByPropertyName = $True)]
        [string[]]$VMName,
        
        [Parameter(Mandatory = $True,
                   Position = 2)]
        [scriptblock]$ScriptBlock, 
        
        [Parameter(Mandatory = $True,
                   Position = 3)]
        [string]$StorageAccountName,

        [string]$StorageAccountKey, 

        $StorageContext,
        
        [string]$StorageContainer = 'scripts',
        
        [string]$Filename, 
        
        [string]$ExtensionName, 

        [switch]$ForceExtension,
        [switch]$ForceBlob,
        [switch]$Force
    )
    begin
    {
        if($Force)
        {
            $ForceExtension = $True
            $ForceBlob = $True
        }
    }
    process
    {
        Foreach($ResourceGroup in $ResourceGroupName)
        {
            Foreach($VM in $VMName)
            {
                if(-not $Filename)
                {
                    $GUID = [GUID]::NewGuid().Guid -replace "-", "_"
                    $FileName = "$GUID.ps1"
                }
                if(-not $ExtensionName)
                {
                    $ExtensionName = $Filename -replace '.ps1', ''
                }

                $CommonParams = @{
                    ResourceGroupName = $ResourceGroup
                    VMName = $VM
                }

                Write-Verbose "Working with ResourceGroup $ResourceGroup, VM $VM"
                
                Try
                {
                    $AzureRmVM = Get-AzureRmVM @CommonParams -ErrorAction Stop
                    $AzureRmVMExtended = Get-AzureRmVM @CommonParams -Status -ErrorAction Stop
                }
                Catch
                {
                    Write-Error $_
                    Write-Error "Failed to retrieve existing extension data for $VM"
                    continue
                }

                
                Write-Verbose "Checking for existing extensions on VM '$VM' in resource group '$ResourceGroup'"
                $Extensions = $null
                $Extensions = @( $AzureRmVMExtended.Extensions | Where {$_.Type -like 'Microsoft.Compute.CustomScriptExtension'} )
                if($Extensions.count -gt 0)
                {
                    Write-Verbose "Found extensions on $VM`:`n$($Extensions | Format-List | Out-String)"
                    if(-not $ForceExtension)
                    {
                        Write-Warning "Found CustomScriptExtension '$($Extensions.Name)' on VM '$VM' in Resource Group '$ResourceGroup'.`n Use -ForceExtension or -Force to remove this"
                        continue
                    }
                    Try
                    {
                        
                        $Output = Remove-AzureRmVMCustomScriptExtension @CommonParams -Name $Extensions.Name -Force -ErrorAction Stop
                        if($Output.StatusCode -notlike 'OK')
                        {
                            Throw "Remove-AzureRmVMCustomScriptExtension output seems off:`n$($Output | Format-List | Out-String)"
                        }
                    }
                    Catch
                    {
                        Write-Error $_
                        Write-Error "Failed to remove existing extension $($Extensions.Name) for VM '$VM' in ResourceGroup '$ResourceGroup'"
                        continue
                    }
                }

                
                Write-Verbose "Uploading script to storage account $StorageAccountName"
                if(-not $StorageContainer)
                {
                    $StorageContainer = 'scripts'
                }
                if(-not $Filename)
                {
                    $Filename = 'CustomScriptExtension.ps1'
                }
                if(-not $StorageContext)
                {
                    if(-not $StorageAccountKey)
                    {
                        Try
                        {
                            $StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroup -Name $storageAccountName -ErrorAction Stop)[0].value
                        }
                        Catch
                        {
                            Write-Error $_
                            Write-Error "Failed to obtain Storage Account Key for storage account '$StorageAccountName' in Resource Group '$ResourceGroup' for VM '$VM'"
                            continue
                        }
                    }
                    Try
                    {
                        $StorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
                    }
                    Catch
                    {
                        Write-Error $_
                        Write-Error "Failed to generate storage context for storage account '$StorageAccountName' in Resource Group '$ResourceGroup' for VM '$VM'"
                        continue
                    }
                }
        
                Try
                {
                    $Script = $ScriptBlock.ToString()
                    $LocalFile = [System.IO.Path]::GetTempFileName()
                    Start-Sleep -Milliseconds 500 
                    Set-Content $LocalFile -Value $Script -ErrorAction Stop
            
                    $params = @{
                        Container = $StorageContainer
                        Context = $StorageContext
                    }

                    $Existing = $Null
                    $Existing = @( Get-AzureStorageBlob @params -ErrorAction Stop )

                    if($Existing.Name -contains $Filename -and -not $ForceBlob)
                    {
                        Write-Warning "Found blob '$FileName' in container '$StorageContainer'.`n Use -ForceBlob or -Force to overwrite this"
                        continue
                    }
                    $Output = Set-AzureStorageBlobContent @params -File $Localfile -Blob $Filename -ErrorAction Stop -Force
                    if($Output.Name -notlike $Filename)
                    {
                        Throw "Set-AzureStorageBlobContent output seems off:`n$($Output | Format-List | Out-String)"
                    }
                }
                Catch
                {
                    Write-Error $_
                    Write-Error "Failed to generate or upload local script for VM '$VM' in Resource Group '$ResourceGroup'"
                    continue
                }

                
                Write-Verbose "Adding CustomScriptExtension to VM '$VM' in resource group '$ResourceGroup'"
                Try
                {
                    $Output = Set-AzureRmVMCustomScriptExtension -ResourceGroupName $ResourceGroup `
                                                                 -VMName $VM `
                                                                 -Location $AzureRmVM.Location `
                                                                 -FileName $Filename `
                                                                 -ContainerName $StorageContainer `
                                                                 -StorageAccountName $StorageAccountName `
                                                                 -StorageAccountKey $StorageAccountKey `
                                                                 -Name $ExtensionName `
                                                                 -TypeHandlerVersion 1.1 `
                                                                 -ErrorAction Stop

                    if($Output.StatusCode -notlike 'OK')
                    {
                        Throw "Set-AzureRmVMCustomScriptExtension output seems off:`n$($Output | Format-List | Out-String)"
                    }
                }
                Catch
                {
                    Write-Error $_
                    Write-Error "Failed to set CustomScriptExtension for VM '$VM' in resource group $ResourceGroup"
                    continue
                }

                
                Try
                {
                    $AzureRmVmOutput = $null
                    $AzureRmVmOutput = Get-AzureRmVM @CommonParams -Status -ErrorAction Stop
                    $SubStatuses = ($AzureRmVmOutput.Extensions | Where {$_.name -like $ExtensionName} ).substatuses
                }
                Catch
                {
                    Write-Error $_
                    Write-Error "Failed to retrieve script output data for $VM"
                    continue
                }

                $Output = [ordered]@{
                    ResourceGroupName = $ResourceGroup
                    VMName = $VM
                    Substatuses = $SubStatuses
                }

                foreach($Substatus in $SubStatuses)
                {
                    $ThisCode = $Substatus.Code -replace 'ComponentStatus/', '' -replace '/', '_'
                    $Output.add($ThisCode, $Substatus.Message)
                }

                [pscustomobject]$Output
            }
        }
    }
}


    
    
    
    
    
    