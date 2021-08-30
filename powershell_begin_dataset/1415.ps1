
function Convert-CXmlFile
{
    
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $Path,

        [Parameter(Mandatory=$true,ParameterSetName='ByXdtFile')]
        [string]
        
        $XdtPath,

        [Parameter(Mandatory=$true,ParameterSetName='ByXdtXml')]
        [xml]
        
        $XdtXml,
        
        [Parameter(Mandatory=$true)]
		[string]
        
        $Destination,
        
        [string[]]
        
        $TransformAssemblyPath = @(),

        [Switch]
        
        $Force
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
	if( -not (Test-Path -Path $Path -PathType Leaf))
	{
		Write-Error ("Path '{0}' not found." -f $Path)
        return
	}
	
    if( $PSCmdlet.ParameterSetName -eq 'ByXdtXml' )
    {
        $xdtPathForInfoMsg = ''
        $xdtPathForShouldProcess = 'raw XDT XML'
        $XdtPath = 'Carbon_Convert-XmlFile_{0}' -f ([IO.Path]::GetRandomFileName())
        $XdtPath = Join-Path $env:TEMP $XdtPath
        $xdtXml.Save( $XdtPath )
    }
    else
    {
	    if( -not (Test-Path -Path $XdtPath -PathType Leaf) )
	    {
		    Write-Error ("XdtPath '{0}' not found." -f $XdtPath)
            return
	    }
        $XdtPath = Resolve-CFullPath -Path $XdtPath
        $xdtPathForShouldProcess = $XdtPath
        $xdtPathForInfoMsg = 'with ''{0}'' ' -f $XdtPath
    }
    
    $Path = Resolve-CFullPath -Path $Path
    $Destination = Resolve-CFullPath -Path $Destination
    $TransformAssemblyPath = $TransformAssemblyPath | ForEach-Object { Resolve-CFullPath -path $_ }
    if( $TransformAssemblyPath )
    {
        $badPaths = $TransformAssemblyPath | Where-Object { -not (Test-Path -Path $_ -PathType Leaf) }
        if( $badPaths )
        {
            $errorMsg = "TransformAssemblyPath not found:`n * {0}" -f ($badPaths -join "`n * ")
            Write-Error -Message $errorMsg -Category ObjectNotFound
            return
        }
    }
    
    if( $Path -eq $Destination )
    {
        $errorMsg = 'Can''t transform Path {0} onto Destination {1}: Path is the same as Destination. XDT is designed to transform an XML file from a known state to a new XML file. Please supply a new, unique path for the Destination XML file.' -f `
                        $Path,$Destination
        Write-Error -Message $errorMsg -Category InvalidOperation -RecommendedAction 'Set Destination parameter to a unique path.'
        return
    }

    if( -not $Force -and (Test-Path -Path $Destination -PathType Leaf) )
    {
        $errorMsg = 'Can''t transform ''{0}'': Destination ''{1}'' exists. Use the -Force switch to overwrite.' -f $Path,$Destination
        Write-Error $errorMsg -Category InvalidOperation -RecommendedAction 'Use the -Force switch to overwrite.'
        return
    }
    
    
    $scriptBlock = {
        param(
            [Parameter(Position=0)]
            [string]
            $CarbonBinDir,

            [Parameter(Position=1)]
            [string]
            $Path,

            [Parameter(Position=2)]
            [string]
            $XdtPath,

            [Parameter(Position=3)]
            [string]
            $Destination,
            
            [Parameter(Position=4)]
            [string[]]
            $TransformAssemblyPath
        )
        
        Add-Type -Path (Join-Path -Path $CarbonBinDir -ChildPath "Microsoft.Web.XmlTransform.dll")
        Add-Type -Path (Join-Path -Path $CarbonBinDir -ChildPath "Carbon.Xdt.dll")
        if( $TransformAssemblyPath )
        {
            $TransformAssemblyPath | ForEach-Object { Add-Type -Path $_ }
        }
                
        function Convert-CXmlFile
        {
            [CmdletBinding()]
            param(
                [string]
                $Path,

                [string]
                $XdtPath,

                [string]
                $Destination
            )

            [Microsoft.Web.XmlTransform.XmlTransformation]$xmlTransform = $null
            [Microsoft.Web.XmlTransform.XmlTransformableDocument]$document = $null
            try
            {
                $document = New-Object Microsoft.Web.XmlTransform.XmlTransformableDocument
                $document.PreserveWhitespace = $true
                $document.Load($Path)

                $logger = New-Object Carbon.Xdt.PSHostUserInterfaceTransformationLogger $PSCmdlet.CommandRuntime
                $xmlTransform = New-Object Microsoft.Web.XmlTransform.XmlTransformation $XdtPath,$logger

                $success = $xmlTransform.Apply($document)

                if($success)
                {
                    $document.Save($Destination)
                }
            }
            finally
            {
                if( $xmlTransform )
                {	
                    $xmlTransform.Dispose()
                }
                if( $document )
                {
                    $document.Dispose()
                }
            }
        }
        
        $PsBoundParameters.Remove( 'CarbonBinDir' )
        $PSBoundParameters.Remove( 'TransformAssemblyPath' )
        Convert-CXmlFile @PSBoundParameters
    }

    try
    {
        if( $PSCmdlet.ShouldProcess( $Path, ('transform with {0} -> {1}' -f $xdtPathForShouldProcess,$Destination) ) )
        {
            $argumentList = $carbonAssemblyDir,$Path,$XdtPath,$Destination,$TransformAssemblyPath
            if( $PSVersionTable.CLRVersion.Major -ge 4 )
            {
                Invoke-Command -ScriptBlock $scriptBlock -ArgumentList $argumentList
            }
            else
            {
                Invoke-CPowerShell -Command $scriptBlock -Args $argumentList -Runtime 'v4.0'
            }
        }
    }
    finally
    {
        if( $PSCmdlet.ParameterSetName -eq 'ByXdtXml' )
        {
            Remove-Item -Path $XdtPath
        }
    }
}


