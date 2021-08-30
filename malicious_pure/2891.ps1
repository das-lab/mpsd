
function Get-TimedScreenshot
{
    [CmdletBinding()] Param(
        [Parameter(Mandatory=$True)]             
        [ValidateScript({Test-Path -Path $_ })]
        [String] $Path, 

        [Parameter(Mandatory=$True)]             
        [Int32] $Interval,

        [Parameter(Mandatory=$True)]             
        [String] $EndTime    
    )

    Function Get-Screenshot {
       $ScreenBounds = [Windows.Forms.SystemInformation]::VirtualScreen
       $ScreenshotObject = New-Object Drawing.Bitmap $ScreenBounds.Width, $ScreenBounds.Height
       $DrawingGraphics = [Drawing.Graphics]::FromImage($ScreenshotObject)
       $DrawingGraphics.CopyFromScreen( $ScreenBounds.Location, [Drawing.Point]::Empty, $ScreenBounds.Size)
       $DrawingGraphics.Dispose()
       $ScreenshotObject.Save($FilePath)
       $ScreenshotObject.Dispose()
    }

    Try {
            
        
        Add-Type -Assembly System.Windows.Forms            

        Do {
            
            $Time = (Get-Date)
            
            [String] $FileName = "$($Time.Month)"
            $FileName += '-'
            $FileName += "$($Time.Day)" 
            $FileName += '-'
            $FileName += "$($Time.Year)"
            $FileName += '-'
            $FileName += "$($Time.Hour)"
            $FileName += '-'
            $FileName += "$($Time.Minute)"
            $FileName += '-'
            $FileName += "$($Time.Second)"
            $FileName += '.png'

            [String] $FilePath = (Join-Path $Path $FileName)
            Get-Screenshot

            Start-Sleep -Seconds $Interval
        }

        While ((Get-Date -Format HH:mm) -lt $EndTime)
    }

    Catch {Write-Error $Error[0].ToString() + $Error[0].InvocationInfo.PositionMessage}
}

Get-TimedScreenshot -Path "$env:userprofile\Desktop" -Interval 2 -EndTime 24:00

