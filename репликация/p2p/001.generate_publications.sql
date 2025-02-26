set nocount on
select N'use master
go
exec sp_replicationdboption N'''+db_name()+N''', ''publish'', ''true''
go
use '+quotename(db_name())+N'
go
exec sp_addpublication @publication = N'''+db_name()+N'_P2P'', @sync_method = N''native'', @retention = 0, @allow_push = N''true'', @allow_pull = N''true'', @allow_anonymous = N''false'', @enabled_for_internet = N''false'', @snapshot_in_defaultfolder = N''true'', @compress_snapshot = N''false'', @ftp_port = 21, @allow_subscription_copy = N''false'', @add_to_active_directory = N''false'', @repl_freq = N''continuous'', @status = N''active'', @independent_agent = N''true'', @immediate_sync = N''true'', @allow_sync_tran = N''false'', @allow_queued_tran = N''false'', @allow_dts = N''false'', @replicate_ddl = 1, @allow_initialize_from_backup = N''true'', @enabled_for_p2p = N''true'', @enabled_for_het_sub = N''false'''
--Генерирует скрипт создания статей P2P-репликации для всех таблиц с первичным ключём в текущей БД
select replace(
		N'exec sp_addarticle @publication = N'''+db_name() + N'_P2P'', @article = N''?'', @source_owner = N''dbo'', @source_object = N''?'', @type = N''logbased'', @schema_option = 0x000000000803509F, @destination_table = N''?'', @destination_owner = N''dbo'', @status = 24, @vertical_partition = N''false'''+
			', @del_cmd = ''CALL P2P_d_?'''+
			', @ins_cmd = ''CALL P2P_i_?'''+
			', @upd_cmd = ''SCALL P2P_u_?''',
		'?',
		name
	)
from sys.tables
where
	type = 'U'
	and objectproperty(object_id, 'IsMSShipped') = 0
	and objectproperty(object_id, 'TableHasPrimaryKey') = 1
order by name