CREATE PROCEDURE dbo.usp_get_db_files_near_maxsize (@nearMaxSizePct DECIMAL (5,1) = 10.0)
AS
BEGIN
    SET NOCOUNT ON

    CREATE TABLE ##ALL_DB_Files (
                    dbname SYSNAME,
                    fileid smallint,
                    groupid smallint,
                    [size] INT NOT NULL,
                    [maxsize] INT NOT NULL,
                    growth INT NOT NULL,
                    status INT,
                    perf INT,
                    [name] SYSNAME NOT NULL,
                    [filename] NVARCHAR(260) NOT NULL)

    -- loop over all databases and collect the information from sysfiles
    -- to the ALL_DB_Files tables using the sp_MsForEachDB system procedure
    EXEC sp_MsForEachDB
        @command1='use [$];Insert into ##ALL_DB_Files select db_name(), * from sysfiles',
        @replacechar = '$'

    -- output the results
    SELECT
        [dbname] AS DatabaseName,
        [name] AS dbFileLogicalName,
        [filename] AS dbFilePhysicalFilePath,
        ROUND(size * CONVERT(FLOAT,8) / 1024,0) AS ActualSizeMB,
        ROUND(maxsize * CONVERT(FLOAT,8) / 1024,0) AS MaxRestrictedSizeMB,
        ROUND(maxsize * CONVERT(FLOAT,8) / 1024,0) - ROUND(size * CONVERT(FLOAT,8) / 1024,0) AS SpaceLeftMB
    FROM ##ALL_DB_Files
    WHERE maxsize > -1 AND -- skip db files that have no max size
        ([maxsize] - [size]) * 1.0 < 0.01 * @nearMaxSizePct * [maxsize] -- find db files within percentage
    ORDER BY 6

    DROP TABLE ##ALL_DB_Files

    SET NOCOUNT OFF
END
GO