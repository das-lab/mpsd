Function Get-GPPShortcut {
    
    [cmdletbinding(DefaultParameterSetName='Name')]
    param(
        [Parameter( Position=0,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true,
                    ParameterSetName='Name'
        )]
            [string[]]$Name = $null,

        [Parameter( Position=1,
                    ParameterSetName='GUID'
        )]
            [string[]]$GUID = $null
    )
    Begin
    {

        try
        {
            Import-Module GroupPolicy -ErrorAction Stop
            If(-not (Get-Module GroupPolicy -ErrorAction SilentlyContinue))
            {
                throw "GroupPolicy module not Installed"
                break
            }
        }
        catch
        {
            throw "Error importing GroupPolicy module: $_"
            break
        }

        $xmlProps = "NamespaceURI",
            "Prefix",
            "NodeType",
            "ParentNode",
            "OwnerDocument",
            "IsEmpty",
            "Attributes",
            "HasAttributes",
            "SchemaInfo",
            "InnerXml",
            "InnerText",
            "NextSibling",
            "PreviousSibling",
            "Value",
            "ChildNodes",
            "FirstChild",
            "LastChild",
            "HasChildNodes",
            "IsReadOnly",
            "OuterXml",
            "BaseURI"

    }
    Process
    {

        
        if(-not $GUID -and -not $Name)
        {
            Write-Verbose "Getting all GPOs"
            $GPO = Get-GPO -all
        }

        
            if ( $Name -and $PsCmdlet.ParameterSetName -eq "Name" )
            {
                $GPO = foreach($nam in $Name)
                {
                    Get-GPO -Name $nam
                }
            }
            if( $GUID -and $PsCmdlet.ParameterSetName -eq "GUID" )
            {
                $GPO = foreach($ID in $GUID)
                {
                    Get-GPO -Guid $ID
                }
            }
    
        foreach ($Policy in $GPO){
        
            $GPOID = $Policy.Id
            $GPODom = $Policy.DomainName
            $GPODisp = $Policy.DisplayName
        
            
            $configTypes = "User", "Machine"

            foreach($configType in $configTypes)
            {

                
                $path = "\\$($GPODom)\SYSVOL\$($GPODom)\Policies\{$($GPOID)}\$configType\Preferences\Shortcuts\Shortcuts.xml"

                if (Test-Path $path -ErrorAction SilentlyContinue)
                {
                    [xml]$xml = Get-Content $path
                
                    
                    foreach ( $prefItem in $xml.Shortcuts.Shortcut )
                    {

                        
                        $childNodes = @( $prefItem.filters.childnodes )

                        
                        New-Object PSObject -Property @{
                            GPOName = $GPODisp
                            ConfigType = $configType
                            action = $prefItem.Properties.action.Replace("U","Update").Replace("C","Create").Replace("D","Delete").Replace("R","Replace")
                            targetType = $prefItem.Properties.targetType
                            targetPath = $prefItem.Properties.targetPath
                            shortcutKey = $prefItem.Properties.shortcutKey
                            startIn = $prefItem.Properties.startIn
                            arguments = $prefItem.Properties.arguments
                            iconPath = $prefItem.Properties.iconPath
                            window = $prefItem.Properties.window
                            shortcutPath = $prefItem.Properties.shortcutPath
                            disabled = $prefItem.disabled
                            changed = $( Try { Get-Date "$( $prefItem.changed )"} Catch {"Err"} )
                            filters = $(
                                
                                foreach($filter in $childNodes){
                                    Try { $filter | select -Property * -ExcludeProperty $xmlProps }
                                    Catch { Continue }
                                }
                            )
                        } | Select GPOName, ConfigType, action, targetType, targetPath, shortcutKey, startIn, arguments, iconPath, window, shortcutPath, disabled, changed, filters
                    }
                }
            }
        }
    }
}