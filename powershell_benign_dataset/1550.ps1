function Get-Type {
    
    [cmdletbinding()]
    param(
        [string]$Module = '*',
        [string]$Assembly = '*',
        [string]$FullName = '*',
        [string]$Namespace = '*',
        [string]$BaseType = '*',
        [switch]$IsEnum
    )
    
    
        $WhereArray = @('$_.IsPublic')
        if($Module -ne "*"){$WhereArray += '$_.Module -like $Module'}
        if($Assembly -ne "*"){$WhereArray += '$_.Assembly -like $Assembly'}
        if($FullName -ne "*"){$WhereArray += '$_.FullName -like $FullName'}
        if($Namespace -ne "*"){$WhereArray += '$_.Namespace -like $Namespace'}
        if($BaseType -ne "*"){$WhereArray += '$_.BaseType -like $BaseType'}
        
        if($PSBoundParameters.ContainsKey("IsEnum")) { $WhereArray += '$_.IsENum -like $IsENum' }
    
    
        $WhereString = $WhereArray -Join " -and "
        $WhereBlock = [scriptblock]::Create( $WhereString )
        Write-Verbose "Where ScriptBlock: { $WhereString }"

    
        [AppDomain]::CurrentDomain.GetAssemblies() | ForEach-Object {
            Write-Verbose "Getting types from $($_.FullName)"
            Try
            {
                $_.GetExportedTypes()
            }
            Catch
            {
                Write-Verbose "$($_.FullName) error getting Exported Types: $_"
                $null
            }

        } | Where-Object -FilterScript $WhereBlock
}

