select distinct
    QUOTENAME(OBJECT_SCHEMA_NAME(p.object_id)) + '.' 
        + QUOTENAME(OBJECT_NAME(p.object_id)) [This procedure...], 
    QUOTENAME(OBJECT_SCHEMA_NAME(p_ref.object_id)) + '.' 
        + QUOTENAME(OBJECT_NAME(p_ref.object_id)) [... calls this procedure]
from sys.procedures p
cross apply sys.dm_sql_referenced_entities(schema_name(p.schema_id) + '.' + p.name, 'OBJECT') re
join sys.procedures p_ref
	on re.referenced_entity_name = p_ref.name
order by 1,2