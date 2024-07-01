select s.login_name,      
       wt.*
from sys.dm_os_waiting_tasks wt
     join sys.dm_exec_sessions s
        on wt.session_id = s.session_id
where s.is_user_process = 1 --and s.session_id <> @@spid
order by wait_duration_ms desc;