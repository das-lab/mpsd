
function Convert-HelpToHtml 
{
    
	param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]
        
        $Name,

        [string]
        
        $DisplayName,

        [string[]]
        
        
        
        
        
        $Syntax,

        [string]
        
        $ModuleName,

        [string[]]
        
        $Script
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
    }

    process
    {

        foreach( $commandName in $Name )
        {
            $html = New-Object 'Text.StringBuilder'

            $fullCommandName = $commandName
            if( (Get-Help -Name $commandName | Measure-Object).Count -gt 1 )
            {
                $fullCommandName = '{0}\{1}' -f $ModuleName,$commandName
            }
            Write-Verbose -Message $fullCommandName
            $help = Get-Help -Name $fullCommandName -Full

            if( -not $DisplayName )
            {
                $DisplayName = $commandName
                if( [IO.Path]::IsPathRooted($DisplayName) )
                {
                    $DisplayName = Split-Path -Leaf -Path $DisplayName
                }
            }
        
            [void]$html.AppendFormat( '<h1>{0}</h1>{1}', $DisplayName, [Environment]::NewLine )

            $synopsis = $help.Synopsis | Convert-MarkdownToHtml
            if( $synopsis )
            {
                [void]$html.AppendFormat( '<div class="Synopsis">{0}{1}{0}</div>{0}', [Environment]::NewLine, $synopsis )
            }

            if( -not $Syntax )
            {
                $help.Syntax |
                    ForEach-Object { $_.syntaxItem } |
                    Where-Object { [IO.Path]::IsPathRooted($_.name) } |
                    ForEach-Object { $_.Name = Split-Path -Leaf -Path $_.name }

                $Syntax = $help.Syntax | Out-HtmlString | Format-ForHtml | ForEach-Object { $_ -split "`n" }
            }

            if( $Syntax )
            {
                [void]$html.AppendLine( @"

<h2>Syntax</h2>
<pre class="Syntax"><code>{0}</code></pre>
"@ -f ($Syntax -join "</code></pre>$([Environment]::NewLine)<pre class=""Syntax""><code>") )
            }

            $description = $null
            if( $help | Get-Member -Name 'Description' )
            {    
                $description = $help.Description | Out-HtmlString | Convert-MarkdownToHtml
            }
            if( $description )
            {
                [void]$html.AppendLine( @"

<h2>Description</h2>
<div class="Description">
$description
</div>
"@ )
            }
    
            [string[]]$relatedCommands = $help | Convert-RelatedLinkToHtml -ModuleName $ModuleName -Script $Script
    
            if( $relatedCommands )
            {
                $relatedCommands = $relatedCommands | ForEach-Object { "<li>{0}</li>" -f $_ }
                [void]$html.AppendLine( @"

<h2>Related Commands</h2>

<ul class="RelatedCommands">
{0}
</ul>
"@ -f ($relatedCommands -join ([Environment]::NewLine)) )
            }
    
            $commonParameterNames = @{
                                        'Verbose' = $true;
                                        'Debug' = $true;
                                        'WarningAction' = $true;
                                        'WarningVariable' = $true;
                                        'ErrorAction' = $true;
                                        'ErrorVariable' = $true;
                                        'OutVariable' = $true;
                                        'OutBuffer' = $true;
                                        'WhatIf' = $true;
                                        'Confirm' = $true;
                                    }
            $hasCommonParameters = $false
            $parameters = $help | 
                            Select-Object -ExpandProperty 'Parameters' |
                            Where-Object { $_ | Get-Member -Name 'parameter' } |
                            Select-Object -ExpandProperty 'parameter' |
                            Where-Object { $_ } | 
                            ForEach-Object {
                                if( $commonParameterNames.ContainsKey( $_.name ) )
                                {
                                    $hasCommonParameters = $true
                                }
            
                                $defaultValue = '&nbsp;'
                                if( $_ | Get-Member -Name 'DefaultValue' )
                                {
                                    $defaultValue = $_.DefaultValue
                                }
                                $typeLink = Get-TypeDocumentationLink -CommandName $commandName -TypeName $_.type.name
                                $paramDescription = $_ | 
                                                        Where-Object { $_ | Get-Member -name 'Description' } |
                                                        Select-Object -ExpandProperty 'Description' |
                                                        Out-HtmlString | 
                                                        Convert-MarkdownToHtml
                            @"
<tr valign='top'>
	<td>{0}</td>
	<td>{1}</td>
	<td class="ParamDescription">{2}</td>
	<td>{3}</td>
	<td>{4}</td>
    <td>{5}</td>
</tr>
"@ -f $_.Name,$typeLink,$paramDescription,$_.Required,$_.PipelineInput,$defaultValue
                    }
        
            if( $parameters )
            {
                $commonParameters = ''
                if( $hasCommonParameters )
                {
                    $commonParameters = @"
<tr valign="top">
    <td><a href="http://technet.microsoft.com/en-us/library/dd315352.aspx">CommonParameters</a></td>
    <td></td>
    <td>This cmdlet supports common parameters.  For more information type <br> <code>Get-Help about_CommonParameters</code>.</td>
    <td></td>
    <td></td>
    <td></td>
</tr>
"@
                }
                [void]$html.AppendLine( (@"

<h2> Parameters </h2>
<table id="Parameters">
<tr>
	<th>Name</th>
    <th>Type</th>
	<th>Description</th>
	<th>Required?</th>
	<th>Pipeline Input</th>
	<th>Default Value</th>
</tr>
{0}
{1}
</table>
"@ -f ($parameters -join [Environment]::NewLine),$commonParameters))
            }

            $inputTypes = @()
            if( ($help | Get-Member -Name 'inputTypes') -and ($help.inputTypes | Get-Member 'inputType') )
            {
                $inputTypes = $help.inputTypes.inputType |
                                    Where-Object {  ($_ | Get-Member -Name 'type') -and $_.type -and $_.type.name -match '^([^\s]+)\s*(.*)?$' } |
                                    ForEach-Object { 
                                        $typeLink = Get-TypeDocumentationLink -CommandName $commandName -TypeName $Matches[1].Trim('.')
                                        '{0}. {1}' -f $typeLink,$matches[2]
                                    } |
                                    Convert-MarkdownToHtml
            }

            if( $inputTypes )
            {
                [void]$html.AppendLine( @"

<h2>Input Types</h2>
<div class="InputTypes">
{0}
</div>
"@ -f ($inputTypes -join [Environment]::NewLine))
            }
    
            $returnValues =@()
            if( ($help | Get-Member -Name 'returnValues') -and ($help.returnValues | Get-Member -Name 'returnValue') )
            {
                $returnValues = $help.returnValues.returnValue |
                                    Where-Object {  ($_ | Get-Member -Name 'type') -and $_.type -and $_.type.name -match '^([^\s]+)\s*(.*)?$' } |
                                    ForEach-Object { 
                                        $typeLink = Get-TypeDocumentationLink -CommandName $commandName -TypeName $Matches[1].Trim('.')
                                        '{0}. {1}' -f $typeLink,$matches[2]
                                    } |
                                    Convert-MarkdownToHtml
            }

            if( $returnValues )
            {
                [void]$html.AppendLine( @"

<h2>Return Values</h2>
<div class="ReturnValues">
{0}
</div>
"@ -f ($returnValues -join [Environment]::NewLine))
            }
    
            $notes = ''
            if( $help | Get-Member -Name 'AlertSet' )
            {
                $notes = $help.AlertSet | Out-HtmlString | ForEach-Object { $_ -replace "\r?\n    ",[Environment]::NewLine } | Convert-MarkdownToHtml
            }

            if( $notes )
            {
                [void]$html.AppendLine( @"

<h2>Notes</h2>
<div class="Notes">
{0}
</div>
"@ -f $notes)
            }
    
            $examples = @()
            if( $help | Get-Member -Name 'Examples' )
            {
                $examples = $help.Examples |
                    Where-Object { $_ } |
                    Where-Object { $_ | Get-Member -Name 'example' } |
                    Select-Object -ExpandProperty 'example' |
                    ForEach-Object {
                        $title = $_.title.Trim(('-',' '))
                        $code = ''
                        if( $_.code )
                        {
                            $code = $_.code | Out-HtmlString
                            $code = '<pre><code>{0}</code></pre>' -f $code
                        }
                        $remarks = $_.remarks | Out-HtmlString | Convert-MarkdownToHtml
                        @"

<h2>{0}</h2>
{1}
{2}
"@ -f $title,$code,($remarks -join [Environment]::NewLine)
                }
            }

            if( $examples )
            {
                [void]$html.AppendLine( ($examples -join ([Environment]::NewLine * 2)) )
            }

            $html.ToString()
        }
    }

    end
    {
    }
}

