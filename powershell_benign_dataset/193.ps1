function Set-PowerShellWindowTitle
{

    PARAM($Title)
    $Host.UI.RawUI.WindowTitle = $Title
}

