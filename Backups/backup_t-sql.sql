declare @cmd1 varchar(500)
declare @cmd2 varchar(500)

set @cmd1 ='IF (''?'' NOT IN (''tempdb'' )) print ''*** Processing DB [?] ***'''

set @cmd2 ='

use [?]


DECLARE @path NVARCHAR(1000), @db_path nvarchar(1000),@bak_path NVARCHAR(1000)

SET @path=N''\\lb-node3\Y\SQL_Backups\SQLArchive\''
SET @db_path=@path+db_name()+''\''
SET @bak_path=@db_path+db_name()+''_''+replace(replace(convert(nvarchar(20),GETDATE(),120),'':'',''''),'' '',''_'')+''.bak''

PRINT @bak_path
EXECUTE master.dbo.xp_create_subdir @db_path

BACKUP DATABASE [?] TO  DISK = @bak_path WITH NOFORMAT, NOINIT, SKIP, REWIND, NOUNLOAD,  STATS = 1


DECLARE @dt NVARCHAR(30)
SET @dt=cast( (GETDATE()-14) AS nvarchar(30))

EXECUTE master.dbo.xp_delete_file 0,N''\\lb-node3\Y\SQL_Backups\SQLArchive'',N''bak'',@dt,1
'


EXEC sys.sp_MSforeachdb @command1=@cmd1,@command2=@cmd2 