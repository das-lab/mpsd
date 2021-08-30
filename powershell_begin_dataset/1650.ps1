












function Set-Wallpaper {
    param (
        [string]$Path,
        [ValidateSet('Tile', 'Center', 'Stretch', 'Fill', 'Fit', 'Span')]
        [string]$Style = 'Fill'
    )

    begin {
        Add-Type @"
        using System;
        using System.Runtime.InteropServices;
        using Microsoft.Win32;
        namespace Wallpaper
        {
        public enum Style : int
        {
        Tile, Center, Stretch, Fill, Fit, Span, NoChange
        }
        public class Setter {
        public const int SetDesktopWallpaper = 20;
        public const int UpdateIniFile = 0x01;
        public const int SendWinIniChange = 0x02;
        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
        public static void SetWallpaper ( string path, Wallpaper.Style style ) {
        SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
        RegistryKey key = Registry.CurrentUser.OpenSubKey("Control Panel\\Desktop", true);
        switch( style )
        {
        case Style.Tile :
        key.SetValue(@"WallpaperStyle", "0") ;
        key.SetValue(@"TileWallpaper", "1") ;
        break;
        case Style.Center :
        key.SetValue(@"WallpaperStyle", "0") ;
        key.SetValue(@"TileWallpaper", "0") ;
        break;
        case Style.Stretch :
        key.SetValue(@"WallpaperStyle", "2") ;
        key.SetValue(@"TileWallpaper", "0") ;
        break;
        case Style.Fill :
        key.SetValue(@"WallpaperStyle", "10") ;
        key.SetValue(@"TileWallpaper", "0") ;
        break;
        case Style.Fit :
        key.SetValue(@"WallpaperStyle", "6") ;
        key.SetValue(@"TileWallpaper", "0") ;
        break;
        case Style.Span :
        key.SetValue(@"WallpaperStyle", "22") ;
        key.SetValue(@"TileWallpaper", "0") ;
        break;
        case Style.NoChange :
        break;
        }
        key.Close();
        }
        }
        }
"@

        $StyleNum = @{
            Tile = 0
            Center = 1
            Stretch = 2
            Fill = 3
            Fit = 4
            Span = 5
        }

        function Resolve-FullPath {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)]
                [string]
                
                $Path = $(Throw 'No path provided.')
            )
    
            if ( -not ([IO.Path]::IsPathRooted($Path)) ) {
                
                $Path = Join-Path (Get-Location) $Path
            }
            [IO.Path]::GetFullPath($Path)
        }
    }

    process {
        [Wallpaper.Setter]::SetWallpaper($Path, $StyleNum[$Style])
        [Wallpaper.Setter]::SetWallpaper($Path, $StyleNum[$Style])
    }
}
