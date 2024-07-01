;with FGObjects(SchemaName, TableName, IndexName, RowNum, Cnt)
as
(
    select 
        s.Name, t.Name, i.Name
        ,ROW_NUMBER() over(order by t.object_id, i.index_id) as RowNum
        ,COUNT(*) over() as Cnt
    from
        sys.indexes i join sys.filegroups f on
            i.data_space_id = f.data_space_id
        join sys.all_objects t ON
            i.object_id = t.object_id
        join sys.schemas s on
            t.schema_id = s.schema_id
    where
        i.index_id >= 1 and
        t.type = 'U' and -- User Created Tables
        i.data_space_id = f.data_space_id and
        f.name = 'PRIMARY' -- Filegroup
)
select 
    'alter index [' as [text()]
    ,[IndexName] as [text()]
    ,'] on [' + SchemaName + '].[' as [text()]
    ,[TableName] as [text()]
    ,'] reorganize;' + CHAR(13) + CHAR(10) as [text()]
    ,'raiserror(''' as [text()]
    ,RowNum as [text()]
    ,'/' as [text()]
    ,Cnt as [text()]
    ,' is done'',0,1) with nowait;' + CHAR(13) + CHAR(10) as [text()]
    ,'go' + CHAR(13) + CHAR(10) as [text()]
from FGObjects
for xml path('');