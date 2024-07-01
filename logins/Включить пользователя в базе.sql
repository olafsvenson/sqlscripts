
/*
use [MessageSettler]
GO
GRANT CONNECT TO [SFN\sec_SQL_role_analytics_DC-AS-UAT]
GO
*/


exec sp_msforeachdb 'USE ? GRANT CONNECT TO [SFN\sec_SQL_role_analytics_DC-AS-UAT];ALTER ROLE [db_datareader] ADD MEMBER [SFN\sec_SQL_role_analytics_DC-AS-UAT];ALTER ROLE [db_ddladmin] ADD MEMBER [SFN\sec_SQL_role_analytics_DC-AS-UAT]'