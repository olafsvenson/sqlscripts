select cpu_count from sys.dm_os_sys_info

select scheduler_id,cpu_id, status, is_online from sys.dm_os_schedulers 

select serverproperty('Edition')
select serverproperty('NumLicenses') 