/*Blitz*/
EXEC dbo.sp_Blitz @CheckUserDatabaseObjects = 1, @CheckServerInfo = 1;

EXEC dbo.sp_Blitz @CheckUserDatabaseObjects = 1, @CheckServerInfo = 1, @OutputDatabaseName = 'DBAtools', @OutputSchemaName = 'dbo', @OutputTableName = 'Blitz';

EXEC dbo.sp_Blitz @CheckUserDatabaseObjects = 1, @CheckServerInfo = 1, @Debug = 1;

EXEC dbo.sp_Blitz @CheckUserDatabaseObjects = 1, @CheckServerInfo = 1, @Debug = 2;

/*BlitzWho*/

EXEC dbo.sp_BlitzWho @ExpertMode = 1, @Debug = 1;

EXEC dbo.sp_BlitzWho @ExpertMode = 0, @Debug = 1;

EXEC dbo.sp_BlitzWho @OutputDatabaseName = 'DBAtools', @OutputSchemaName = 'dbo', @OutputTableName = 'BlitzWho_Results';


/*BlitzFirst*/
EXEC dbo.sp_BlitzFirst @Seconds = 5, @ExpertMode = 1;

EXEC dbo.sp_BlitzFirst @SinceStartup = 1;

EXEC dbo.sp_BlitzFirst @Seconds = 5, @ExpertMode = 1, @ShowSleepingSPIDs = 1;

CREATE DATABASE DBAtools;

EXEC dbo.sp_BlitzFirst @OutputDatabaseName = 'DBAtools',
                       @OutputSchemaName = 'dbo',
                       @OutputTableName = 'BlitzFirst',
                       @OutputTableNameFileStats = 'BlitzFirst_FileStats',
                       @OutputTableNamePerfmonStats = 'BlitzFirst_PerfmonStats',
                       @OutputTableNameWaitStats = 'BlitzFirst_WaitStats',
                       @OutputTableNameBlitzCache = 'BlitzCache',
                       @OutputTableNameBlitzWho = 'BlitzWho';

SELECT TOP 100 * FROM DBAtools.dbo.BlitzFirst ORDER BY 1 DESC;
SELECT TOP 100 * FROM DBAtools.dbo.BlitzFirst_FileStats ORDER BY 1 DESC;
SELECT TOP 100 * FROM DBAtools.dbo.BlitzFirst_PerfmonStats ORDER BY 1 DESC;
SELECT TOP 100 * FROM DBAtools.dbo.BlitzFirst_WaitStats ORDER BY 1 DESC;
SELECT TOP 100 * FROM DBAtools.dbo.BlitzCache ORDER BY 1 DESC;
SELECT TOP 100 * FROM DBAtools.dbo.BlitzWho ORDER BY 1 DESC;


/*BlitzIndex*/
EXEC dbo.sp_BlitzIndex @GetAllDatabases = 1, @Mode = 4;

EXEC dbo.sp_BlitzIndex @DatabaseName = 'StackOverflow', @Mode = 4;

EXEC dbo.sp_BlitzIndex @DatabaseName = 'StackOverflow', @Mode = 4, @SkipPartitions = 0, @SkipStatistics = 0;

EXEC dbo.sp_BlitzIndex @GetAllDatabases = 1, @Mode = 1;

EXEC dbo.sp_BlitzIndex @GetAllDatabases = 1, @Mode = 2;

EXEC dbo.sp_BlitzIndex @GetAllDatabases = 1, @Mode = 3;


/*BlitzCache*/
EXEC dbo.sp_BlitzCache @SortOrder = 'all';

EXEC dbo.sp_BlitzCache @SortOrder = 'all avg', @Debug = 1;

EXEC dbo.sp_BlitzCache @MinimumExecutionCount = 10;

EXEC dbo.sp_BlitzCache @DatabaseName = N'StackOverflow';

EXEC dbo.sp_BlitzCache @OutputDatabaseName = 'DBAtools', @OutputSchemaName = 'dbo', @OutputTableName = 'BlitzCache';

EXEC dbo.sp_BlitzCache @ExpertMode = 1;

EXEC dbo.sp_BlitzCache @ExpertMode = 2;

/*BlitzQueryStore*/
EXEC dbo.sp_BlitzQueryStore @DatabaseName = 'StackOverflow';

/*BlitzBackups*/
EXEC dbo.sp_BlitzBackups @HoursBack = 1000000;

/*sp_AllNightLog_Setup*/
EXEC dbo.sp_AllNightLog_Setup @RPOSeconds = 30, @RTOSeconds = 30, @BackupPath = 'D:\Backup', @RestorePath = 'D:\Backup', @RunSetup = 1;

/*sp_BlitzLock*/
EXEC dbo.sp_BlitzLock @Debug = 1;
