




param (
		$Server
		);


[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null; 
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMOExtended")| Out-Null; 
 

function writeHtmlPage 
{ 
    param ($title, $heading, $body, $filePath); 
    $html = "<html> 
             <head> 
                 <title>$title</title> 
             </head> 
             <body> 
                 <h1>$heading</h1> 
                $body 
             </body> 
             </html>"; 
    $html | Out-File -FilePath $filePath; 
} 
 

function getDatabases 
{ 
    param ($sql_server); 
    $databases = $sql_server.Databases | Where-Object {$_.IsSystemObject -eq $false}; 
    return $databases; 
} 
 

function getDatabaseSchemata 
{ 
    param ($sql_server, $database); 
    $db_name = $database.Name; 
    $schemata = $sql_server.Databases[$db_name].Schemas;
	foreach ($schema in $schemata) 
	{ 
		if ( $schema.Owner -match '\\' )
			{$schema.Owner = $schema.Owner -replace '\\', '-'};
	} 
	return $schemata; 
} 
 

function getDatabaseTables 
{ 
    param ($sql_server, $database); 
    $db_name = $database.Name; 
    $tables = $sql_server.Databases[$db_name].Tables | Where-Object {$_.IsSystemObject -eq $false}; 
    return $tables; 
} 
 

function getDatabaseStoredProcedures 
{ 
    param ($sql_server, $database); 
    $db_name = $database.Name; 
    $procs = $sql_server.Databases[$db_name].StoredProcedures | Where-Object {$_.IsSystemObject -eq $false}; 
    return $procs; 
} 
 

function getDatabaseFunctions 
{ 
    param ($sql_server, $database); 
    $db_name = $database.Name; 
    $functions = $sql_server.Databases[$db_name].UserDefinedFunctions | Where-Object {$_.IsSystemObject -eq $false}; 
    return $functions; 
} 
 

function getDatabaseViews 
{ 
    param ($sql_server, $database); 
    $db_name = $database.Name; 
    $views = $sql_server.Databases[$db_name].Views | Where-Object {$_.IsSystemObject -eq $false}; 
    return $views; 
} 
 

function getDatabaseTriggers 
{ 
    param ($sql_server, $database); 
    $db_name = $database.Name; 
    $tables = $sql_server.Databases[$db_name].Tables | Where-Object {$_.IsSystemObject -eq $false}; 
    $triggers = $null; 
    foreach($table in $tables) 
    { 
        $triggers += $table.Triggers; 
    } 
    return $triggers; 
} 

function getDBLogins
{
	param ($sql_server, $database);
	$db_name = $database.Name;
	$logins = $sql_server.Databases[$db_name].Users;
	return $logins;
}


function getLogins
{
	param ($sql_server);
	$logins = $sql_server.Logins | Where-Object {$_.IsSystemObject -eq $false};
	return $logins;
}
 

function getLinkedServers
{
 	param ($sql_server);
	$linkedservers = $sql_server.LinkedServers;
	return $linkedservers;
}
  
function getJobs
{
 	param ($sql_server);
	$jobs = $sql_server.JobServer.Jobs;
	return $jobs;
}
 


function buildLinkList 
{ 
    param ($array, $path); 
    $output = "<ul>"; 
    foreach($item in $array) 
    { 
        if($item.IsSystemObject -eq $false) 
        {
            if([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.Schema") 
            { 
                $output += "`n<li><a href=`"$path" + $item.Owner + ".html`">" + $item.Name + "</a></li>"; 
            } 
            elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.Trigger") 
            { 
                $output += "`n<li><a href=`"$path" + $item.Parent.Schema + "." + $item.Name + ".html`">" + $item.Parent.Schema + "." + $item.Name + "</a></li>"; 
            } 
			elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.Login") 
            { 
                
				$output += "`n<li><a href=`"$path" + ($item.Name -replace "\\", "-") + ".html`">" + $item.Name + "</a></li>"; 
            }
			elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.User") 
            { 
				
				$output += "`n<li><a href=`"$path" + ($item.Name -replace "\\", "-") + ".html`">" + $item.Name + "</a></li>"; 
            }
            else 
            { 
				
				$output += "`n<li><a href=`"$path" + $item.Schema + "." + $item.Name + ".html`">" + $item.Schema + "." + $item.Name + "</a></li>"; 
            } 
        }
		elseif($item.IsSystemObject -eq $true)
		{


			if([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.Agent.Job")
			{
				$output += "`n<li><a href=`"$path" + $item + ".html`">" + $item + "</a></li>";
			}
			elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.LinkedServer")
			{
				$output += "`n<li><a href=`"$path" + $item.Name + ".html`">" + $item.Name + "</a></li>";
			}
			elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.User") 
            { 
				
				$output += "`n<li><a href=`"$path" + ($item.Name -replace "\\", "-") + ".html`">" + $item.Name + "</a></li>"; 
            }
		}
    } 
    $output += "</ul>"; 
    return $output; 
} 
 

function getObjectDefinition 
{ 
    param ($item); 
    $definition = ""; 
    
	if([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.Schema")
    { 
		$definition = $item.Script(); 
    } 
    else 
    { 
        $options = New-Object ('Microsoft.SqlServer.Management.Smo.ScriptingOptions'); 
        $options.DriAll = $true; 
        $options.Indexes = $true; 
        $definition = $item.Script($options);
		
    } 
    return "<pre>$definition</pre>"; 
} 
 


function getDescriptionExtendedProperty 
{ 
    param ($item); 
    $description = "No extended property documentation on object."; 
    foreach($property in $item.ExtendedProperties) 
    { 
        
        
        $description = $property.Value; 
        
    } 
    return $description; 
} 
 

function getProcParameterTable 
{ 
    param ($proc); 
    $proc_params = $proc.Parameters; 
    $prms = $proc_params | ConvertTo-Html -Fragment -Property Name, DataType, DefaultValue, IsOutputParameter; 
    return $prms; 
} 
 

function getTableColumnTable 
{ 
    param ($table); 
    $table_columns = $table.Columns; 
    $objs = @(); 
    foreach($column in $table_columns) 
    { 
        $obj = New-Object -TypeName Object; 
        $description = getDescriptionExtendedProperty $column; 
        Add-Member -Name "Name" -MemberType NoteProperty -Value $column.Name -InputObject $obj; 
        Add-Member -Name "DataType" -MemberType NoteProperty -Value $column.DataType -InputObject $obj; 
        Add-Member -Name "Default" -MemberType NoteProperty -Value $column.Default -InputObject $obj; 
        Add-Member -Name "Identity" -MemberType NoteProperty -Value $column.Identity -InputObject $obj; 
        Add-Member -Name "InPrimaryKey" -MemberType NoteProperty -Value $column.InPrimaryKey -InputObject $obj; 
        Add-Member -Name "IsForeignKey" -MemberType NoteProperty -Value $column.IsForeignKey -InputObject $obj; 
        Add-Member -Name "Description" -MemberType NoteProperty -Value $description -InputObject $obj; 
        $objs = $objs + $obj; 
    } 
    $cols = $objs | ConvertTo-Html -Fragment -Property Name, DataType, Default, Identity, InPrimaryKey, IsForeignKey, Description; 
    return $cols; 
} 
 

function getTriggerDetailsTable 
{ 
    param ($trigger); 
    $trigger_details = $trigger | ConvertTo-Html -Fragment -Property IsEnabled, CreateDate, DateLastModified, Delete, DeleteOrder, Insert, InsertOrder, Update, UpdateOrder; 
    return $trigger_details; 
} 
 

function createObjectTypePages 
{ 
    param ($objectName, $objectArray, $filePath, $db); 
    New-Item -Path $($filePath + $db.Name + "\$objectName") -ItemType directory -Force | Out-Null; 
    
    $page = $filePath + $($db.Name) + "\$objectName\index.html"; 
    $list = buildLinkList $objectArray ""; 
    if($objectArray -eq $null) 
    { 
        $list = "No $objectName in $db"; 
    }
    writeHtmlPage $objectName $objectName $list $page; 
    
    if($objectArray.Count -gt 0) 
    { 
        foreach ($item in $objectArray) 
        { 
			if($item.IsSystemObject -eq $false) 
            { 
                $description = getDescriptionExtendedProperty($item); 
                $body = "<h2>Description</h2>$description"; 
                $definition = getObjectDefinition $item; 
                if([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.Schema") 
                { 
					$page = $filePath + $($db.Name + "\$objectName\" + $item.Owner + ".html");
                } 
                elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.Trigger") 
                { 
                    $page = $filePath + $($db.Name + "\$objectName\" + $item.Parent.Schema + "." + $item.Name + ".html"); 
            	}
				elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.Login")
				{
					$page = $filePath + $($db.Name + "\$objectname\" + ($item.Name -replace "\\", "-") + ".html");
				}
				elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.User")
				{
					$page = $filePath + $($db.Name + "\$objectname\" + ($item.Name -replace "\\", "-") + ".html");
				}
            	else 
            	{ 
					$page = $filePath + $($db.Name + "\$objectName\" + $item.Schema + "." + $item.Name + ".html"); 
                } 
                $title = ""; 
            	if([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.Schema") 
            		{ 
            		    $title = $item.Name; 
            		    $body += "<h2>Object Definition</h2>$definition"; 
            		}
					elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.Login")
					{
						$title = $item.Name;
						$body += "<h2>Object Definition</h2>$definition";
					}
	                else 
	                { 
	                $title = $item.Schema + "." + $item.Name; 
	                if(([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.StoredProcedure") -or ([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.UserDefinedFunction")) 
	                  	{ 
	                   	    $proc_params = getProcParameterTable $item; 
	                   	    $body += "<h2>Parameters</h2>$proc_params<h2>Object Definition</h2>$definition"; 
	                   	} 
		                elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.Table") 
		                { 
		                    $cols = getTableColumnTable $item; 
		                    $body += "<h2>Columns</h2>$cols<h2>Object Definition</h2>$definition"; 
		                } 
		                elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.View") 
		                { 
		                    $cols = getTableColumnTable $item; 
		                    $body += "<h2>Columns</h2>$cols<h2>Object Definition</h2>$definition"; 
		                } 
		                elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.Trigger") 
		                { 
		                    $title = $item.Parent.Schema + "." + $item.Name; 
		                    $trigger_details = getTriggerDetailsTable $item; 
		                    $body += "<h2>Details</h2>$trigger_details<h2>Object Definition</h2>$definition"; 
	                  	}




                } 
                
            }
			elseif($item.IsSystemObject -eq $true) 
			
			{
				$description = getDescriptionExtendedProperty($item); 
                $body = "<h2>Description</h2>$description"; 
                $definition = getObjectDefinition $item;
                if([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.Agent.Job") 
                { 
					$title = $item;
					$page = $filePath + $($db.Name + "\$objectName\" + $item + ".html");
					$body += "<h2>Object Definition</h2>$definition";
                }
				elseif([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.LinkedServer") 
                { 
					$title = $item.Name;
					$page = $filePath + $($db.Name + "\$objectName\" + $item.Name + ".html");
					$body += "<h2>Object Definition</h2>$definition";
                }
				if([string]$item.GetType() -eq "Microsoft.SqlServer.Management.Smo.User") 
                { 
					$title = $item.Name;
					$page = $filePath + $($db.Name + "\$objectName\" + $item.Name + ".html");
					$body += "<h2>Object Definition</h2>$definition";
                }
			}
			writeHtmlPage $title $title $body $page; 
        } 
    } 
}	
 

$filePath = "$env:USERPROFILE\database_documentation\$Server\"; 
New-Item -Path $filePath -ItemType directory -Force | Out-Null; 

$sql_server = New-Object Microsoft.SqlServer.Management.Smo.Server $Server; 


$sql_server.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.Table], "IsSystemObject"); 
$sql_server.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.View], "IsSystemObject"); 
$sql_server.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.StoredProcedure], "IsSystemObject"); 
$sql_server.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.Trigger], "IsSystemObject"); 
$sql_server.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.User], "IsSystemObject");


$databases = getDatabases $sql_server; 


$linkedservers = getLinkedServers $sql_server;
createObjectTypePages "LinkedServers" $linkedservers $filePath;
Write-Host "Documented Linked Servers on " $sql_server.Name;


$jobs = getJobs $sql_server;
createObjectTypePages "Jobs" $jobs $filePath;
Write-Host "Documented Jobs on " $sql_server.Name;


$logins = getLogins $sql_server;
createObjectTypePages "Logins" $logins $filePath;
Write-Host "Documented Logins on " $sql_server.Name;
	
	
foreach ($db in $databases) 
{ 
    Write-Host "Started documenting " $db.Name; 
    
    New-Item -Path $($filePath + $db.Name) -ItemType directory -Force | Out-Null; 
 
    
    $db_page = $filePath + $($db.Name) + "\index.html"; 
    $body = "<ul> 
                <li><a href='Schemata/index.html'>Schemata</a></li> 
                <li><a href='Tables/index.html'>Tables</a></li> 
                <li><a href='Views/index.html'>Views</a></li> 
                <li><a href='Stored Procedures/index.html'>Stored Procedures</a></li> 
                <li><a href='Functions/index.html'>Functions</a></li> 
                <li><a href='Triggers/index.html'>Triggers</a></li> 
				<li><a href='Users/index.html'>Users</a></li>
            </ul>"; 
    writeHtmlPage $db $db $body $db_page; 
         
    
    $schemata = getDatabaseSchemata $sql_server $db;
    createObjectTypePages "Schemata" $schemata $filePath $db; 
    Write-Host "`tDocumented schemata in " $db.Name; 
    
	
    $tables = getDatabaseTables $sql_server $db; 
    createObjectTypePages "Tables" $tables $filePath $db; 
    Write-Host "Documented tables in " $db.Name; 
    
	
    $views = getDatabaseViews $sql_server $db; 
    createObjectTypePages "Views" $views $filePath $db; 
    Write-Host "`tDocumented views in " $db.Name; 
    
	
    $procs = getDatabaseStoredProcedures $sql_server $db; 
    createObjectTypePages "Stored Procedures" $procs $filePath $db; 
    Write-Host "`tDocumented stored procedures in " $db.Name; 
   
	
    $functions = getDatabaseFunctions $sql_server $db; 
    createObjectTypePages "Functions" $functions $filePath $db; 
    Write-Host "`tDocumented functions in " $db.Name; 
    
	
    $triggers = getDatabaseTriggers $sql_server $db; 
    createObjectTypePages "Triggers" $triggers $filePath $db; 
    Write-Host "`tDocumented triggers in " $db.Name; 
    
	
	$logins = getDBLogins $sql_server $db;
	createObjectTypePages "Users" $logins $filePath $db;
	Write-Host "`tDocumented Users in " $db.Name;
	
	Write-Host "Finished documenting " $db.Name; 
}