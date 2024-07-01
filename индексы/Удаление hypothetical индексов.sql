SELECT *
FROM sys.indexes i
WHERE is_hypothetical = 1


SELECT 'drop index ['+i.name+'] ON ['+OBJECT_NAME(i.[object_id])+']' AS [DROP]
FROM sys.indexes i
WHERE is_hypothetical = 1
