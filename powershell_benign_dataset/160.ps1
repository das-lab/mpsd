Function Get-StringCharCount
{
	
	PARAM ([String]$String)
	($String -as [Char[]]).count
}