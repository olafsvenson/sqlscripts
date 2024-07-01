SELECT 
'ALTER AUTHORIZATION ON DATABASE::['+ [name] +'] TO [sa]', 
suser_sname( owner_sid ), 
* 
FROM sys.databases




