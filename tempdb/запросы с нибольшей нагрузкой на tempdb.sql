exec sp_whoisactive
@show_sleeping_spids=0,
@sort_order = '[tempdb_current] desc',
@output_column_list = '[tempdb_current][dd%][session_id][status][sql_text][host_name][program_name][login_name][wait_info]';