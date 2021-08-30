



 


Set-ExecutionPolicy Unrestricted
c:\temp\InitPowerSMO.ps1
$server = SMO_Server 
$db = SMO_Database $server "PowerDW"
$db.DatabaseOptions.RecoveryModel="Simple"
$db.Create()
c:
cd \
md PowerDW


function global:insert-table ($tablename) { 
$dataset = $DB.ExecuteWithResults( "sp_columns ["+$tablename+"]")
$tableCol=$DATASET.TABLES[0].ROWS | select column_name, type_name,char_octect_length
$all='function insert-'+$tablename+'  ('; 
$varall=''; $tableCol | %{$varall=$varall+'$'+$_.column_name+','}; 
$all=$($all+$varall+')').replace(",)",") "); 
$all=$all+"{  "" insert into ["+$tablename+"] values ("
if ($tableCol.count -lt 1) {$tableCol | %{$apri="'{"; $chiudi="}',"; $oggetto=$_; `
if (($oggetto.type_name -eq 'bigint') -or ($oggetto.type_name -eq 'Int32')  -or `
($oggetto.type_name -eq 'datetime')) {$apri="{";$chiudi="},";} $all=$all+$apri+'0'+$chiudi; }; } `
else {$num=0..($tableCol.count-1); $num | %{$apri="'{"; $chiudi="}',"; if (($tableCol[$_].type_name -eq 'bigint') `
-or ($tableCol[$_].type_name -eq 'Int32')  -or ($tableCol[$_].type_name -eq 'datetime')) {$apri="{";$chiudi="},";} `
$all=$all+$apri+$_+$chiudi; }; }$all=$($all+')').replace(",)",") ") + """ -f "+$varall.substring(0,$($varall.length-1)) + " }";
$all
}


function global:AD-Table ($tablename,$Variabile,$errorpath) { 
if ($errorpath -eq '') {$errorpath="c:\PowerDW\"}


$query="CREATE TABLE ["+$tablename+"] ("
$variables |%{ $query=$query+$($_)+' varchar(500), '}
$query=$($query+')').replace("), )","))")


$DB.ExecuteNonQuery("drop table ["+$tablename+"]")
$DB.ExecuteNonQuery($query)


$dom=Get-WmiObject Win32_NTDomain
$domall=$($dom | select DomainName, DomainControllerName, DnsForestName | where {$_.DomainControllerName -gt ''} | 
%{$foresta=$_.DnsForestName; $domfo=$foresta.split('.');$domfo1=$domfo[0];$DomainName=$_.DomainName;`
$root=$_.DomainControllerName.replace('\\','')+'.'+$_.DnsForestName; if($DomainName -ne $domfo1.ToUpper()) `
{$root=$_.DomainControllerName.replace('\\','')+'.'+$DomainName+'.'+$_.DnsForestName;} $root})
$AdditionalDomains='dc1.dom1.com','dc2.dom1.com'


$domall=$($domall | where {$_ -ne 'DCExcludeDom1.dom1.com' }) +$AdditionalDomains


$all=insert-table $tablename
Invoke-Expression $($all)
write-host $all



$varall='insert-'+$tablename
$REP=@'
.REPLACE("'","''")
'@
$a=@'
 $o]
'@


$letters='$','0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f','g','h','i','j','k','l','m','n',`
    'o','p','q','r','s','t','u','v','w','x','y','z'
$variables |%{ $varall=$varall+' $($_.'+$_+'.tostring())'+$REP}

{ write-host $_.name ' ' $_.member[$o] }} else {write-host $_.name} }


$varall2=$varall.replace("$_.member","$_.member["+$a);
$errori=$error.count
"Inizio "+$(get-date)>$($errorpath+$tablename+".log")
"Inizio "+$(get-date)>$($errorpath+$tablename+"2.log")
$domall | %{
    for ($k=0; $k -lt $letters.count; $k++) 
    {$interrogoAD="get-adobject  -server "+$_+" -filter ""(&("+$Variabile+"="+$letters[$k]+"*)(objectcategory="+$tablename+"))"" `
        -PageSize 1000 "; Invoke-Expression $($interrogoAD) | 
            %{
                        if ($varall.indexof("member") -gt -1) { for ( $o=0;$o -lt $_.member.count; $o++) `
                            { Invoke-Expression $($VARALL2) | %{$DB.ExecuteNonQuery($_)};  if ($errori -lt $error.count) `
                            {$_ >>$($errorpath+$tablename+"2.log"); $errori=$error.count; } }} 
                        else {Invoke-Expression $($VARALL) | %{$DB.ExecuteNonQuery($_); if ($errori -lt $error.count) `
                             { $_>>$($errorpath+$tablename+"2.log"); $errori=$error.count; }}} 
            } 
            if ($errori -lt $error.count) {$_ >>$($errorpath+$tablename+"2.log"); $errori=$error.count; }
   }
  }
"Fine "+$(get-date)>>$($errorpath+$tablename+".log")
"Fine "+$(get-date)>>$($errorpath+$tablename+"2.log")
}




$variables='cn','OperatingSystem','OperatingSystemServicePack','OperatingSystemversion','distinguishedname',`
    'objectclass','objectcategory','name','description'
AD-Table Computer name ''


$variables='cn','name','distinguishedName','whenChanged','whenCreated','objectclass','groupType','description','member','mail','displayname'
AD-Table Group name ''


$variables='Samaccountname','Mail','sn','TelephoneNumber','GivenName','Mobile','proxyAddresses','distinguishedName',`
    'PhysicalDeliveryOfficeName','description','displayname','Homemdb','MSExchHomeServerName','name','objectcategory','objectclass'
AD-Table Person displayname ''
