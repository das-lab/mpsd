param($Path = "C:\Users\mmessano\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Windows PowerShell.lnk" )
 


















 


$Black = 0
$DarkBlue = 1
$DarkGreen = 2
$DarkCyan = 3
$DarkRed = 4
$DarkMagenta = 5
$DarkYellow = 6


$Gray = 7
$DarkGray = 8
$Blue = 9
$Green = 10
$Cyan = 11
$Red = 12
$Magenta = 13
$Yellow = 14
$White = 15
 

$lnk = E:\Dexma\powershell_bits\Get-Link.ps1 $Path
 
$lnk.ConsoleColors[$Black]       =   "
$lnk.ConsoleColors[$DarkBlue]    =   "
$lnk.ConsoleColors[$DarkGreen]   =   "
$lnk.ConsoleColors[$DarkCyan]    =   "
$lnk.ConsoleColors[$DarkRed]     =   "
$lnk.ConsoleColors[$DarkMagenta] =   "
$lnk.ConsoleColors[$DarkYellow]  =   "
$lnk.ConsoleColors[$Gray]        =   "
$lnk.ConsoleColors[$DarkGray]    =   "
$lnk.ConsoleColors[$Blue]        =   "
$lnk.ConsoleColors[$Green]       =   "
$lnk.ConsoleColors[$Cyan]        =   "
$lnk.ConsoleColors[$Red]         =   "
$lnk.ConsoleColors[$Magenta]     =   "
$lnk.ConsoleColors[$Yellow]      =   "
$lnk.ConsoleColors[$White]       =   "
 
 
$lnk.Save()