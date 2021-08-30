
function Get-TypeDocumentationLink
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        
        $CommandName,

        [Parameter(Mandatory=$true)]
        [string]
        
        $TypeName
    )

    Set-StrictMode -Version 'Latest'

    $displayName = $TypeName
    if( $TypeName.EndsWith('[]') )
    {
        $TypeName = $TypeName -replace '\[\]',''
    }

    if( $TypeName -eq 'bool' )
    {
        $TypeName = 'boolean'
    }

    $type = $null
    if( $loadedTypes.ContainsKey( $TypeName ) )
    {
        $type = [Type]$loadedTypes[$TypeName]
    }
    else
    {
        try
        {
            $type = [Type]$TypeName
        }
        catch
        {
            Write-Warning ("[{0}] Type {1} not found." -f $CommandName,$TypeName)
            return $displayName
        }
    }

    $typeLink = $TypeName
    $typeFullName = $type.FullName

    $msdnUri = 'http://msdn.microsoft.com/en-us/library/{0}.aspx' -f $Type.FullName.ToLower()
    if( $Type.FullName -notlike 'System.*' )
    {
        $result = $null
        try
        {
            $result = Invoke-WebRequest -Uri $msdnUri -Method Head -ErrorAction Ignore
        }
        catch
        {
        }

        if( -not $result )
        {
            return $displayName
        }
    }

    return '<a href="{0}">{1}</a>' -f $msdnUri,$displayName
}