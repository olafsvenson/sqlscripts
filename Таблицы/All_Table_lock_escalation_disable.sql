USE [supa];
DECLARE @cmd1 VARCHAR(8000), @cmd2 VARCHAR(8000);
SET @cmd1 = '';
DECLARE CheckList CURSOR
FOR SELECT
    --проверим, включены ли эскалации
    CASE
        WHEN t.lock_escalation_desc != 'DISABLE'
        THEN 'ALTER TABLE [dbo].[' + t.[name] + '] SET (LOCK_ESCALATION = DISABLE)'
        ELSE ''
    END AS tbl_lock
    FROM sys.tables t
    WHERE type = 'U'
          AND name IN('_AccumRgT33623');
OPEN CheckList;
FETCH NEXT FROM CheckList INTO @cmd1;
WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @cmd1 != ''
            EXEC (@cmd1);
        --print @cmd1
        FETCH NEXT FROM CheckList INTO @cmd1;
    END;
CLOSE CheckList;
DEALLOCATE CheckList;