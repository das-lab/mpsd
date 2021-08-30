
function Split-CIni
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ByPath')]
        [string]
        
        $Path,
        
        [Switch]
        
        $AsHashtable,

        [Switch]
        
        $CaseSensitive
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-Path $Path -PathType Leaf) )
    {
        Write-Error ("INI file '{0}' not found." -f $Path)
        return
    }
    
    $sectionName = ''
    $lineNum = 0
    $lastSetting = $null
    $settings = @{ }
    if( $CaseSensitive )
    {
        $settings = New-Object 'Collections.Hashtable'
    }
    
    Get-Content -Path $Path | ForEach-Object {
        
        $lineNum += 1
        
        if( -not $_ -or $_ -match '^[;
        {
            if( -not $AsHashtable -and $lastSetting )
            {
                $lastSetting
            }
            $lastSetting = $null
            return
        }
        
        if( $_ -match '^\[([^\]]+)\]' )
        {
            if( -not $AsHashtable -and $lastSetting )
            {
                $lastSetting
            }
            $lastSetting = $null
            $sectionName = $matches[1]
            Write-Debug "Parsed section [$sectionName]"
            return
        }
        
        if( $_ -match '^\s+(.*)$' -and $lastSetting )
        {
            $lastSetting.Value += "`n" + $matches[1]
            return
        }
        
        if( $_ -match '^([^=]*) ?= ?(.*)$' )
        {
            if( -not $AsHashtable -and $lastSetting )
            {
                $lastSetting
            }
            
            $name = $matches[1]
            $value = $matches[2]
            
            $name = $name.Trim()
            $value = $value.TrimStart()
            
            $setting = New-Object Carbon.Ini.IniNode $sectionName,$name,$value,$lineNum
            $settings[$setting.FullName] = $setting
            $lastSetting = $setting
            Write-Debug "Parsed setting '$($setting.FullName)'"
        }
    }
    
    if( $AsHashtable )
    {
        return $settings
    }
    else
    {
        if( $lastSetting )
        {
            $lastSetting
        }
    }
}

