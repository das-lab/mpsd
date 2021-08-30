
function Install-CIisWebsite
{
    
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.Site])]
    param(
        [Parameter(Position=0,Mandatory=$true)]
        [string]
        
        $Name,
        
        [Parameter(Position=1,Mandatory=$true)]
        [Alias('Path')]
        [string]
        
        $PhysicalPath,
        
        [Parameter(Position=2)]
        [Alias('Bindings')]
        [string[]]
        
        
        
        
        
        $Binding = @('http/*:80:'),
        
        [string]
        
        $AppPoolName,

        [int]
        
        
        
        $SiteID,

        [Switch]
        
        
        
        $PassThru,

        [Switch]
        
        
        
        $Force
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $bindingRegex = '^(?<Protocol>https?):?//?(?<IPAddress>\*|[\d\.]+):(?<Port>\d+):?(?<HostName>.*)$'

    filter ConvertTo-Binding
    {
        param(
            [Parameter(ValueFromPipeline=$true,Mandatory=$true)]
            [string]
            $InputObject
        )

        Set-StrictMode -Version 'Latest'

        $InputObject -match $bindingRegex | Out-Null
        [pscustomobject]@{ 
                            'Protocol' = $Matches['Protocol'];
                            'IPAddress' = $Matches['IPAddress'];
                            'Port' = $Matches['Port'];
                            'HostName' = $Matches['HostName'];
                          } |
                            Add-Member -MemberType ScriptProperty -Name 'BindingInformation' -Value { '{0}:{1}:{2}' -f $this.IPAddress,$this.Port,$this.HostName } -PassThru
    }

    $PhysicalPath = Resolve-CFullPath -Path $PhysicalPath
    if( -not (Test-Path $PhysicalPath -PathType Container) )
    {
        New-Item $PhysicalPath -ItemType Directory | Out-String | Write-Verbose
    }
    
    $invalidBindings = $Binding | 
                           Where-Object { $_ -notmatch $bindingRegex } 
    if( $invalidBindings )
    {
        $invalidBindings = $invalidBindings -join "`n`t"
        $errorMsg = "The following bindings are invalid. The correct format is protocol/IPAddress:Port:Hostname. Protocol and IP address must be separted by a single slash, not ://. IP address can be * for all IP addresses. Hostname is optional. If hostname is not provided, the binding must end with a colon.`n`t{0}" -f $invalidBindings
        Write-Error $errorMsg
        return
    }

    if( $Force )
    {
        Uninstall-CIisWebsite -Name $Name
    }

    [Microsoft.Web.Administration.Site]$site = $null
    $modified = $false
    if( -not (Test-CIisWebsite -Name $Name) )
    {
        Write-Verbose -Message ('Creating website ''{0}'' ({1}).' -f $Name,$PhysicalPath)
        $firstBinding = $Binding | Select-Object -First 1 | ConvertTo-Binding
        $mgr = New-Object 'Microsoft.Web.Administration.ServerManager'
        $site = $mgr.Sites.Add( $Name, $firstBinding.Protocol, $firstBinding.BindingInformation, $PhysicalPath )
        $mgr.CommitChanges()
    }

    $site = Get-CIisWebsite -Name $Name

    $expectedBindings = New-Object 'Collections.Generic.Hashset[string]'
    $Binding | ConvertTo-Binding | ForEach-Object { [void]$expectedBindings.Add( ('{0}/{1}' -f $_.Protocol,$_.BindingInformation) ) }

    $bindingsToRemove = $site.Bindings | Where-Object { -not $expectedBindings.Contains(  ('{0}/{1}' -f $_.Protocol,$_.BindingInformation ) ) }
    foreach( $bindingToRemove in $bindingsToRemove )
    {
        Write-IisVerbose $Name 'Binding' ('{0}/{1}' -f $bindingToRemove.Protocol,$bindingToRemove.BindingInformation)
        $site.Bindings.Remove( $bindingToRemove )
        $modified = $true
    }

    $existingBindings = New-Object 'Collections.Generic.Hashset[string]'
    $site.Bindings | ForEach-Object { [void]$existingBindings.Add( ('{0}/{1}' -f $_.Protocol,$_.BindingInformation) ) }
    $bindingsToAdd = $Binding | ConvertTo-Binding | Where-Object { -not $existingBindings.Contains(  ('{0}/{1}' -f $_.Protocol,$_.BindingInformation ) ) }
    foreach( $bindingToAdd in $bindingsToAdd )
    {
        Write-IisVerbose $Name 'Binding' '' ('{0}/{1}' -f $bindingToAdd.Protocol,$bindingToAdd.BindingInformation)
        $site.Bindings.Add( $bindingToAdd.BindingInformation, $bindingToAdd.Protocol ) | Out-Null
        $modified = $true
    }
    
    [Microsoft.Web.Administration.Application]$rootApp = $null
    if( $site.Applications.Count -eq 0 )
    {
        $rootApp = $site.Applications.Add("/", $PhysicalPath)
        $modifed = $true
    }
    else
    {
        $rootApp = $site.Applications | Where-Object { $_.Path -eq '/' }
    }

    if( $site.PhysicalPath -ne $PhysicalPath )
    {
        Write-IisVerbose $Name 'PhysicalPath' $site.PhysicalPath $PhysicalPath 
        [Microsoft.Web.Administration.VirtualDirectory]$vdir = $rootApp.VirtualDirectories | Where-Object { $_.Path -eq '/' }
        $vdir.PhysicalPath = $PhysicalPath
        $modified = $true
    }
    
    if( $AppPoolName )
    {
        if( $rootApp.ApplicationPoolName -ne $AppPoolName )
        {
            Write-IisVerbose $Name 'AppPool' $rootApp.ApplicationPoolName $AppPoolName 
            $rootApp.ApplicationPoolName = $AppPoolName
            $modified = $true
        }
    }

    if( $modified )
    {
        $site.CommitChanges()
    }
    
    if( $SiteID )
    {
        Set-CIisWebsiteID -SiteName $Name -ID $SiteID
    }
    
    
    $security = Get-CIisSecurityAuthentication -SiteName $Name -VirtualPath '/' -Anonymous
    Write-IisVerbose $Name 'Anonymous Authentication UserName' $security['username'] ''
    $security['username'] = ''
    $security.CommitChanges()

    
    $tries = 0
    $website = $null
    do
    {
        $website = Get-CIisWebsite -SiteName $Name
        $tries += 1
        if($website.State -ne 'Unknown')
        {
            break
        }
        else
        {
            Start-Sleep -Milliseconds 100
        }
    }
    while( $tries -lt 100 )

    if( $PassThru )
    {
        return $website
    }
}

