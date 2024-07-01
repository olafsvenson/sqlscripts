
-- текущее состояние настройки, храняйшейся в памяти
select * from sys.dm_resource_governor_configuration;


-- состояние пула ресурсов, настройки и статистики
select * from sys.dm_resource_governor_resource_pools;

-- статистика по группе рабочей нагрузки и настройки в памяти

select * from sys.dm_resource_governor_workload_groups;