
function Get-CIisConfigurationSection
{
    
    [CmdletBinding(DefaultParameterSetName='Global')]
    [OutputType([Microsoft.Web.Administration.ConfigurationSection])]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ForSite')]
        [string]
        
        $SiteName,
        
        [Parameter(ParameterSetName='ForSite')]
        [Alias('Path')]
        [string]
        
        $VirtualPath = '',
        
        [Parameter(Mandatory=$true,ParameterSetName='ForSite')]
        [Parameter(Mandatory=$true,ParameterSetName='Global')]
        [string]
        
        $SectionPath,
        
        [Type]
        
        $Type = [Microsoft.Web.Administration.ConfigurationSection]
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $mgr = New-Object 'Microsoft.Web.Administration.ServerManager'
    $config = $mgr.GetApplicationHostConfiguration()
    
    $section = $null
    $qualifier = ''
    try
    {
        if( $PSCmdlet.ParameterSetName -eq 'ForSite' )
        {
            $qualifier = Join-CIisVirtualPath $SiteName $VirtualPath
            $section = $config.GetSection( $SectionPath, $Type, $qualifier )
        }
        else
        {
            $section = $config.GetSection( $SectionPath, $Type )
        }
    }
    catch
    {
    }
        
    if( $section )
    {
        $section | Add-IisServerManagerMember -ServerManager $mgr -PassThru
    }
    else
    {
        Write-Error ('IIS:{0}: configuration section {1} not found.' -f $qualifier,$SectionPath)
        return
    }
}

