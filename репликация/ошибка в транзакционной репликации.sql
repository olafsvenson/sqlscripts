use distribution
go

select * from distribution.dbo.MSpublisher_databases

(Transaction sequence number: 0x0000073B00000299001800000000, Command ID: 1)

sp_browsereplcmds @xact_seqno_start = '0x0046468600032A1E000400000000'
,@xact_seqno_end = '0x0046468600032A1E000400000000'
,@publisher_database_id =4
--,@article_id = 1
,@command_id= 1


{CALL [sp_MSupd_dbo_tblMen_TT] (,,,18,10,1990,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,45003038,0x38000000000000)}


{CALL [sp_MSdel_IntegrationTTLanguages] (1000824)}


{CALL [sp_MSdel_IntegrationTTAccounts] (20001744263)}

{CALL [sp_MSupd_IntegrationTTMemberSearchIndex] (,,,,,,,,,,,,,,,,,,2013-11-29 11:15:07.313,,20001744263,0x000004)}