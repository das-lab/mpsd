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

       $VideoController = Get-WmiObject -Query 'SELECT VideoModeDescription FROM Win32_VideoController'

       if ($VideoController.VideoModeDescription -and $VideoController.VideoModeDescription -match '(?<ScreenWidth>^\d+) x (?<ScreenHeight>\d+) x .*$') {
           $Width = [Int] $Matches['ScreenWidth']
           $Height = [Int] $Matches['ScreenHeight']
       } else {
           $ScreenBounds = [Windows.Forms.SystemInformation]::VirtualScreen

           $Width = $ScreenBounds.Width
           $Height = $ScreenBounds.Height
       }

       $Size = New-Object System.Drawing.Size($Width, $Height)
       $Point = New-Object System.Drawing.Point(0, 0)

       $ScreenshotObject = New-Object Drawing.Bitmap $Width, $Height
       $DrawingGraphics = [Drawing.Graphics]::FromImage($ScreenshotObject)
       $DrawingGraphics.CopyFromScreen($Point, [Drawing.Point]::Empty, $Size)
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
               
            Write-Verbose "Saved screenshot to $FilePath. Sleeping for $Interval seconds"

            Start-Sleep -Seconds $Interval
        }

        
        While ((Get-Date -Format HH:mm) -lt $EndTime)
    }

    Catch {Write-Error $Error[0].ToString() + $Error[0].InvocationInfo.PositionMessage}
}
