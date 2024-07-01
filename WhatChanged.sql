/*
 * Get a list of objects sorted by modified date.
 * Allows you to quickly identify what has been
 * added or changed.
 */

SELECT
    modify_date, OBJECT_NAME(object_id ) 'Stored Procedure' , *
FROM
    sys.procedures
order by 1 desc

SELECT
    modify_date, OBJECT_NAME(object_id ) 'Table' , *
FROM
    sys.tables
order by 1 desc

SELECT
    modify_date, OBJECT_NAME(object_id ) 'Trigger' , *
FROM
    sys.triggers
order by 1 desc


SELECT
    modify_date, OBJECT_NAME(object_id ) 'View' , *
FROM
    sys.views
order by 1 desc
