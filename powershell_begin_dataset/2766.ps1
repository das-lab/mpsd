
ForEach ($NameSpace in "root\subscription","root\default") { get-wmiobject -namespace $NameSpace -query "select * from __EventConsumer" }
