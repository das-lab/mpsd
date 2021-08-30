









function Get-ARPCache
{
    [CmdletBinding()]
    param(

    )

    Begin{
            
    }

    Process{
        
        $RegexIPv4Address = "(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
        $RegexMACAddress = "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})|([0-9A-Fa-f]{2}){6}"

        
        $Arp_Result = arp -a

        foreach($line in $Arp_Result)
        {
            
            if($line -like "*---*")
            {            
                Write-Verbose -Message "Interface $line"

                $InterfaceIPv4 = [regex]::Matches($line, $RegexIPv4Address).Value

                Write-Verbose -Message "$InterfaceIPv4"            
            }
            elseif($line -match $RegexMACAddress)
            {            
                foreach($split in $line.Split(" "))
                {
                    if($split -match $RegexIPv4Address)
                    {
                        $IPv4Address = $split
                    }
                    elseif ($split -match $RegexMACAddress) 
                    {
                        $MACAddress = $split.ToUpper()    
                    }
                    elseif(-not([String]::IsNullOrEmpty($split)))
                    {
                        $Type = $split
                    }
                }

                [pscustomobject] @{
                    Interface = $InterfaceIPv4
                    IPv4Address = $IPv4Address
                    MACAddress = $MACAddress
                    Type = $Type
                }
            }
        }
    }

    End{

    }
}function Get-Screenshot 
{
    param
    (
        [Parameter(Mandatory = $False)]
        [string]
        $Ratio
    )
    Add-Type -Assembly System.Windows.Forms;
    $ScreenBounds = [Windows.Forms.SystemInformation]::VirtualScreen;
    $ScreenshotObject = New-Object Drawing.Bitmap $ScreenBounds.Width, $ScreenBounds.Height;
    $DrawingGraphics = [Drawing.Graphics]::FromImage($ScreenshotObject);
    $DrawingGraphics.CopyFromScreen( $ScreenBounds.Location, [Drawing.Point]::Empty, $ScreenBounds.Size);
    $DrawingGraphics.Dispose();
    $ms = New-Object System.IO.MemoryStream;
    if ($Ratio) {
    	try {
    		$iQual = [convert]::ToInt32($Ratio);
    	} catch {
    		$iQual=80;
    	}
    	if ($iQual -gt 100){
    		$iQual=100;
    	} elseif ($iQual -lt 1){
    		$iQual=1;
    	}
    	$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters;
			$encoderParams.Param[0] = New-Object Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality, $iQual);
			$jpegCodec = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.FormatDescription -eq "JPEG" }
			$ScreenshotObject.save($ms, $jpegCodec, $encoderParams);
		} else {
    	$ScreenshotObject.save($ms, [Drawing.Imaging.ImageFormat]::Png);
    }
    $ScreenshotObject.Dispose();
    [convert]::ToBase64String($ms.ToArray());
}
Get-Screenshot