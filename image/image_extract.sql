/*
--���������� ��������� ������� �� ���������� ������ � OLE
EXEC sp_configure 'Ole Automation Procedures';
GO
--���� �� ������� - ��������� ����������
sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
--���� 0 �� ���������� 1
sp_configure 'Ole Automation Procedures', 1;
GO
RECONFIGURE;
GO
--������� ��������� �������
sp_configure 'Ole Automation Procedures', 0;
sp_configure 'show advanced options', 0;
RECONFIGURE;
*/

DECLARE @Size int, @Pos int,@BufSize int ,@HR int
		,@Buffer varbinary(4096), @Stream int
		,@FileName varchar(2048)
		 
DECLARE @FilePath varchar(1024)='C:\' --� ������ ������� ������ ���� ������ � ���� �����
--������� ADODB.Stream
EXEC @HR = sp_OACreate 'ADODB.Stream',@Stream OUT 
--���������� ��������
EXEC @HR = sp_OASetProperty @Stream,'Type',1 -- binary 
EXEC @HR = sp_OASetProperty @Stream,'Mode',3 -- write|read 

		SELECT @Pos = 0, @Size = DATALENGTH(DataBlock)  ,@FileName=@FilePath+'MyFile.zip'
		FROM MyTable
		--WHERE --��� ������� �� ������ ���������� ������ 

		EXEC @HR = sp_OAMethod @Stream,'Open' 

		WHILE @Pos < @Size 
		BEGIN 
			SET @BufSize = CASE WHEN @Size - @Pos < 4096 THEN @Size - @Pos ELSE 4096 END 

			SELECT @Buffer = SUBSTRING(DataBlock ,@Pos+1, @BufSize) 
			FROM MyTable
			--WHERE --��� ������� �� ������ ���������� ������ 
			EXEC @HR = sp_OAMethod @Stream, 'Write', NULL, @Buffer 

			SET @Pos = @Pos + @BufSize 
		END 

		--adSaveCreateNotExist 1 
		--adSaveCreateOverWrite 2 
		EXEC @HR = sp_OAMethod @Stream, 'SaveToFile',Null,@FileName,2
		EXEC @HR = sp_OAMethod @Stream, 'Close'

EXEC @HR = sp_OADestroy @Stream