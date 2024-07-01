EXEC sys.sp_MSforeachdb '
IF (''?'' NOT IN (''tempdb'',''Versions''))
begin

use [?]
DECLARE @path NVARCHAR(1000), @db_path nvarchar(1000),@bak_path1 NVARCHAR(1000), @bak_path2 NVARCHAR(1000), @bak_path3 NVARCHAR(1000)
-- путь для бекапа
SET @path=N''\\data\backups3\SQL\''
SET @db_path=@path+db_name()+''\''
SET @bak_path1=@db_path+db_name()+''_backup_''+replace(replace(convert(nvarchar(20),GETDATE(),120),'':'',''''),'' '',''_'')+''_0000000-part1.bak''
SET @bak_path2=@db_path+db_name()+''_backup_''+replace(replace(convert(nvarchar(20),GETDATE(),120),'':'',''''),'' '',''_'')+''_0000000-part2.bak''
SET @bak_path3=@db_path+db_name()+''_backup_''+replace(replace(convert(nvarchar(20),GETDATE(),120),'':'',''''),'' '',''_'')+''_0000000-part3.bak''

PRINT @bak_path1
PRINT @bak_path2
PRINT @bak_path3

EXECUTE master.dbo.xp_create_subdir @db_path

BACKUP DATABASE [?] TO
	 DISK = @bak_path1,
	 DISK = @bak_path2,
	 DISK = @bak_path3
WITH  NOFORMAT, INIT,  SKIP, NOREWIND, NOUNLOAD, COMPRESSION
	, BUFFERCOUNT = 2200
	, BLOCKSIZE = 65536
	, MAXTRANSFERSIZE=4194304

-- удаляем старые бекапы старше 31 дня
DECLARE @dt NVARCHAR(30)
SET @dt=cast( (GETDATE()-31) AS nvarchar(30))

EXECUTE master.dbo.xp_delete_file 0,N''\\data\backups3\SQL'',N''bak'',@dt,1
end
'