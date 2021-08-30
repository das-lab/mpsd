
function Set-CIniEntry
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        
        $Name,
        
        [string]
        
        $Value,

        [string]
        
        $Section,

        [Switch]
        
        $CaseSensitive
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    if( $Name -like '*=*' )
    {
        Write-Error "INI entry name '$Name' invalid: can not contain equal sign '='."
        return
    }
    
    
    $settings = @{ }
    $lines = New-Object 'Collections.ArrayList'
    
    if( Test-Path $Path -PathType Leaf )
    {
        $settings = Split-CIni -Path $Path -AsHashtable -CaseSensitive:$CaseSensitive
        Get-Content -Path $Path | ForEach-Object { [void] $lines.Add( $_ ) }
    }
    
    $settings.Values | 
        Add-Member -MemberType NoteProperty -Name 'Updated' -Value $false -PassThru |
        Add-Member -MemberType NoteProperty -Name 'IsNew' -Value $false 
        
    $key = "$Name"
    if( $Section )
    {
        $key = "$Section.$Name"
    }
    
    if( $settings.ContainsKey( $key ) )
    {
        $setting = $settings[$key]
        if( $setting.Value -cne $Value )
        {
            Write-Verbose -Message "Updating INI entry '$key' in '$Path'."
            $lines[$setting.LineNumber - 1] = "$Name = $Value" 
        }
    }
    else
    {
        $lastItemInSection = $settings.Values | `
                                Where-Object { $_.Section -eq $Section } | `
                                Sort-Object -Property LineNumber | `
                                Select-Object -Last 1
        
        $newLine = "$Name = $Value"
        Write-Verbose -Message "Creating INI entry '$key' in '$Path'."
        if( $lastItemInSection )
        {
            $idx = $lastItemInSection.LineNumber
            $lines.Insert( $idx, $newLine )
            if( $lines.Count -gt ($idx + 1) -and $lines[$idx + 1])
            {
                $lines.Insert( $idx + 1, '' )
            }
        }
        else
        {
            if( $Section )
            {
                if( $lines.Count -gt 1 -and $lines[$lines.Count - 1] )
                {
                    [void] $lines.Add( '' )
                }

                if(-not $lines.Contains("[$Section]"))
                {
                    [void] $lines.Add( "[$Section]" )
                    [void] $lines.Add( $newLine )
                }
                else
                {
                    for ($i=0; $i -lt $lines.Count; $i++)
                    {
                        if ($lines[$i] -eq "[$Section]")
                        {
                            $lines.Insert($i+1, $newLine)
                            break
                        }
                    }
                }
            }
            else
            {
                $lines.Insert( 0, $newLine )
                if( $lines.Count -gt 1 -and $lines[1] )
                {
                    $lines.Insert( 1, '' )
                }
            }
        }
    }
    
    $lines | Set-Content -Path $Path
}

