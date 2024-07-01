/*This will script out the command for you, check it and execute the output */

    SELECT  'ALTER DATABASE ' + QUOTENAME(name) + ' SET AUTO_SHRINK OFF WITH NO_WAIT;' AS [To Execute]
    FROM    sys.databases
    WHERE   is_auto_shrink_on = 1;
GO