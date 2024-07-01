-- на базу
use Pythoness
go
grant view definition to [SFN\aburimskiy]
go



----
select 'GRANT VIEW DEFINITION ON [' + schema_name(schema_id) + '].[' + name +
       '] TO ' + '[SFN\sec_SQL_role_analytics_DC-AS-UAT]'
  from sys.all_objects
 where type_desc = 'SQL_STORED_PROCEDURE'
   and schema_id <> schema_id('sys')


/*

 grant view definition on SCHEMA::[dataflow] to [SFN\sec_SQL_role_analytics_DC-AS-UAT]


[agent].[prepCompensationAdditionalDetails]


   */