SELECT database_name, 
       activity, 
       start_time, 
       message
FROM msdb..sysdbmaintplan_history
WHERE error_number = 0;