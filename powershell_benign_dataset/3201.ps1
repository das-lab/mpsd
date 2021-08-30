function Add-ObjectDetail
{
    
    [CmdletBinding()] 
    param(
           [Parameter( Mandatory = $true,
                       Position=0,
                       ValueFromPipeline=$true )]
           [ValidateNotNullOrEmpty()]
           [psobject[]]$InputObject,

           [Parameter( Mandatory = $false,
                       Position=1)]
           [string]$TypeName,

           [Parameter( Mandatory = $false,
                       Position=2)]    
           [System.Collections.Hashtable]$PropertyToAdd,

           [Parameter( Mandatory = $false,
                       Position=3)]
           [ValidateNotNullOrEmpty()]
           [Alias('dp')]
           [System.String[]]$DefaultProperties,

           [boolean]$Passthru = $True
    )
    
    Begin
    {
        if($PSBoundParameters.ContainsKey('DefaultProperties'))
        {
            
            $ddps = New-Object System.Management.Automation.PSPropertySet DefaultDisplayPropertySet,$DefaultProperties
            $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]$ddps
        }
    }
    Process
    {
        foreach($Object in $InputObject)
        {
            switch ($PSBoundParameters.Keys)
            {
                'PropertyToAdd'
                {
                    foreach($Key in $PropertyToAdd.Keys)
                    {
                        
                        $Object.PSObject.Properties.Add( ( New-Object System.Management.Automation.PSNoteProperty($Key, $PropertyToAdd[$Key]) ) )  
                    }
                }
                'TypeName'
                {
                    
                    [void]$Object.PSObject.TypeNames.Insert(0,$TypeName)
                }
                'DefaultProperties'
                {
                    
                    Add-Member -InputObject $Object -MemberType MemberSet -Name PSStandardMembers -Value $PSStandardMembers
                }
            }
            if($Passthru)
            {
                $Object
            }
        }
    }
}