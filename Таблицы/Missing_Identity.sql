SELECT Seq
FROM (SELECT ROW_NUMBER() OVER (ORDER BY c1.column_id) Seq
FROM sys.columns c1
CROSS JOIN sys.columns c2) SequenceTable
LEFT JOIN BigTable ON BigTable.ID = SequenceTable.Seq
WHERE BigTable.ID IS NULL AND
Seq < (SELECT MAX(ID) FROM BigTable)
GO