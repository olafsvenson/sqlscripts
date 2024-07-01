
SET NOCOUNT ON;
--USE Itilium_SUP
--SELECT OBJECT_ID('[dbo].[_Reference91]')
--use pegasus2008ms
DECLARE @objectID INT = OBJECT_ID('[event_message_context]');

select @objectID

SELECT 
	[rowmodcounter].[modPercent], 
	names.dbName,
	names.schemaName,
	names.tableName,
	names.statsName,
	[s].[auto_created], 
	[s].[no_recompute], 
	[sp].[last_updated],
	[sp].[rows],
	[sp].[rows_sampled],
	[sp].[steps],
	[sp].[unfiltered_rows],
	[sp].[modification_counter],
	sampleRate = (1.0*sp.rows_sampled/sp.rows)*100,
	'UPDATE STATISTICS ' + names.schemaName + '.' + names.tableName + '(' + names.statsName + ')'
FROM [sys].[stats] s
CROSS APPLY [sys].[dm_db_stats_properties]([s].[object_id],[s].[stats_id]) sp
INNER JOIN [sys].[tables] t
	ON [s].[object_id] = [t].[object_id] 
CROSS APPLY (
				SELECT (1.0*[sp].[modification_counter]/NULLIF([sp].[rows],0))*100
				) AS rowmodcounter(modPercent)
CROSS APPLY (SELECT 	
	dbName			= DB_NAME(),
	schemaName		= SCHEMA_NAME(t.schema_id),
	tableName		= t.[name], 
	statsName		= s.[name]
	) AS names
WHERE 
	(t.[object_id] = @objectID OR @objectID IS NULL) 
	--AND [t].[is_ms_shipped] =0
	--AND OBJECTPROPERTY(s.[object_id],'IsMSShipped')=0 
	--AND [rowmodcounter].[modPercent] > @modPercentLimit
	AND names.tableName IN ('event_message_context')
ORDER BY [rowmodcounter].[modPercent] DESC;
GO

-- ALTER INDEX ALL ON _InfoRg41296 rebuild
--157383

--SELECT count(1) FROM _InfoRg41296 with (nolock) 