


$ShellApp = new-Object -ComObject shell.application
Add-Type -AssemblyName PresentationFramework



[xml]$xaml = @"

<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AlliedVOA | Mini Desktop Tool - Folder Shortcuts | v1.5 " Height="150" Width="374" Background="
    <Grid>
        <Button Content="Desktop" Height="23" HorizontalAlignment="Left" Name="button1" VerticalAlignment="Top" Width="75" Margin="12,12,0,0" />
        <Button Content="Drives" Height="23" HorizontalAlignment="Left" Margin="93,12,0,0" Name="button2" VerticalAlignment="Top" Width="75" />
        <Button Content="Control Pnl" Height="23" HorizontalAlignment="Left" Margin="174,12,0,0" Name="button3" VerticalAlignment="Top" Width="75" />
        <Button Content="Favorites" Height="23" HorizontalAlignment="Left" Margin="255,12,0,0" Name="button4" VerticalAlignment="Top" Width="75" />
        <Button Content="Printers" Height="23" HorizontalAlignment="Left" Margin="12,41,0,0" Name="button5" VerticalAlignment="Top" Width="75" />
        <Button Content="History" Height="23" HorizontalAlignment="Left" Margin="93,41,0,0" Name="button6" VerticalAlignment="Top" Width="75" />
        <Button Content="Net Conn" Height="23" HorizontalAlignment="Left" Margin="174,41,0,0" Name="button7" VerticalAlignment="Top" Width="75" />
        <Button Content="Recent" Height="23" HorizontalAlignment="Left" Margin="255,41,0,0" Name="button8" VerticalAlignment="Top" Width="75" />
        <Button Content="Prog Files" Height="23" HorizontalAlignment="Left" Margin="12,70,0,0" Name="button9" VerticalAlignment="Top" Width="75" />
        <Button Content="Local Apps" Height="23" HorizontalAlignment="Left" Margin="93,70,0,0" Name="button10" VerticalAlignment="Top" Width="75" />
        <Button Content="Start-Up" Height="23" HorizontalAlignment="Left" Margin="174,70,0,0" Name="button11" VerticalAlignment="Top" Width="75" />

    </Grid>
</Window>

"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$d = [Windows.Markup.XamlReader]::Load($reader) 


	$desktop = $d.FindName("button1")
	$desktop.add_Click({ $ShellApp.Explore(0x00) })
	

	$drives = $d.FindName("button2")
	$drives.add_Click({ $ShellApp.Explore(0x11) })


	$cPanel = $d.FindName("button3")
	$cpanel.add_Click({ $ShellApp.Explore(0x03) })


	$fav = $d.FindName("button4")
	$fav.add_Click({ $ShellApp.Explore(0x06) })


	$printer = $d.FindName("button5")
	$printer.add_click({ $ShellApp.Explore(0x04) })


   $history = $d.FindName("button6")
   $history.add_click({ $ShellApp.Explore(0x22) })


	$network = $d.FindName("button7")
	$network.add_click({ ncpa.cpl })
	

	$recent = $d.FindName("button8")
	$recent.add_click({ $ShellApp.Explore(0x08 ) })



	$nethood = $d.FindName("button9")
	$nethood.add_click({ $ShellApp.Explore(0x26) })


	$localapp = $d.FindName("button10")
	$localapp.add_click({ $ShellApp.Explore(0x1c) })


	$startup = $d.FindName("button11")
	$startup.add_click({ $ShellApp.Explore(0x07) })

$d.ShowDialog() | Out-Null