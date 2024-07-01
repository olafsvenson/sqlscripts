/*
	https://techcommunity.microsoft.com/t5/sql-server-integration-services/troubleshooting-ssis-package-performance-issues/ba-p/387927#
*/
USE SSISDB;
GO

/*
SELECT * FROM catalog.executions
WHERE 
folder_name='CustomerRelationshipPerformance'
AND project_name='WORKLOAD_FACTS_PROCESSING'
ORDER BY start_time desc

*/



DECLARE @foldername NVARCHAR(260);
DECLARE @projectname NVARCHAR(260);
DECLARE @packagename NVARCHAR(260);
SET @foldername = 'CustomerRelationshipPerformance';
SET @projectname = 'WORKLOAD_FACTS_PROCESSING';
SET @packagename = 'RootPackage.dtsx';
DECLARE @ExecIds TABLE(execution_id BIGINT);
INSERT INTO @ExecIds
       SELECT execution_id
       FROM catalog.executions
       WHERE folder_name = @foldername
             AND project_name = @projectname
             AND package_name = @packagename
             AND STATUS = 7;



With AverageExecDudration As (
select executable_name, avg(es.execution_duration) as avg_duration,STDEV(es.execution_duration) as stddev
from catalog.executable_statistics es, catalog.executables e
where
es.executable_id = e.executable_id AND
es.execution_id = e.execution_id AND
es.execution_id in (select * from @ExecIds)
group by e.executable_name
)
select es.execution_id, e.executable_name, ES.execution_duration, AvgDuration.avg_duration, AvgDuration.stddev
from catalog.executable_statistics es, catalog.executables e,
AverageExecDudration AvgDuration
where
es.executable_id = e.executable_id AND
es.execution_id = e.execution_id AND
es.execution_id in (select * from @ExecIds) AND
e.executable_name = AvgDuration.executable_name AND
es.execution_duration > (AvgDuration.avg_duration + AvgDuration.stddev)
order by es.execution_duration DESC



DECLARE @probExec BIGINT;
SET @probExec = 47;

-- Identify the component’s total and active time

SELECT package_name, 
       task_name, 
       subcomponent_name, 
       execution_path, 
       SUM(DATEDIFF(ms, start_time, end_time)) AS active_time, 
       DATEDIFF(ms, MIN(start_time), MAX(end_time)) AS total_time
FROM catalog.execution_component_phases
WHERE execution_id = @probExec
GROUP BY package_name, 
         task_name, 
         subcomponent_name, 
         execution_path
ORDER BY active_time DESC;
DECLARE @component_name NVARCHAR(1024);
SET @component_name = 'DFT Load DC Vendor';

-- See the breakdown of the component by phases

SELECT package_name, 
       task_name, 
       subcomponent_name, 
       execution_path, 
       phase, 
       SUM(DATEDIFF(ms, start_time, end_time)) AS active_time, 
       DATEDIFF(ms, MIN(start_time), MAX(end_time)) AS total_time
FROM catalog.execution_component_phases
WHERE execution_id = @probExec
      AND subcomponent_name = @component_name
GROUP BY package_name, 
         task_name, 
         subcomponent_name, 
         execution_path, 
         phase
ORDER BY active_time DESC;