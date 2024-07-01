/*
	use pegasus2008ms 
	USE pegasus2008bb
	use pegasus2008
*/

SELECT s.name as schemaname, object_name (t.object_id) as table_name, t.lock_escalation_desc
FROM sys.tables t, sys.schemas s
WHERE object_name(t.object_id) IN ( 'QualDocumentQualificationStatus' )
--and s.name = 'buffer' 
and s.schema_id = t.schema_id 

/*
ALTER TABLE [RG_AllObjects_v4] SET (LOCK_ESCALATION = DISABLE)
ALTER INDEX ALL ON [RG_AllObjects_v4] SET (ALLOW_PAGE_LOCKS = OFF)
ALTER TABLE [_InfoRg52926] SET (LOCK_ESCALATION = DISABLE);ALTER INDEX ALL ON [_InfoRg52926] SET (ALLOW_PAGE_LOCKS = OFF)
*/
ALTER INDEX ALL ON [RG_AllObjects_v4] rebuild with(online=on,ALLOW_PAGE_LOCKS = OFF)

SELECT count(1) FROM buffer.[QualDocumentQualificationStatus] with (nolock) 
1 556 764

select * from QualDocumentQualificationStatus
/* 
	отключил Pythoness_buf.buffer.[QualDocumentQualificationStatus]
  12.09
*/

ALTER INDEX [_InfoRg53940_4] ON [_InfoRg53940] REBUILD WITH (SORT_IN_TEMPDB = ON, ONLINE = ON, allow_page_locks=off)
go
ALTER INDEX [_InfoRg53940_5] ON [_InfoRg53940] REBUILD WITH (SORT_IN_TEMPDB = ON, ONLINE = ON, allow_page_locks=off)
go
ALTER INDEX [_InfoRg53940_2] ON [_InfoRg53940] REBUILD WITH (SORT_IN_TEMPDB = ON, ONLINE = ON, allow_page_locks=off)
go
ALTER INDEX [_Add_5673_00190] ON [_InfoRg53940] REBUILD WITH (SORT_IN_TEMPDB = ON, ONLINE = ON, allow_page_locks=off)
go
ALTER INDEX [_InfoRg53940_6] ON [_InfoRg53940] REBUILD WITH (SORT_IN_TEMPDB = ON, ONLINE = ON, allow_page_locks=off)
go
ALTER INDEX [_InfoRg53940_3] ON [_InfoRg53940] REBUILD WITH (SORT_IN_TEMPDB = ON, ONLINE = ON, allow_page_locks=off)
GO
ALTER INDEX [_InfoRg53940_1] ON [_InfoRg53940] REBUILD WITH (SORT_IN_TEMPDB = ON, ONLINE = ON, allow_page_locks=off)
go