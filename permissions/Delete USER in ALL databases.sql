EXECUTE master.sys.sp_MSforeachdb 'USE [?]; 
DROP USER IF EXISTS [test1]
'