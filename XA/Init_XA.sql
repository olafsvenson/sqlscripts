--exec sp_sqljdbc_xa_install

exec xp_sqljdbc_xa_init

select file_version,product_version,company,[description],name 
from sys.dm_os_loaded_modules 
where name  like '%JDBC%'