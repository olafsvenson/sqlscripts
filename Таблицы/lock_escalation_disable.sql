/*
ALTER TABLE [stage].[Справочник.Пользователи] SET (LOCK_ESCALATION = DISABLE)
ALTER INDEX ALL ON [stage].[Справочник.Пользователи] SET (ALLOW_PAGE_LOCKS = OFF)

*/


SELECT count(1) FROM [stage].[Справочник.Пользователи] with (nolock) 

DS_Orders
9 054 679
DS_FACES
757 965
DS_RouteHeaders
86 463
DS_RoutePoints
1 050 527
DS_Agent_Avto
5288

SELECT s.name AS schemaname, 
       OBJECT_NAME(t.object_id) AS table_name, 
       t.lock_escalation_desc
FROM sys.tables t, 
     sys.schemas s
WHERE OBJECT_NAME(t.object_id) IN('buffer.QualDocumentQualificationStatus')
AND s.name = 'dbo'
AND s.schema_id = t.schema_id;

