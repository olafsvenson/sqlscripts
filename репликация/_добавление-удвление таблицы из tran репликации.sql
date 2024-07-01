exec sp_dropsubscription @publication = N'HelpdeskRusHelpDeskAm', @article = N'tblQuestions', @subscriber = 'all'
exec sp_droparticle @publication = N'HelpdeskRusHelpDeskAm', @article = N'tblQuestions', @force_invalidate_snapshot = 1

--edit table

exec sp_addarticle @publication = N'HelpdeskRusHelpDeskAm', @article = N'tblQuestions', @source_owner = N'dbo', @source_object = N'tblQuestions', @type = N'logbased', @description = N'', @creation_script = N'', @pre_creation_cmd = N'drop', @schema_option = 0x00000000080300FF, @identityrangemanagementoption = N'manual', @destination_table = N'tblQuestions', @destination_owner = N'dbo', @status = 24, @vertical_partition = N'false', @ins_cmd = N'CALL [dbo].[sp_MSins_dbotblQuestions]', @del_cmd = N'CALL [dbo].[sp_MSdel_dbotblQuestions]', @upd_cmd = N'MCALL [dbo].[sp_MSupd_dbotblQuestions]', @force_invalidate_snapshot = 1
	exec sp_refreshsubscriptions @publication = N'HelpdeskRusHelpDeskAm'