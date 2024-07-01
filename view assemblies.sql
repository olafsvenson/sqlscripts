select top 10 * from Pythoness_Transport.support.vDocument


SELECT * FROM sys.databases
SELECT * FROM Sys.server_principals

0x010500000000000515000000E7A3401BC6DDD334D54813E8A7090000
0x010500000000000515000000E7A3401BC6DDD334D54813E8A7090000



select * from sys.assembly_modules where assembly_id=65930


65930


SELECT      so.name AS [ObjectName],
            so.[type],
            SCHEMA_NAME(so.[schema_id]) AS [SchemaName],
            asmbly.name AS [AssemblyName],
            asmbly.permission_set_desc,
            am.assembly_class, 
            am.assembly_method
FROM        sys.assembly_modules am
INNER JOIN  sys.assemblies asmbly
        ON  asmbly.assembly_id = am.assembly_id
        AND asmbly.is_user_defined = 1 -- if using SQL Server 2008 or newer
--      AND asmbly.name NOT LIKE 'Microsoft%' -- if using SQL Server 2005
INNER JOIN  sys.objects so
        ON  so.[object_id] = am.[object_id]
UNION ALL
SELECT      at.name AS [ObjectName],
            'UDT' AS [type],
            SCHEMA_NAME(at.[schema_id]) AS [SchemaName], 
            asmbly.name AS [AssemblyName],
            asmbly.permission_set_desc,
            at.assembly_class,
            NULL AS [assembly_method]
FROM        sys.assembly_types at
INNER JOIN  sys.assemblies asmbly
        ON  asmbly.assembly_id = at.assembly_id
        AND asmbly.is_user_defined = 1 -- if using SQL Server 2008 or newer
--      AND asmbly.name NOT LIKE 'Microsoft%' -- if using SQL Server 2005
ORDER BY    [AssemblyName], [type], [ObjectName]