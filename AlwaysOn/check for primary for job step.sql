IF (SELECT [dbo].[fn_hadr_group_is_primary] ('dwh-etl-p-ag') ) = 0
begin
print 'its secondary, stop job'
print '$(ESCAPE_SQUOTE(JOBNAME))'
EXEC msdb..sp_stop_job N'$(ESCAPE_SQUOTE(JOBNAME))'
end